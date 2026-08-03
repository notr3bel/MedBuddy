import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'symptom_chat_screen.dart';
import 'history_screen.dart';
import 'sos_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String language;
  final Function(String)? onLanguageChanged;

  const DashboardScreen({super.key, this.language = "en", this.onLanguageChanged});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String selectedLanguage;
  String userName = "User";

  int abnormalResultsCount = 0;
  String latestReportSummary = "No recent reports.";
  List<dynamic> recentAnalyses = [];

  // Track which medicines are marked for the current session to give immediate feedback
  final Set<String> _markedMeds = {};
  List<String> _displayedMeds =
      []; // Start with an empty list instead of mock data
  int takenCount = 0;
  bool _isLoading = true;



  @override
  void initState() {
    super.initState();
    selectedLanguage = widget.language;
    _fetchDashboardData();
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      setState(() {
        selectedLanguage = widget.language;
        _fetchDashboardData();
      });
    }
  }



  Future<void> _fetchDashboardData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      userName = user.userMetadata?['name'] ?? "User";

      try {
        final historyRes = await Supabase.instance.client
            .from('analysis_history')
            .select()
            .order('created_at', ascending: false)
            .limit(5);

        recentAnalyses = historyRes as List<dynamic>;

        // Find latest report and count total abnormal results across all history
        int totalAbnormal = 0;
        String latestRep = "No recent reports.";

        for (var record in recentAnalyses) {
          if (record['type'] == 'report') {
            try {
              final resultStr = record['result'] as String;
              if (resultStr.startsWith('{')) {
                final Map<String, dynamic> parsed = jsonDecode(resultStr);
                totalAbnormal += (parsed['abnormal_count'] ?? 0) as int;
                if (latestRep == "No recent reports.") {
                  latestRep = parsed['summary'] ?? "No summary";
                }
              }
            } catch (e) {
              // Ignore parse errors for older non-JSON reports
            }
          }
        }

        abnormalResultsCount = totalAbnormal;
        latestReportSummary =
            latestRep.isEmpty ? "No recent reports." : latestRep;

        // Fetch user medications (try the user_medications table, fallback to empty if missing)
        try {
          final medsRes = await Supabase.instance.client
              .from('user_medications')
              .select('name')
              .eq('user_id', user.id);

          final List<String> fetchedMeds = (medsRes as List<dynamic>)
              .map((m) => m['name'] as String)
              .toList();

          if (fetchedMeds.isNotEmpty) {
            _displayedMeds = fetchedMeds;
          }
        } catch (e) {
          debugPrint("Note: user_medications table issue: $e");
          String errorMsg = e.toString();
          if (errorMsg.contains('PGRST205')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Database table missing. Please check Supabase schema.'),
                    backgroundColor: Colors.orange),
              );
            }
          } else if (errorMsg.contains('PGRST301') ||
              errorMsg.contains('42501')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Permission denied. Please ensure RLS policies are created.'),
                    backgroundColor: Colors.red),
              );
            }
          }
        }

        // Fetch medicine adherence for today to populate _markedMeds
        final DateTime now = DateTime.now();
        final startOfDay =
            DateTime(now.year, now.month, now.day).toIso8601String();
        final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59)
            .toIso8601String();

        final medLogs = await Supabase.instance.client
            .from('medicine_log')
            .select()
            .eq('user_id', user.id)
            .gte('date', startOfDay)
            .lte('date', endOfDay);

        int todayTaken = 0;
        for (var log in medLogs) {
          _markedMeds.add(log['medicine_name']);
          if (log['status'] == 'taken') {
            todayTaken++;
          }
        }
        takenCount = todayTaken;
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

  String _getText(String key) {
    final translations = {
      'en': {
        'insights': 'Health Insights',
        'issues': 'Issues Detected',
        'meds_taken': 'Medicines Taken',
        'todays_plan': 'Today’s Medicine Plan',
        'quick_actions': 'Quick Actions',
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
      },
      'hi': {
        'insights': 'स्वास्थ्य जानकारी',
        'issues': 'समस्याएं मिलीं',
        'meds_taken': 'दवाएं ली गईं',
        'todays_plan': 'आज का दवा प्लान',
        'quick_actions': 'त्वरित कार्रवाई',
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
      },
      'kn': {
        'insights': 'ಆರೋಗ್ಯ ಒಳನೋಟಗಳು',
        'issues': 'ಸಮಸ್ಯೆಗಳು ಕಂಡುಬಂದಿವೆ',
        'meds_taken': 'ಔಷಧಿಗಳನ್ನು ತೆಗೆದುಕೊಳ್ಳಲಾಗಿದೆ',
        'todays_plan': 'ಇಂದಿನ ಔಷಧಿ ಯೋಜನೆ',
        'quick_actions': 'ತ್ವರಿತ ಕ್ರಮಗಳು',
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
      },
      'ta': {
        'insights': 'சுகாதார நுண்ணறிவு',
        'issues': 'கண்டறியப்பட்ட சிக்கல்கள்',
        'meds_taken': 'மருந்துகள் எடுக்கப்பட்டன',
        'todays_plan': 'இன்றைய மருந்துத் திட்டம்',
        'quick_actions': 'விரைவான செயல்கள்',
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
      },
      'ml': {
        'insights': 'ആരോഗ്യ ഉൾക്കാഴ്ചകൾ',
        'issues': 'പ്രശ്നങ്ങൾ കണ്ടെത്തി',
        'meds_taken': 'മരുന്നുകൾ കഴിച്ചു',
        'todays_plan': 'ഇന്നത്തെ മരുന്ന് പ്ലാൻ',
        'quick_actions': 'വേഗത്തിലുള്ള നടപടികൾ',
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
      },
      'te': {
        'insights': 'ఆరోగ్య సమాచారం',
        'issues': 'కనుగొనబడిన సమస్యలు',
        'meds_taken': 'మందులు తీసుకున్నారు',
        'todays_plan': 'నేటి మందుల ప్రణాళిక',
        'quick_actions': 'త్వరిత చర్యలు',
        'chat': 'లక్షణాల చాట్',
        'history': 'చరిత్ర',
        'sos': 'SOS',
        'hello': 'హలో',
        'taken': 'తీసుకున్నారు',
        'skip': 'వదిలేయండి',
        'remove_med': 'మందును తొలగించండి',
        'remove_med_query': 'మీరు మీ డాష్‌బోర్డ్ నుండి {med}ని తొలగించాలనుకుంటున్నారా?',
        'cancel': 'రద్దు చేయండి',
        'remove': 'తొలగించండి',
        'recent_reports': 'ఇటీవలి నివేదికలు',
        'ai_summary': 'AI సారాంశం',
        'emergency_sos': 'అత్యవసర SOS',
      },
    };
    return translations[selectedLanguage]?[key] ?? translations['en']![key]!;
  }

  Future<void> _markMedicine(String name, String status) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('medicine_log').insert({
        'user_id': user.id,
        'medicine_name': name,
        'status': status,
        'date': DateTime.now().toIso8601String(),
      });

      setState(() {
        _markedMeds.add(name);
        if (status == 'taken') {
          takenCount++;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Medicine marked as $status'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error logging medicine: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteMedication(String name) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('user_medications')
          .delete()
          .eq('user_id', user.id)
          .eq('name', name);

      setState(() {
        _displayedMeds.remove(name);
        _markedMeds.remove(name);
        // Recalculate takenCount if needed (optional, depends on if we want historical logs to stay)
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name removed from dashboard')),
        );
      }
    } catch (e) {
      debugPrint("Error deleting medication: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error removing medicine: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("MedIntel"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
            left: 16.0, right: 16.0, top: 20.0, bottom: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${_getText('hello')} $userName 👋",
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 24),
            Text(_getText('insights'),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildMetricCard(
                        _getText('issues'),
                        abnormalResultsCount.toString(),
                        Icons.warning_amber_rounded,
                        Colors.orange)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildMetricCard(
                        _getText('meds_taken'),
                        "$takenCount / ${_displayedMeds.length}",
                        Icons.medication_liquid,
                        Colors.blue)),
              ],
            ),
            const SizedBox(height: 20),
            Text(_getText('recent_reports'),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.monitor_heart, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(_getText('ai_summary'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      latestReportSummary,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(height: 1.5, color: Colors.grey[800], fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(_getText('todays_plan'),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
            const SizedBox(height: 12),
            ..._displayedMeds.map((med) {
              final bool isMarked = _markedMeds.contains(med);
              return Dismissible(
                key: Key(med),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(_getText('remove_med')),
                        content: Text(
                            _getText('remove_med_query').replaceFirst('{med}', med)),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(false),
                            child: Text(_getText('cancel')),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(true),
                            child: Text(_getText('remove'),
                                style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  _deleteMedication(med);
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: isMarked ? Colors.grey[200] : Colors.white,
                  elevation: 1,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isMarked ? Colors.grey[300] : Colors.blue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.medication,
                          color: isMarked ? Colors.grey : Colors.blue),
                    ),
                    title: Text(med,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: isMarked
                                ? TextDecoration.lineThrough
                                : null,
                            color: isMarked ? Colors.grey : Colors.black87)),
                    trailing: isMarked
                        ? const Icon(Icons.check_circle, color: Colors.blue, size: 28)
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                child: Text(_getText('skip'),
                                    style: const TextStyle(color: Colors.grey)),
                                onPressed: () =>
                                    _markMedicine(med, 'skipped'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)
                                    )
                                ),
                                child: Text(_getText('taken')),
                                onPressed: () =>
                                    _markMedicine(med, 'taken'),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            Text(_getText('quick_actions'),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildNavTile(context, _getText('chat'), Icons.chat_bubble_outline,
                    SymptomChatScreen(language: selectedLanguage), color: Colors.purple),
                _buildNavTile(context, _getText('history'), Icons.history,
                    HistoryScreen(language: selectedLanguage), color: Colors.teal),
                _buildNavTile(context, _getText('emergency_sos'), Icons.warning_rounded,
                    SosScreen(language: selectedLanguage),
                    isEmergency: true, color: Colors.redAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile(
      BuildContext context, String title, IconData icon, Widget destination,
      {bool isEmergency = false, Color? color}) {
    Color primaryColor = isEmergency ? Colors.redAccent : (color ?? Colors.blue);
    
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: primaryColor.withValues(alpha: 0.2), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
              context, MaterialPageRoute(builder: (context) => destination));
          // Refresh data when returning to dashboard
          _fetchDashboardData();
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isEmergency ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: primaryColor),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
