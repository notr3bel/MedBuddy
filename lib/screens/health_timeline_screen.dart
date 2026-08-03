import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class HealthTimelineScreen extends StatefulWidget {
  final String language;
  const HealthTimelineScreen({super.key, this.language = "en"});

  @override
  State<HealthTimelineScreen> createState() => _HealthTimelineScreenState();
}

class _HealthTimelineScreenState extends State<HealthTimelineScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _history = [];
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(HealthTimelineScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      // Fetch History
      final response = await supabase
          .from('analysis_history')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      // Fetch AI Summary from backend
      final summary = await ApiService.getHealthSummary(user.id, lang: widget.language);

      setState(() {
        _history = response as List<dynamic>;
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getText(String key) {
    final translations = {
      'en': {
        'title': 'Health Timeline',
        'summary': 'Health Summary',
        'events': 'Events',
        'common_issue': 'MOST COMMON ISSUE',
        'rec': 'RECOMMENDATION',
        'no_events': 'No health events found.',
        'unknown': 'Unknown',
        'no_rec': 'No suggestion available.',
        'prescription': 'Prescription Analysis',
        'report': 'Medical Report',
        'skin': 'Skin Analysis',
        'symptom': 'Symptom Check',
        'event': 'Health Event',
        'retry': 'Retry',
      },
      'hi': {
        'title': 'स्वास्थ्य समयरेखा',
        'summary': 'स्वास्थ्य सारांश',
        'events': 'घटनाएं',
        'common_issue': 'सबसे आम समस्या',
        'rec': 'सिफारिश',
        'no_events': 'कोई स्वास्थ्य घटना नहीं मिली।',
        'unknown': 'अज्ञात',
        'no_rec': 'कोई सुझाव उपलब्ध नहीं है।',
        'prescription': 'नुस्खा विश्लेषण',
        'report': 'मेडिकल रिपोर्ट',
        'skin': 'त्वचा विश्लेषण',
        'symptom': 'लक्षण जांच',
        'event': 'स्वास्थ्य घटना',
        'retry': 'पुनः प्रयास करें',
      },
      'kn': {
        'title': 'ಆರೋಗ್ಯ ಕಾಲಸೂಚಿ',
        'summary': 'ಆರೋಗ್ಯ ಸಾರಾಂಶ',
        'events': 'ಘಟನೆಗಳು',
        'common_issue': 'ಅತ್ಯಂತ ಸಾಮಾನ್ಯ ಸಮಸ್ಯೆ',
        'rec': 'ಶಿಫಾರಸು',
        'no_events': 'ಯಾವುದೇ ಆರೋಗ್ಯ ಘಟನೆಗಳು ಕಂಡುಬಂದಿಲ್ಲ.',
        'unknown': 'ಅಪರಿಚಿತ',
        'no_rec': 'ಯಾವುದೇ ಸಲಹೆ ಲಭ್ಯವಿಲ್ಲ.',
        'prescription': 'ಪ್ರಿಸ್ಕ್ರಿಪ್ಷನ್ ವಿಶ್ಲೇಷಣೆ',
        'report': 'ವೈದ್ಯಕೀಯ ವರದಿ',
        'skin': 'ಚರ್ಮದ ವಿಶ್ಲೇಷಣೆ',
        'symptom': 'ರೋಗಲಕ್ಷಣದ ತಪಾಸಣೆ',
        'event': 'ಆರೋಗ್ಯ ಘಟನೆ',
        'retry': 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',
      },
      'ta': {
        'title': 'சுகாதார காலவரிசை',
        'summary': 'சுகாதார சுருக்கம்',
        'events': 'நிகழ்வுகள்',
        'common_issue': 'மிகவும் பொதுவான பிரச்சனை',
        'rec': 'பரிந்துரை',
        'no_events': 'சுகாதார நிகழ்வுகள் எதுவும் காணப்படவில்லை.',
        'unknown': 'தெரியவில்லை',
        'no_rec': 'பரிந்துரை எதுவும் இல்லை.',
        'prescription': 'மருந்துச் சீட்டு பகுப்பாய்வு',
        'report': 'மருத்துவ அறிக்கை',
        'skin': 'தோல் பகுப்பாய்வு',
        'symptom': 'அறிகுறி சரிபார்ப்பு',
        'event': 'சுகாதார நிகழ்வு',
        'retry': 'மீண்டும் முயற்சி செய்க',
      },
      'ml': {
        'title': 'ആരോഗ്യ രേഖ',
        'summary': 'ആരോഗ്യ സംഗ്രഹം',
        'events': 'സംഭവങ്ങൾ',
        'common_issue': 'ഏറ്റവും സാധാരണമായ പ്രശ്നം',
        'rec': 'ശുപാർശ',
        'no_events': 'ആരോഗ്യ സംഭവങ്ങൾ ഒന്നും കണ്ടെത്തിയില്ല.',
        'unknown': 'അജ്ഞാതം',
        'no_rec': 'ശുപാർശകളൊന്നുമില്ല.',
        'prescription': 'കുറിപ്പടി വിശകലനം',
        'report': 'മെഡിക്കൽ റിപ്പോർട്ട്',
        'skin': 'ചർമ്മ വിശകലനം',
        'symptom': 'ലക്ഷണ പരിശോധന',
        'event': 'ആരോഗ്യ സംഭവം',
        'retry': 'വീണ്ടും ശ്രമിക്കുക',
      },
      'te': {
        'title': 'ఆరోగ్య కాలక్రమం',
        'summary': 'ఆరోగ్య సారాంశం',
        'events': 'ఘటనలు',
        'common_issue': 'అత్యంత సాధారణ సమస్య',
        'rec': 'సిఫార్సు',
        'no_events': 'ఆరోగ్య ఘటనలు ఏవీ కనుగొనబడలేదు.',
        'unknown': 'తెలియదు',
        'no_rec': 'ఎటువంటి సూచన అందుబాటులో లేదు.',
        'prescription': 'ప్రిస్క్రిప్షన్ విశ్లేషణ',
        'report': 'వైద్య నివేదిక',
        'skin': 'చర్మ విశ్లేషణ',
        'symptom': 'లక్షణాల తనిఖీ',
        'event': 'ఆరోగ్య సంఘటన',
        'retry': 'మళ్ళీ ప్రయత్నించండి',
      },
    };
    return translations[widget.language]?[key] ?? translations['en']![key]!;
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'prescription':
        return Icons.medical_services;
      case 'report':
        return Icons.assignment;
      case 'skin':
        return Icons.healing;
      case 'symptom':
        return Icons.chat;
      default:
        return Icons.event;
    }
  }

  String _getTitleForType(String type) {
    switch (type.toLowerCase()) {
      case 'prescription':
        return _getText('prescription');
      case 'report':
        return _getText('report');
      case 'skin':
        return _getText('skin');
      case 'symptom':
        return _getText('symptom');
      default:
        return _getText('event');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getText('title')),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $_error', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchData,
                          child: Text(_getText('retry')),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      if (_summary != null)
                        SliverToBoxAdapter(
                          child: _buildSummaryCard(),
                        ),
                      if (_history.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Text(_getText('no_events')),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final event = _history[index];
                              final isFirst = index == 0;
                              final isLast = index == _history.length - 1;
                              return _buildTimelineTile(event, isFirst, isLast);
                            },
                            childCount: _history.length,
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                _getText('summary'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_summary!['total_events']} ${_getText('events')}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _getText('common_issue'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _summary!['most_common_condition'] ?? _getText('unknown'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Divider(color: Colors.white24, height: 24),
          Text(
            _getText('rec'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _summary!['suggestion'] ?? _getText('no_rec'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTile(dynamic event, bool isFirst, bool isLast) {
    final DateTime createdAt = DateTime.parse(event['created_at']).toLocal();
    final String dateStr = DateFormat('MMM dd, yyyy').format(createdAt);
    final String timeStr = DateFormat('hh:mm a').format(createdAt);
    final String type = event['type'];
    final String result = event['result'];

    return TimelineTile(
      alignment: TimelineAlign.manual,
      lineXY: 0.2,
      isFirst: isFirst,
      isLast: isLast,
      indicatorStyle: IndicatorStyle(
        width: 40,
        height: 40,
        indicator: Container(
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.teal, width: 2),
          ),
          child: Icon(
            _getIconForType(type),
            color: Colors.teal,
            size: 20,
          ),
        ),
      ),
      beforeLineStyle: LineStyle(
        color: Colors.teal.withValues(alpha: 0.5),
        thickness: 2,
      ),
      afterLineStyle: LineStyle(
        color: Colors.teal.withValues(alpha: 0.5),
        thickness: 2,
      ),
      startChild: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerRight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              dateStr,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Colors.black87,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade600,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      endChild: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: _buildEventCard(type, result),
      ),
    );
  }

  Widget _buildEventCard(String type, String result) {
    String displayResult = result;
    if (type == 'report' && result.startsWith('{')) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(result));
        displayResult = decoded['summary'] ?? result;
      } catch (e) {
        // Fallback to raw result if not JSON
      }
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          dense: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          visualDensity: VisualDensity.compact,
          leading: Icon(_getIconForType(type), color: Colors.teal, size: 20),
          title: Text(
            _getTitleForType(type),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.1),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            displayResult.split('\n').first.trim(),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.1),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                displayResult,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
