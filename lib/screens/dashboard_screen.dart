import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../services/date_formatter.dart';
import '../widgets/medicine_card.dart';
import '../widgets/statistic_card.dart';
import '../widgets/insight_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/section_header.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/empty_state_widget.dart';
import 'symptom_chat_screen.dart';
import 'history_screen.dart';
import 'sos_screen.dart';
import 'settings_screen.dart';
import 'health_timeline_screen.dart';
import 'voice_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String language;
  final Function(String)? onLanguageChanged;

  const DashboardScreen({super.key, this.language = "en", this.onLanguageChanged});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late String selectedLanguage;
  String userName = "User";

  int abnormalResultsCount = 0;
  String latestReportSummary = "No recent reports.";
  List<dynamic> recentAnalyses = [];
  List<Map<String, dynamic>> healthAlertsList = [];

  int prescriptionScansCount = 0;
  int medicalReportsCount = 0;
  int aiChatsCount = 0;

  List<dynamic> _reminders = [];
  List<dynamic> _allHistory = [];
  int _todayTotalCount = 0;
  int takenCount = 0;
  bool _isLoading = true;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    selectedLanguage = widget.language;
    _fetchDashboardData();
    _setupRealtimeSubscription();
    dashboardRefreshNotifier.addListener(_fetchDashboardData);
    pendingRemindersNotifier.addListener(_onPendingRemindersUpdated);
  }

  @override
  void dispose() {
    dashboardRefreshNotifier.removeListener(_fetchDashboardData);
    pendingRemindersNotifier.removeListener(_onPendingRemindersUpdated);
    if (_realtimeChannel != null) {
      Supabase.instance.client.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  void _onPendingRemindersUpdated() {
    final incoming = pendingRemindersNotifier.value;
    if (incoming.isEmpty || !mounted) return;
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    setState(() {
      for (final item in incoming) {
        final medName = (item['medicine_name'] ?? '').toString().toLowerCase();
        final rTime = item['reminder_time'] ?? '';
        final rDate = item['reminder_date'] ?? todayStr;
        final exists = _reminders.any((r) =>
            (r['medicine_name'] ?? '').toString().toLowerCase() == medName &&
            (r['reminder_time'] ?? '') == rTime &&
            (r['reminder_date'] ?? '') == rDate);
        if (!exists) {
          _reminders.add(Map<String, dynamic>.from(item));
        }
      }
      int todayTaken = 0;
      int todayTotal = 0;
      for (var reminder in _reminders) {
        if (reminder['reminder_date'] == todayStr) {
          todayTotal++;
          if (reminder['status'] == 'taken') {
            todayTaken++;
          }
        }
      }
      takenCount = todayTaken;
      _todayTotalCount = todayTotal;
    });
  }

  void _setupRealtimeSubscription() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _realtimeChannel != null) return;

    try {
      _realtimeChannel = Supabase.instance.client.channel('public:dashboard_${user.id}')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'analysis_history',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            debugPrint("Realtime event on analysis_history: ${payload.eventType}");
            if (mounted) {
              _fetchDashboardData();
            }
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'medication_reminders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            debugPrint("Realtime event on medication_reminders: ${payload.eventType}");
            if (mounted) {
              _fetchDashboardData();
            }
          },
        )
        ..subscribe();
    } catch (e) {
      debugPrint("Error setting up Realtime subscription: $e");
    }
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      setState(() {
        selectedLanguage = widget.language;
      });
    }
  }

  Future<void> _fetchDashboardData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      userName = user.userMetadata?['name'] ?? "User";
      _setupRealtimeSubscription();

      try {
        await Future.wait([
          fetchReminders(),
          () async {
            final allHistoryRes = await Supabase.instance.client
                .from('analysis_history')
                .select()
                .eq('user_id', user.id)
                .order('created_at', ascending: false);

            final allHistory = (allHistoryRes as List<dynamic>)
                .where((item) => (item['type'] as String? ?? '').toLowerCase() != 'skin')
                .toList();
            _allHistory = allHistory;
            recentAnalyses = allHistory.take(5).toList();
          }(),
        ]);

        _processHealthAlerts(_allHistory);
      } catch (e) {
        debugPrint("Error fetching dashboard data: $e");
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> _extractWarningsFromText(String text) {
    List<String> warnings = [];
    final lines = text.split('\n');
    bool inKeyFindings = false;

    for (var rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final lower = line.toLowerCase();
      if (lower.contains('key findings') || lower.contains('abnormal results') || lower.contains('warnings')) {
        inKeyFindings = true;
        continue;
      }
      if (inKeyFindings && line.startsWith('###')) {
        inKeyFindings = false;
      }

      if (line.contains('⚠️') ||
          line.startsWith('>') ||
          lower.contains('warning') ||
          lower.contains('abnormal') ||
          lower.contains('high') ||
          lower.contains('low') ||
          lower.contains('elevated') ||
          lower.contains('deficient') ||
          inKeyFindings) {
        
        String clean = line
            .replaceAll(RegExp(r'^[>\s#*-]+'), '')
            .replaceAll('**', '')
            .replaceAll('`', '')
            .trim();

        if (clean.isNotEmpty &&
            !clean.toLowerCase().startsWith('health status overview') &&
            !clean.toLowerCase().startsWith('key findings') &&
            !clean.toLowerCase().startsWith('suggestions')) {
          if (!warnings.contains(clean)) {
            warnings.add(clean);
          }
        }
      }
    }
    return warnings;
  }

  void _processHealthAlerts(List<dynamic> allHistory) {
    int totalAbnormal = 0;
    String latestRep = "No recent reports.";
    List<Map<String, dynamic>> alertsList = [];

    int rxCount = 0;
    int repCount = 0;
    int chatCount = 0;

    for (var record in allHistory) {
      try {
        final type = (record['type'] as String? ?? 'report').toLowerCase();
        if (type == 'skin') continue;
        final resultStr = record['result'] as String? ?? '';
        final createdAt = record['created_at'] as String? ?? '';

        if (type == 'prescription') {
          rxCount++;
        } else if (type == 'report') {
          repCount++;
        } else if (type == 'symptom') {
          chatCount++;
        }

        String summaryText = resultStr;
        int count = 0;

        if (resultStr.trim().startsWith('{')) {
          try {
            final Map<String, dynamic> parsed = jsonDecode(resultStr);
            count = (parsed['abnormal_count'] ?? 0) as int;
            summaryText = parsed['summary'] ?? resultStr;
          } catch (_) {}
        }

        if (type == 'report' && latestRep == "No recent reports.") {
          latestRep = summaryText;
        }

        List<String> extractedWarnings = _extractWarningsFromText(summaryText);

        if (count > 0 || extractedWarnings.isNotEmpty || (type == 'report' && summaryText.toLowerCase().contains('abnormal'))) {
          int effectiveCount = count > 0 ? count : (extractedWarnings.isNotEmpty ? extractedWarnings.length : 1);
          totalAbnormal += effectiveCount;

          alertsList.add({
            'id': record['id'],
            'type': type,
            'title': type == 'report' ? 'Lab Report Findings' : 'Symptom Check Alert',
            'created_at': createdAt,
            'abnormal_count': effectiveCount,
            'summary': summaryText,
            'warnings': extractedWarnings.isNotEmpty ? extractedWarnings : [summaryText],
            'raw_result': resultStr,
          });
        }
      } catch (e) {
        debugPrint("Error processing alert item: $e");
      }
    }

    // Include missed medications in healthAlertsList
    final missedMeds = _reminders.where((r) => r['status'] == 'missed').toList();
    for (var med in missedMeds) {
      totalAbnormal += 1;
      alertsList.add({
        'id': med['id'],
        'type': 'medication',
        'title': 'Missed Dose: ${med['medicine_name'] ?? 'Medicine'}',
        'created_at': '${med['reminder_date'] ?? ''} ${med['reminder_time'] ?? ''}',
        'abnormal_count': 1,
        'summary': 'Medication dose missed.',
        'warnings': ['Dose missed for ${med['medicine_name'] ?? 'Medicine'} at ${med['reminder_time'] ?? ''}'],
        'raw_result': med,
      });
    }

    setState(() {
      abnormalResultsCount = totalAbnormal;
      latestReportSummary = latestRep.isEmpty ? "No recent reports." : latestRep;
      healthAlertsList = alertsList;
      prescriptionScansCount = rxCount;
      medicalReportsCount = repCount;
      aiChatsCount = chatCount;
    });
  }

  String _getText(String key) {
    final translations = {
      'en': {
        'insights': 'Health Insights',
        'issues': 'Health Status',
        'optimal': 'Optimal Range',
        'alerts': 'Alerts',
        'meds_taken': 'Medicines Taken',
        'todays_plan': 'Today’s Medicine Plan',
        'todays_plan_sub': 'Track & manage your scheduled medicines',
        'quick_actions': 'Quick Actions',
        'quick_actions_sub': 'Fast access to health features',
        'health_stats': 'Health Statistics',
        'health_stats_sub': 'Dynamic health analysis metrics',
        'ai_recommendation': 'AI Health Recommendation',
        'ai_recommendation_sub': 'Personalized advice based on your health history',
        'health_overview': "Today's Health Overview",
        'meds_taken_sub': '{taken} of {total} medicines taken',
        'good_morning': 'Good Morning ☀️',
        'good_afternoon': 'Good Afternoon 🌤️',
        'good_evening': 'Good Evening 🌙',
        'all_done_today': 'All done for today! 🎉',
        'voice_assistant': 'Voice Assistant',
        'health_timeline': 'Health Timeline',
        'view_records': 'View records',
        'speak_with_ai': 'Speak with AI',
        'full_history': 'Full history',
        'instant_help': 'Instant help',
        'chat': 'Symptom Chat',
        'history': 'History',
        'sos': 'SOS',
        'hello': 'Hello',
        'taken': 'Taken',
        'skip': 'Skip',
        'remove_med': 'Remove Medicine',
        'remove_med_query': 'Are you sure you want to remove {med} from your dashboard?',
        'cancel': 'Cancel',
        'remove': 'Remove',
        'recent_reports': 'Recent Reports',
        'ai_summary': 'AI Summary',
        'emergency_sos': 'Emergency SOS',
        'alerts_detail_title': 'Health Alerts & Issues',
        'active_alerts_sub': 'issues requiring your attention',
        'no_active_alerts': 'No Active Health Alerts',
        'all_optimal': 'All your lab reports and medication schedules are in optimal condition.',
        'view_full_report': 'View Full Analysis',
        'mark_taken': 'Mark as Taken',
        'doctor_disclaimer': 'Tip: Discuss these alerts with your physician. Use Emergency SOS if you feel unwell.',
        'missed_med': 'Missed Dose',
        'tap_to_view': 'Tap to view',
      },
      'hi': {
        'insights': 'स्वास्थ्य जानकारी',
        'issues': 'स्वास्थ्य स्थिति',
        'optimal': 'सामान्य',
        'alerts': 'अलर्ट',
        'meds_taken': 'दवाएं ली गईं',
        'todays_plan': 'आज का दवा प्लान',
        'todays_plan_sub': 'अपनी निर्धारित दवाओं को ट्रैक और प्रबंधित करें',
        'quick_actions': 'त्वरित कार्रवाई',
        'quick_actions_sub': 'स्वास्थ्य सुविधाओं तक त्वरित पहुंच',
        'health_stats': 'स्वास्थ्य आंकड़े',
        'health_stats_sub': 'डायनेमिक स्वास्थ्य विश्लेषण मेट्रिक्स',
        'ai_recommendation': 'AI स्वास्थ्य सिफारिश',
        'ai_recommendation_sub': 'आपके स्वास्थ्य इतिहास के आधार पर व्यक्तिगत सलाह',
        'health_overview': 'आज का स्वास्थ्य अवलोकन',
        'meds_taken_sub': '{total} में से {taken} दवाएं ली गईं',
        'good_morning': 'शुभ प्रभात ☀️',
        'good_afternoon': 'शुभ दोपहर 🌤️',
        'good_evening': 'शुभ संध्या 🌙',
        'all_done_today': 'आज का सारा काम पूरा हुआ! 🎉',
        'voice_assistant': 'वॉइस असिस्टेंट',
        'health_timeline': 'स्वास्थ्य समयरेखा',
        'view_records': 'रिकॉर्ड देखें',
        'speak_with_ai': 'AI के साथ बात करें',
        'full_history': 'पूरा इतिहास',
        'instant_help': 'त्वरित सहायता',
        'chat': 'सत्र चैट',
        'history': 'इतिहास',
        'sos': 'एसओएस',
        'hello': 'नमस्ते',
        'taken': 'ली गई',
        'skip': 'छोड़ें',
        'remove_med': 'दवा हटाएं',
        'remove_med_query': 'क्या आप वाकई अपने डैशबोर्ड से {med} को हटाना चाहते हैं?',
        'cancel': 'रद्द करें',
        'remove': 'हटाएं',
        'recent_reports': 'हाल की रिपोर्ट',
        'ai_summary': 'AI सारांश',
        'emergency_sos': 'आपातकालीन SOS',
        'alerts_detail_title': 'स्वास्थ्य अलर्ट और समस्याएं',
        'active_alerts_sub': 'समस्याएं जिन पर ध्यान देने की आवश्यकता है',
        'no_active_alerts': 'कोई सक्रिय स्वास्थ्य अलर्ट नहीं',
        'all_optimal': 'आपकी सभी लैब रिपोर्ट और दवाएं सामान्य स्थिति में हैं।',
        'view_full_report': 'पूरा विश्लेषण देखें',
        'mark_taken': 'ली गई के रूप में चिह्नित करें',
        'doctor_disclaimer': 'सुझाव: अपने डॉक्टर से इन अलर्ट पर चर्चा करें। अस्वस्थ होने पर आपातकालीन SOS का उपयोग करें।',
        'missed_med': 'छूटी हुई खुराक',
        'tap_to_view': 'देखने के लिए टैप करें',
      },
      'kn': {
        'insights': 'ಆರೋಗ್ಯ ಒಳನೋಟಗಳು',
        'issues': 'ಆರೋಗ್ಯ ಸ್ಥಿತಿ',
        'optimal': 'ಸೂಕ್ತವಾಗಿದೆ',
        'alerts': 'ಎಚ್ಚರಿಕೆಗಳು',
        'meds_taken': 'ಔಷಧಿಗಳನ್ನು ತೆಗೆದುಕೊಳ್ಳಲಾಗಿದೆ',
        'todays_plan': 'ಇಂದಿನ ಔಷಧಿ ಯೋಜನೆ',
        'todays_plan_sub': 'ನಿಮ್ಮ ನಿಗದಿತ ಔಷಧಿಗಳನ್ನು ಟ್ರ್ಯಾಕ್ ಮಾಡಿ ಮತ್ತು ನಿರ್ವಹಿಸಿ',
        'quick_actions': 'ತ್ವರಿತ ಕ್ರಮಗಳು',
        'quick_actions_sub': 'ಆರೋಗ್ಯ ವೈಶಿಷ್ಟ್ಯಗಳಿಗೆ ತ್ವರಿತ ಪ್ರವೇಶ',
        'health_stats': 'ಆರೋಗ್ಯ ಅಂಕಿಅಂಶಗಳು',
        'health_stats_sub': 'ಡೈನಾಮಿಕ್ ಆರೋಗ್ಯ ವಿಶ್ಲೇಷಣೆ ಮೆಟ್ರಿಕ್ಸ್',
        'ai_recommendation': 'AI ಆರೋಗ್ಯ ಶಿಫಾರಸು',
        'ai_recommendation_sub': 'ನಿಮ್ಮ ಆರೋಗ್ಯ ಇತಿಹಾಸದ ಆಧಾರದ ಮೇಲೆ ವೈಯಕ್ತಿಕಗೊಳಿಸಿದ ಸಲಹೆ',
        'health_overview': 'ಇಂದಿನ ಆರೋಗ್ಯ ಮುನ್ನೋಟ',
        'meds_taken_sub': '{total} ರಲ್ಲಿ {taken} ಔಷಧಿಗಳನ್ನು ತೆಗೆದುಕೊಳ್ಳಲಾಗಿದೆ',
        'good_morning': 'ಶುಭೋದಯ ☀️',
        'good_afternoon': 'ಮಧ್ಯಾಹ್ನದ ಶುಭಾಶಯಗಳು 🌤️',
        'good_evening': 'ಶುಭ ಸಂಜೆ 🌙',
        'all_done_today': 'ಇಂದಿನ ಕೆಲಸವೆಲ್ಲ ಮುಗಿಯಿತು! 🎉',
        'voice_assistant': 'ಧ್ವನಿ ಸಹಾಯಕ',
        'health_timeline': 'ಆರೋಗ್ಯ ಕಾಲಸೂಚಿ',
        'view_records': 'ದಾಖಲೆಗಳನ್ನು ವೀಕ್ಷಿಸಿ',
        'speak_with_ai': 'AI ನೊಂದಿಗೆ ಮಾತನಾಡಿ',
        'full_history': 'ಪೂರ್ಣ ಇತಿಹಾಸ',
        'instant_help': 'ತತ್ಕ್ಷಣ ಸಹಾಯ',
        'chat': 'ರೋಗಲಕ್ಷಣ ಚಾಟ್',
        'history': 'ಇತಿಹಾಸ',
        'sos': 'ಎಸ್‌ಒಎಸ್',
        'hello': 'ಹಲೋ',
        'taken': 'ತೆಗೆದುಕೊಳ್ಳಲಾಗಿದೆ',
        'skip': 'ಬಿಟ್ಟುಬಿಡಿ',
        'remove_med': 'ಔಷಧಿಯನ್ನು ತೆಗೆದುಹಾಕಿ',
        'remove_med_query': 'ನಿಮ್ಮ ಡ್ಯಾಶ್‌ಬೋರ್ಡ್‌ನಿಂದ {med} ಅನ್ನು ತೆಗೆದುಹಾಕಲು ನೀವು ಖಚಿತವಾಗಿ ಬಯಸುವಿರಾ?',
        'cancel': 'ರದ್ದುಗೊಳಿಸಿ',
        'remove': 'ತೆಗೆದುಹಾಕಿ',
        'recent_reports': 'ಇತ್ತೀಚಿನ ವರದಿಗಳು',
        'ai_summary': 'AI ಸಾರಾಂಶ',
        'emergency_sos': 'ತುರ್ತು SOS',
        'alerts_detail_title': 'ಆರೋಗ್ಯ ಎಚ್ಚರಿಕೆಗಳು ಮತ್ತು ಸಮಸ್ಯೆಗಳು',
        'active_alerts_sub': 'ನಿಮ್ಮ ಗಮನ ಅಗತ್ಯವಿರುವ ಸಮಸ್ಯೆಗಳು',
        'no_active_alerts': 'ಯಾವುದೇ ಸಕ್ರಿಯ ಆರೋಗ್ಯ ಎಚ್ಚರಿಕೆಗಳಿಲ್ಲ',
        'all_optimal': 'ನಿಮ್ಮ ಎಲ್ಲಾ ಲ್ಯಾಬ್ ವರದಿಗಳು ಮತ್ತು ಔಷಧಿ ವೇಳಾಪಟ್ಟಿಗಳು ಉತ್ತಮ ಸ್ಥಿತಿಯಲ್ಲಿವೆ.',
        'view_full_report': 'ಪೂರ್ಣ ವಿಶ್ಲೇಷಣೆ ವೀಕ್ಷಿಸಿ',
        'mark_taken': 'ತೆಗೆದುಕೊಳ್ಳಲಾಗಿದೆ ಎಂದು ಗುರುತಿಸಿ',
        'doctor_disclaimer': 'ಸಲಹೆ: ಈ ಎಚ್ಚರಿಕೆಗಳನ್ನು ನಿಮ್ಮ ವೈದ್ಯರೊಂದಿಗೆ ಚರ್ಚಿಸಿ. ಅನಾರೋಗ್ಯ ಅನಿಸಿದರೆ ತುರ್ತು SOS ಬಳಸಿ.',
        'missed_med': 'ತಪ್ಪಿದ ಡೋಸ್',
        'tap_to_view': 'ವೀಕ್ಷಿಸಲು ಟ್ಯಾಪ್ ಮಾಡಿ',
      },
      'ta': {
        'insights': 'சுகாதார நுண்ணறிவு',
        'issues': 'சுகாதார நிலை',
        'optimal': 'சிறந்தது',
        'alerts': 'விழிப்பூட்டல்கள்',
        'meds_taken': 'மருந்துகள் எடுக்கப்பட்டன',
        'todays_plan': 'இன்றைய மருந்துத் திட்டம்',
        'todays_plan_sub': 'உங்கள் திட்டமிடப்பட்ட மருந்துகளைக் கண்காணித்து நிர்வகிக்கவும்',
        'quick_actions': 'விரைவான செயல்கள்',
        'quick_actions_sub': 'சுகாதார அம்சங்களுக்கான விரைவான அணுகல்',
        'health_stats': 'சுகாதார புள்ளிவிவரங்கள்',
        'health_stats_sub': 'டைனமிக் சுகாதார பகுப்பாய்வு அளவீடுகள்',
        'ai_recommendation': 'AI சுகாதார பரிந்துரை',
        'ai_recommendation_sub': 'உங்கள் சுகாதார வரலாற்றின் அடிப்படையில் தனிப்பயனாக்கப்பட்ட ஆலோசனை',
        'health_overview': 'இன்றைய சுகாதார மேலோட்டம்',
        'meds_taken_sub': '{total} இல் {taken} மருந்துகள் எடுக்கப்பட்டன',
        'good_morning': 'காலை வணக்கம் ☀️',
        'good_afternoon': 'மதிய வணக்கம் 🌤️',
        'good_evening': 'மாலை வணக்கம் 🌙',
        'all_done_today': 'இன்றைய வேலை அனைத்தும் முடிந்தது! 🎉',
        'voice_assistant': 'குரல் உதவியாளர்',
        'health_timeline': 'சுகாதார காலவரிசை',
        'view_records': 'பதிவுகளைப் பார்க்கவும்',
        'speak_with_ai': 'AI உடன் பேசுங்கள்',
        'full_history': 'முழு வரலாறு',
        'instant_help': 'உடனடி உதவி',
        'chat': 'அறிகுறி அரட்டை',
        'history': 'வரலாறு',
        'sos': 'SOS',
        'hello': 'வணக்கம்',
        'taken': 'எடுக்கப்பட்டது',
        'skip': 'தவிர்க்கவும்',
        'remove_med': 'மருந்தை அகற்று',
        'remove_med_query': 'உங்கள் டாஷ்போர்டிலிருந்து {med}-ஐ அகற்ற விரும்புகிறீர்களா?',
        'cancel': 'ரத்துசெய்',
        'remove': 'அகற்று',
        'recent_reports': 'சமீபத்திய அறிக்கைகள்',
        'ai_summary': 'AI சுருக்கம்',
        'emergency_sos': 'அவசர SOS',
        'alerts_detail_title': 'சுகாதார விழிப்பூட்டல்கள் மற்றும் சிக்கல்கள்',
        'active_alerts_sub': 'உங்கள் கவனம் தேவைப்படும் சிக்கல்கள்',
        'no_active_alerts': 'செயலில் உள்ள சுகாதார விழிப்பூட்டல்கள் எதுவும் இல்லை',
        'all_optimal': 'உங்கள் ஆய்வக அறிக்கைகள் மற்றும் மருந்து அட்டவணைகள் சிறந்த நிலையில் உள்ளன.',
        'view_full_report': 'முழு பகுப்பாய்வைக் காண்க',
        'mark_taken': 'எடுக்கப்பட்டதாகக் குறிக்கவும்',
        'doctor_disclaimer': 'குறிப்பு: இந்த விழிப்பூட்டல்களை உங்கள் மருத்துவரிடம் விவாதிக்கவும். அவசர நிலைக்கு SOS ஐப் பயன்படுத்தவும்.',
        'missed_med': 'தவறிய டோஸ்',
        'tap_to_view': 'பார்க்க தட்டவும்',
      },
      'ml': {
        'insights': 'ആരോഗ്യ ഉൾക്കാഴ്ചകൾ',
        'issues': 'ആരോഗ്യ സ്ഥിതി',
        'optimal': 'മികച്ചത്',
        'alerts': 'അലേർട്ടുകൾ',
        'meds_taken': 'മരുന്നുകൾ കഴിച്ചു',
        'todays_plan': 'ഇന്നത്തെ മരുന്ന് പ്ലാൻ',
        'todays_plan_sub': 'നിങ്ങളുടെ ഷെഡ്യൂൾ ചെയ്ത മരുന്നുകൾ ട്രാക്ക് ചെയ്യുകയും കൈകാര്യം ചെയ്യുകയും ചെയ്യുക',
        'quick_actions': 'വേഗത്തിലുള്ള നടപടികൾ',
        'quick_actions_sub': 'ആരോഗ്യ ഫീച്ചറുകളിലേക്ക് വേഗത്തിലുള്ള ആക്സസ്',
        'health_stats': 'ആരോഗ്യ കണക്കുകൾ',
        'health_stats_sub': 'ഡൈനാമിക് ആരോഗ്യ വിശകലന സൂചികകൾ',
        'ai_recommendation': 'AI ആരോഗ്യ ശുപാർശ',
        'ai_recommendation_sub': 'നിങ്ങളുടെ ആരോഗ്യ ചരിത്രത്തെ അടിസ്ഥാനമാക്കിയുള്ള വ്യക്തിഗത ഉപദേശം',
        'health_overview': 'ഇന്നത്തെ ആരോഗ്യ അവലോകനം',
        'meds_taken_sub': '{total}-ൽ {taken} മരുന്നുകൾ കഴിച്ചു',
        'good_morning': 'സുപ്രഭാതം ☀️',
        'good_afternoon': 'ഉച്ചകഴിഞ്ഞുള്ള ആശംസകൾ 🌤️',
        'good_evening': 'സന്ധ്യാ വന്ദനം 🌙',
        'all_done_today': 'ഇന്നത്തെ കാര്യങ്ങളെല്ലാം കഴിഞ്ഞു! 🎉',
        'voice_assistant': 'വോയിസ് അസിസ്റ്റന്റ്',
        'health_timeline': 'ആരോഗ്യ രേഖ',
        'view_records': 'റെക്കോർഡുകൾ കാണുക',
        'speak_with_ai': 'AI യോട് സംസാരിക്കുക',
        'full_history': 'പൂർണ്ണ ചരിത്രം',
        'instant_help': 'ഉടനടി സഹായം',
        'chat': 'ലക്ഷണ ചാറ്റ്',
        'history': 'ചരിത്രം',
        'sos': 'SOS',
        'hello': 'ഹലോ',
        'taken': 'കഴിച്ചു',
        'skip': 'ഒഴിവാക്കുക',
        'remove_med': 'മരുന്ന് ഒഴിവാക്കുക',
        'remove_med_query': 'നിങ്ങളുടെ ഡാഷ്‌ബോർഡിൽ നിന്ന് {med} ഒഴിവാക്കണമെന്ന് നിങ്ങൾക്ക് ഉറപ്പാണോ?',
        'cancel': 'റദ്ദാക്കുക',
        'remove': 'ഒഴിവാക്കുക',
        'recent_reports': 'സമീപകാല റിപ്പോർട്ടുകൾ',
        'ai_summary': 'AI സംഗ്രഹം',
        'emergency_sos': 'അടിയന്തര SOS',
        'alerts_detail_title': 'ആരോഗ്യ അലേർട്ടുകളും പ്രശ്നങ്ങളും',
        'active_alerts_sub': 'നിങ്ങളുടെ ശ്രദ്ധ ആവശ്യമുള്ള പ്രശ്നങ്ങൾ',
        'no_active_alerts': 'സജീവമായ ആരോഗ്യ അലേർട്ടുകൾ ഒന്നുമില്ല',
        'all_optimal': 'നിങ്ങളുടെ എല്ലാ ലാബ് റിപ്പോർട്ടുകളും മരുന്ന് ഷെഡ്യൂളുകളും മികച്ച നിലയിലാണ്.',
        'view_full_report': 'പൂർണ്ണ വിശകലനം കാണുക',
        'mark_taken': 'കഴിച്ചു എന്ന് രേഖപ്പെടുത്തുക',
        'doctor_disclaimer': 'ടിപ്പ്: ഈ അലേർട്ടുകൾ ഡോക്ടറുമായി ചർച്ച ചെയ്യുക. അടിയന്തര സാഹചര്യത്തിൽ SOS ഉപയോഗിക്കുക.',
        'missed_med': 'വിട്ടുപോയ ഡോസ്',
        'tap_to_view': 'കാണാൻ ടാപ്പ് ചെയ്യുക',
      },
      'te': {
        'insights': 'ఆరోగ్య సమాచారం',
        'issues': 'ఆరోగ్య స్థితి',
        'optimal': 'అనుకూలమైనది',
        'alerts': 'హెచ్చరికలు',
        'meds_taken': 'మందులు తీసుకున్నారు',
        'todays_plan': 'నేటి మందుల ప్రణాళిక',
        'todays_plan_sub': 'మీ షెడ్యూల్ చేసిన మందులను ట్రాక్ చేయండి మరియు నిర్వహించండి',
        'quick_actions': 'త్వరిత చర్యలు',
        'quick_actions_sub': 'ఆరోగ్య ఫీచర్లకు వేగవంతమైన ప్రాప్యత',
        'health_stats': 'ఆరోగ్య గణాంకాలు',
        'health_stats_sub': 'డైనమిక్ ఆరోగ్య విశ్లేషణ కొలమానాలు',
        'ai_recommendation': 'AI ఆరోగ్య సిఫార్సు',
        'ai_recommendation_sub': 'మీ ఆరోగ్య చరిత్ర ఆధారంగా వ్యక్తిగతీకరించిన సలహా',
        'health_overview': 'నేటి ఆరోగ్య అవలోకనం',
        'meds_taken_sub': '{total} లలో {taken} మందులు తీసుకున్నారు',
        'good_morning': 'శుభోదయం ☀️',
        'good_afternoon': 'శుభ మధ్యాహ్నం 🌤️',
        'good_evening': 'శుభ సాయంత్రం 🌙',
        'all_done_today': 'ఈ రోజుకు అంతా పూర్తయింది! 🎉',
        'voice_assistant': 'వాయిస్ అసిస్టెంట్',
        'health_timeline': 'ఆరోగ్య టైమ్‌లైన్',
        'view_records': 'రికార్డులను చూడండి',
        'speak_with_ai': 'AI తో మాట్లాడండి',
        'full_history': 'పూర్తి చరిత్ర',
        'instant_help': 'తక్షణ సహాయం',
        'chat': 'లక్షణాల చాట్',
        'history': 'చరిత్ర',
        'sos': 'SOS',
        'hello': 'హలో',
        'taken': 'తీసుకున్నారు',
        'skip': 'వదిలేయండి',
        'remove_med': 'మందును తొలగించండి',
        'remove_med_query': 'మీరు మీ డాష్‌బోర్డ్ నుండి {med}ని తొలగించాలనుకుంటున్నారా?',
        'cancel': 'రద్దు చేయండి',
        'remove': 'తొലగించండి',
        'recent_reports': 'ఇటీవలి నివేదికలు',
        'ai_summary': 'AI సారాంశం',
        'emergency_sos': 'అత్యవసర SOS',
        'alerts_detail_title': 'ఆరోగ్య హెచ్చరికలు మరియు సమస్యలు',
        'active_alerts_sub': 'మీ దృష్టి అవసరమయ్యే సమస్యలు',
        'no_active_alerts': 'యాక్టివ్ ఆరోగ్య హెచ్చరికలు లేవు',
        'all_optimal': 'మీ అన్ని ల్యాబ్ నివేదికలు మరియు మందుల షెడ్యూల్‌లు అనుకూలమైన స్థితిలో ఉన్నాయి.',
        'view_full_report': 'పూర్తి విశ్లేషణను చూడండి',
        'mark_taken': 'తీసుకున్నట్లు గుర్తించండి',
        'doctor_disclaimer': 'చిట్కా: ఈ హెచ్చరికలను మీ వైద్యుడితో చర్చించండి. అత్యవసర పరిస్థితిలో SOS ఉపయోగించండి.',
        'missed_med': 'మిస్ అయిన డోస్',
        'tap_to_view': 'చూడటానికి టాప్ చేయండి',
      },
    };
    return translations[selectedLanguage]?[key] ?? translations['en']![key]!;
  }

  Future<void> fetchReminders() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('medication_reminders')
          .select()
          .eq('user_id', user.id)
          .order('reminder_date', ascending: true)
          .order('reminder_time', ascending: true);

      final List<dynamic> fetchedList = response as List<dynamic>;
      final now = DateTime.now();
      final updatedList = <dynamic>[];
      final List<String> missedIds = [];

      for (var reminder in fetchedList) {
        if (reminder['status'] == 'pending' && _isTimePassed(reminder['reminder_date'], reminder['reminder_time'], now)) {
          reminder['status'] = 'missed';
          if (reminder['id'] != null) {
            missedIds.add(reminder['id'].toString());
          }
        }
        updatedList.add(reminder);
      }

      // Update missed statuses in DB asynchronously without blocking UI render
      if (missedIds.isNotEmpty) {
        _updateMissedRemindersBatch(missedIds);
      }

      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // Merge any newly scheduled local reminders not yet reflected by DB fetch
      final remainingPending = <Map<String, dynamic>>[];
      for (final item in pendingRemindersNotifier.value) {
        final medName = (item['medicine_name'] ?? '').toString().toLowerCase();
        final rTime = item['reminder_time'] ?? '';
        final rDate = item['reminder_date'] ?? todayStr;
        final inDb = updatedList.any((r) =>
            (r['medicine_name'] ?? '').toString().toLowerCase() == medName &&
            (r['reminder_time'] ?? '') == rTime &&
            (r['reminder_date'] ?? '') == rDate);
        if (!inDb && rDate == todayStr) {
          updatedList.add(Map<String, dynamic>.from(item));
          remainingPending.add(item);
        }
      }
      if (remainingPending.length != pendingRemindersNotifier.value.length) {
        pendingRemindersNotifier.value = remainingPending;
      }

      int todayTaken = 0;
      int todayTotal = 0;
      for (var reminder in updatedList) {
        if (reminder['reminder_date'] == todayStr) {
          todayTotal++;
          if (reminder['status'] == 'taken') {
            todayTaken++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _reminders = updatedList;
          takenCount = todayTaken;
          _todayTotalCount = todayTotal;
        });
      }
    } catch (e) {
      debugPrint("Error fetching reminders: $e");
    }
  }

  Future<void> _updateMissedRemindersBatch(List<String> ids) async {
    try {
      await Supabase.instance.client
          .from('medication_reminders')
          .update({'status': 'missed'})
          .filter('id', 'in', ids);
    } catch (e) {
      debugPrint("Error updating missed reminders batch: $e");
    }
  }

  bool _isTimePassed(String dateStr, String timeStr, DateTime now) {
    try {
      final dateParts = dateStr.trim().split('-');
      final time24 = DateFormatter.format24HourTime(timeStr);
      final timeParts = time24.split(':');
      if (dateParts.length == 3 && timeParts.length >= 2) {
        final year = int.parse(dateParts[0].trim());
        final month = int.parse(dateParts[1].trim());
        final day = int.parse(dateParts[2].trim());
        final hourMatch = RegExp(r'\d+').firstMatch(timeParts[0]);
        final minuteMatch = RegExp(r'\d+').firstMatch(timeParts[1]);
        if (hourMatch != null && minuteMatch != null) {
          final hour = int.parse(hourMatch.group(0)!);
          final minute = int.parse(minuteMatch.group(0)!);
          final reminderDateTime = DateTime(year, month, day, hour, minute);
          return now.isAfter(reminderDateTime);
        }
      }
    } catch (e) {
      debugPrint("Error parsing date/time: $e");
    }
    return false;
  }

  Future<void> updateReminderStatus(String id, String status) async {
    try {
      await Supabase.instance.client
          .from('medication_reminders')
          .update({'status': status})
          .eq('id', id);

      if (mounted) {
        setState(() {
          final index = _reminders.indexWhere((r) => r['id'] == id);
          if (index != -1) {
            _reminders[index]['status'] = status;
          }

          final now = DateTime.now();
          final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
          int todayTaken = 0;
          int todayTotal = 0;
          for (var reminder in _reminders) {
            if (reminder['reminder_date'] == todayStr) {
              todayTotal++;
              if (reminder['status'] == 'taken') {
                todayTaken++;
              }
            }
          }
          takenCount = todayTaken;
          _todayTotalCount = todayTotal;
        });
        _processHealthAlerts(_allHistory);
      }
    } catch (e) {
      debugPrint("Error updating reminder status: $e");
    }
  }

  Future<void> _snoozeReminder(String id, String name, String currentReminderTime) async {
    try {
      String cleanTime = currentReminderTime.trim();
      int hours = 8;
      int minutes = 0;

      final isPM = cleanTime.toLowerCase().contains('pm');
      final isAM = cleanTime.toLowerCase().contains('am');
      String digitsOnly = cleanTime.replaceAll(RegExp(r'[^\d:]'), '').trim();

      if (digitsOnly.contains(':')) {
        final parts = digitsOnly.split(':');
        hours = int.tryParse(parts[0]) ?? 8;
        minutes = int.tryParse(parts[1]) ?? 0;

        if (isPM && hours < 12) hours += 12;
        if (isAM && hours == 12) hours = 0;
      } else {
        hours = int.tryParse(digitsOnly) ?? 8;
      }

      final totalMinutes = (hours * 60 + minutes + 15) % (24 * 60);
      final newHour = totalMinutes ~/ 60;
      final newMin = totalMinutes % 60;
      final newTimeStr = "${newHour.toString().padLeft(2, '0')}:${newMin.toString().padLeft(2, '0')}";

      await Supabase.instance.client
          .from('medication_reminders')
          .update({
            'reminder_time': newTimeStr,
            'status': 'pending'
          })
          .eq('id', id);

      if (mounted) {
        setState(() {
          final index = _reminders.indexWhere((r) => r['id'] == id);
          if (index != -1) {
            _reminders[index]['reminder_time'] = newTimeStr;
            _reminders[index]['status'] = 'pending';
          }
        });

        final formatted12h = DateFormatter.format12HourTime(newTimeStr);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Snoozed $name for 15 min (New time: $formatted12h)"),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error snoozing reminder: $e");
    }
  }

  Future<void> _deleteMedication(String id) async {
    try {
      await Supabase.instance.client
          .from('medication_reminders')
          .delete()
          .eq('id', id);

      if (mounted) {
        setState(() {
          _reminders.removeWhere((r) => r['id'] == id);

          final now = DateTime.now();
          final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
          int todayTaken = 0;
          int todayTotal = 0;
          for (var reminder in _reminders) {
            if (reminder['reminder_date'] == todayStr) {
              todayTotal++;
              if (reminder['status'] == 'taken') {
                todayTaken++;
              }
            }
          }
          takenCount = todayTaken;
          _todayTotalCount = todayTotal;
        });
        _processHealthAlerts(_allHistory);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Medication reminder deleted")),
        );
      }
    } catch (e) {
      debugPrint("Error deleting reminder: $e");
    }
  }

  Map<String, List<dynamic>> groupRemindersByDate(List<dynamic> reminders) {
    final Map<String, List<dynamic>> grouped = {};
    for (var r in reminders) {
      final date = r['reminder_date'] as String;
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(r);
    }
    return grouped;
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return _getText('good_morning');
    } else if (hour < 17) {
      return _getText('good_afternoon');
    } else {
      return _getText('good_evening');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7FAFC),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                LoadingSkeleton(height: 120, borderRadius: 24),
                SizedBox(height: 20),
                LoadingSkeleton(height: 160, borderRadius: 24),
                SizedBox(height: 24),
                LoadingSkeleton(height: 30, width: 180),
                SizedBox(height: 12),
                LoadingSkeleton(height: 90, borderRadius: 20),
                SizedBox(height: 12),
                LoadingSkeleton(height: 90, borderRadius: 20),
              ],
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final todayReminders = _reminders.where((r) => r['reminder_date'] == todayStr).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF7FAFC),
      body: CustomScrollView(
        slivers: [
          // 1. Dynamic Greeting Header Bar
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F9D8A), // Vibrant Primary Teal
                    Color(0xFF1CC8B5), // Accent Mint Teal
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white.withValues(alpha: 0.25),
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getTimeBasedGreeting(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${_getText('hello')} $userName 👋",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.settings_rounded, color: Colors.white),
                          onPressed: () async {
                            final newLang = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SettingsScreen(currentLanguage: selectedLanguage),
                              ),
                            );
                            if (newLang != null && newLang is String) {
                              if (widget.onLanguageChanged != null) {
                                widget.onLanguageChanged!(newLang);
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 2. Today's Health Card (Large Overview Banner)
                _buildTodaysHealthCard(todayReminders),
                const SizedBox(height: 28),

                // 3. Medicine Timeline Section
                SectionHeader(
                  title: _getText('todays_plan'),
                  subtitle: _getText('todays_plan_sub'),
                ),
                const SizedBox(height: 14),
                _buildMedicineTimelineSection(todayReminders),
                const SizedBox(height: 28),

                // 4. Health Statistics Grid (4 Dynamic Metrics)
                SectionHeader(
                  title: _getText('health_stats'),
                  subtitle: _getText('health_stats_sub'),
                ),
                const SizedBox(height: 14),
                _buildHealthStatisticsGrid(),
                const SizedBox(height: 28),

                // 5. AI Health Insight Card
                SectionHeader(
                  title: _getText('ai_recommendation'),
                  subtitle: _getText('ai_recommendation_sub'),
                ),
                const SizedBox(height: 14),
                _buildAIHealthInsightCard(),
                const SizedBox(height: 28),

                // 6. Recent Activity Section
                SectionHeader(
                  title: _getText('recent_reports'),
                  actionText: "See History",
                  onActionTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoryScreen(language: selectedLanguage),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _buildRecentActivitySection(),
                const SizedBox(height: 28),

                // 7. Quick Actions Grid
                SectionHeader(
                  title: _getText('quick_actions'),
                  subtitle: _getText('quick_actions_sub'),
                ),
                const SizedBox(height: 14),
                _buildQuickActionsGrid(),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysHealthCard(List<dynamic> todayReminders) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _todayTotalCount > 0 ? (takenCount / _todayTotalCount) : 1.0;
    final pendingReminders = todayReminders.where((r) => r['status'] == 'pending').toList();
    final nextReminderText = pendingReminders.isNotEmpty
        ? "${pendingReminders.first['medicine_name']} • ${DateFormatter.format12HourTime(pendingReminders.first['reminder_time'] ?? '')}"
        : _getText('all_done_today');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF1CC8B5) : const Color(0xFF0F9D8A)).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.favorite_rounded, color: isDark ? const Color(0xFF1CC8B5) : const Color(0xFF0F9D8A), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getText('health_overview'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            _getText('meds_taken_sub').replaceAll('{taken}', '$takenCount').replaceAll('{total}', '$_todayTotalCount'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F9D8A)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (pendingReminders.isNotEmpty) {
                      _showNextReminderPopup(context, pendingReminders.first);
                    } else {
                      _showNextReminderPopup(context, null);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.alarm_rounded, color: isDark ? const Color(0xFF1CC8B5) : const Color(0xFF0F9D8A), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Next Reminder",
                                style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.bold),
                              ),
                              Text(
                                nextReminderText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  _showHealthAlertsDetailsModal(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: abnormalResultsCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: abnormalResultsCount > 0 ? const Color(0xFFFCA5A5) : const Color(0xFFA7F3D0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        abnormalResultsCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                        color: abnormalResultsCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        abnormalResultsCount > 0 ? "$abnormalResultsCount Alerts" : "Optimal",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: abnormalResultsCount > 0 ? const Color(0xFF991B1B) : const Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineTimelineSection(List<dynamic> todayReminders) {
    if (todayReminders.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.medication_outlined,
        title: "No Medicines Today",
        description: "You have no scheduled medication reminders for today.",
      );
    }

    return Column(
      children: todayReminders.map((reminder) {
        final id = (reminder['id'] ?? '').toString();
        final name = reminder['medicine_name'] as String? ?? 'Medicine';
        final time = reminder['reminder_time'] as String? ?? '';
        final dose = reminder['dosage'] as String? ?? '';
        final timing = (reminder['timing'] as String?)?.trim();
        final status = reminder['status'] as String? ?? 'pending';

        return MedicineCard(
          medicineName: name,
          time: time,
          dosage: dose,
          instructions: (timing != null && timing.isNotEmpty) ? timing : "After Food",
          status: status,
          onTake: () {
            if (id.isNotEmpty) updateReminderStatus(id, 'taken');
          },
          onSnooze: () {
            if (id.isNotEmpty) _snoozeReminder(id, name, time);
          },
          onSkip: () {
            if (id.isNotEmpty) updateReminderStatus(id, 'skipped');
          },
          onDelete: () {
            if (id.isNotEmpty) _deleteMedication(id);
          },
        );
      }).toList(),
    );
  }

  Widget _buildHealthStatisticsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 132,
                child: StatisticCard(
                  title: "Prescription Scans",
                  value: "$prescriptionScansCount",
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF0F9D8A),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HistoryScreen(language: selectedLanguage)),
                    ).then((_) => _fetchDashboardData());
                  },
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 132,
                child: StatisticCard(
                  title: "Medical Reports",
                  value: "$medicalReportsCount",
                  icon: Icons.description_rounded,
                  color: const Color(0xFF2563EB),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HistoryScreen(language: selectedLanguage)),
                    ).then((_) => _fetchDashboardData());
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 124,
          child: StatisticCard(
            title: "AI Chats",
            value: "$aiChatsCount",
            icon: Icons.chat_bubble_rounded,
            color: const Color(0xFF7C3AED),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SymptomChatScreen(language: selectedLanguage)),
              ).then((_) => _fetchDashboardData());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAIHealthInsightCard() {
    String advice = "Your health overview is optimal. Maintain good hydration and follow your daily routine.";
    if (abnormalResultsCount > 0) {
      advice = "You have $abnormalResultsCount health alerts needing your review. Consult your doctor regarding recent lab reports.";
    } else if (takenCount < _todayTotalCount) {
      advice = "Don't forget to take your remaining medication doses scheduled for today.";
    }

    return InsightCard(
      recommendation: advice,
      onTap: () {
        if (abnormalResultsCount > 0) {
          _showHealthAlertsDetailsModal(context);
        }
      },
    );
  }

  Widget _buildRecentActivitySection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (recentAnalyses.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.history_rounded,
        title: "No Recent Activity",
        description: "Scan your prescriptions or reports to see AI analysis results here.",
      );
    }

    return Column(
      children: recentAnalyses.map((item) {
        final type = (item['type'] as String? ?? 'report').toLowerCase();
        final resultStr = item['result'] as String? ?? '';
        final dateStr = item['created_at'] as String? ?? '';

        String title = "Medical Analysis";
        IconData icon = Icons.event_note_rounded;
        Color color = const Color(0xFF0F9D8A);

        if (type == 'prescription') {
          title = "Prescription Analysis";
          icon = Icons.receipt_long_rounded;
          color = const Color(0xFF0F9D8A);
        } else if (type == 'report') {
          title = "Medical Report Analysis";
          icon = Icons.description_rounded;
          color = const Color(0xFF2563EB);
        } else if (type == 'symptom') {
          title = "Symptom Check";
          icon = Icons.chat_bubble_rounded;
          color = const Color(0xFF7C3AED);
        }

        DateTime dateObj = DateFormatter.parseUtcToIst(dateStr);
        String formattedDate = DateFormatter.formatIST(dateStr);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            onTap: () {
              _showFullAlertDetailDialog(context, title, resultStr, dateObj);
            },
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
            subtitle: Text(
              formattedDate,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.15,
      children: [
        QuickActionCard(
          title: _getText('history'),
          subtitle: _getText('view_records'),
          icon: Icons.history_rounded,
          color: const Color(0xFF0F9D8A),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HistoryScreen(language: selectedLanguage)),
            ).then((_) => _fetchDashboardData());
          },
        ),
        QuickActionCard(
          title: _getText('voice_assistant'),
          subtitle: _getText('speak_with_ai'),
          icon: Icons.mic_rounded,
          color: const Color(0xFF2563EB),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VoiceScreen(language: selectedLanguage)),
            ).then((_) => _fetchDashboardData());
          },
        ),
        QuickActionCard(
          title: _getText('health_timeline'),
          subtitle: _getText('full_history'),
          icon: Icons.timeline_rounded,
          color: const Color(0xFF7C3AED),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HealthTimelineScreen(language: selectedLanguage)),
            ).then((_) => _fetchDashboardData());
          },
        ),
        QuickActionCard(
          title: _getText('emergency_sos'),
          subtitle: _getText('instant_help'),
          icon: Icons.sos_rounded,
          color: const Color(0xFFEF4444),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SosScreen(language: selectedLanguage)),
            );
          },
        ),
      ],
    );
  }

  void _showHealthAlertsDetailsModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: abnormalResultsCount > 0
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFECFDF5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        abnormalResultsCount > 0
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        color: abnormalResultsCount > 0
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getText('alerts_detail_title'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            abnormalResultsCount > 0
                                ? "$abnormalResultsCount ${_getText('active_alerts_sub')}"
                                : _getText('no_active_alerts'),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              Expanded(
                child: healthAlertsList.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFECFDF5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_user_outlined,
                                  size: 48,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _getText('no_active_alerts'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getText('all_optimal'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20.0),
                        itemCount: healthAlertsList.length,
                        itemBuilder: (context, index) {
                          final alert = healthAlertsList[index];
                          return _buildAlertCardItem(context, alert);
                        },
                      ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF0D9488), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _getText('doctor_disclaimer'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF475569),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertCardItem(BuildContext context, Map<String, dynamic> alert) {
    final type = alert['type'] as String? ?? 'report';
    final title = alert['title'] as String? ?? 'Health Alert';
    final dateStr = alert['created_at'] as String? ?? '';
    final warnings = (alert['warnings'] as List<dynamic>?)?.cast<String>() ?? [];
    final rawResult = alert['raw_result'];
    final count = alert['abnormal_count'] ?? 1;

    DateTime? dateObj = DateTime.tryParse(dateStr);
    String formattedDate = dateStr;
    if (dateObj != null) {
      try {
        formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(dateObj.toLocal());
      } catch (_) {}
    }

    final isMedication = type == 'medication';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isMedication ? const Color(0xFFFDE68A) : const Color(0xFFFCA5A5),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                color: isMedication ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  isMedication
                                      ? Icons.medication_liquid_outlined
                                      : Icons.assignment_late_outlined,
                                  color: isMedication
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFFDC2626),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isMedication
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isMedication
                                  ? _getText('missed_med')
                                  : "$count ${_getText('alerts')}",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isMedication
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (formattedDate.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: warnings.map((warn) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("• ",
                                    style: TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                Expanded(
                                  child: Text(
                                    warn,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF334155),
                                      height: 1.35,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isMedication)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D9488),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                Navigator.pop(context);
                                final alertId = (alert['id'] ?? '').toString();
                                if (alertId.isNotEmpty) {
                                  await updateReminderStatus(alertId, 'taken');
                                }
                              },
                              icon: const Icon(Icons.check, size: 16),
                              label: Text(_getText('mark_taken'), style: const TextStyle(fontSize: 12)),
                            )
                          else if (rawResult is String && rawResult.isNotEmpty)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0D9488),
                                side: const BorderSide(color: Color(0xFF0D9488)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                _showFullAlertDetailDialog(
                                  context,
                                  title,
                                  rawResult,
                                  dateObj,
                                );
                              },
                              icon: const Icon(Icons.visibility_outlined, size: 16),
                              label: Text(_getText('view_full_report'), style: const TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullAlertDetailDialog(
      BuildContext context, String title, String result, DateTime? date) {
    showDialog(
      context: context,
      builder: (context) {
        String displayMarkdown = result;
        if (result.trim().startsWith('{')) {
          try {
            final parsed = jsonDecode(result);
            displayMarkdown = parsed['summary'] ?? result;
          } catch (_) {}
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.report_problem_outlined, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (date != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        "Date: ${DateFormat('MMM dd, yyyy • hh:mm a').format(date.toLocal())}",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 12),
                      ),
                    ),
                  MarkdownBody(
                    data: displayMarkdown,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 14, height: 1.5),
                      h3: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                        height: 2.0,
                      ),
                      listBullet: TextStyle(color: Colors.teal.shade700),
                      blockquote: TextStyle(color: Colors.orange.shade900),
                      blockquoteDecoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: const Border(
                          left: BorderSide(color: Colors.orange, width: 4),
                        ),
                      ),
                      blockquotePadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showNextReminderPopup(BuildContext context, Map<String, dynamic>? reminder) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF1CC8B5) : const Color(0xFF0F9D8A);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        if (reminder == null) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  _getText('all_done_today'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "All scheduled medicine reminders for today have been completed.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Close"),
                ),
              ],
            ),
          );
        }

        final id = reminder['id'] as String;
        final medicineName = reminder['medicine_name'] as String? ?? 'Medicine';
        final timeStr = reminder['reminder_time'] as String? ?? '';
        final dosage = reminder['dosage'] as String? ?? '1 Dose';
        final formatted12h = DateFormatter.format12HourTime(timeStr);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.alarm_rounded, color: primaryColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Next Scheduled Reminder",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          medicineName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 18, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              "Scheduled Time:",
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          formatted12h,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.medication_rounded, size: 18, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              "Dosage:",
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          dosage,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _snoozeReminder(id, medicineName, timeStr);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.snooze_rounded, size: 18),
                      label: const Text("Snooze +15m", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        updateReminderStatus(id, 'taken');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text("Mark Taken", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
