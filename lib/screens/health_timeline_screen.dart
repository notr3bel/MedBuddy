import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../services/date_formatter.dart';

class HealthTimelineScreen extends StatefulWidget {
  final String language;
  const HealthTimelineScreen({super.key, this.language = "en"});

  @override
  State<HealthTimelineScreen> createState() => _HealthTimelineScreenState();
}

class _HealthTimelineScreenState extends State<HealthTimelineScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final supabase = Supabase.instance.client;
  List<dynamic> _history = [];
  bool _isLoadingHistory = true;
  String? _error;
  String _selectedFilter = 'All';

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

  List<dynamic> get _filteredHistory {
    final visibleHistory = _history.where((item) {
      final type = (item['type'] as String? ?? '').toLowerCase();
      return type != 'skin';
    }).toList();
    if (_selectedFilter == 'All') return visibleHistory;
    return visibleHistory.where((item) {
      final type = (item['type'] as String? ?? '').toLowerCase();
      return type == _selectedFilter.toLowerCase();
    }).toList();
  }

  Widget _buildFilterChips(bool isDark) {
    final filters = ['All', 'Prescription', 'Report', 'Symptom'];
    final primaryColor = isDark ? const Color(0xFF1CC8B5) : const Color(0xFF0F9D8A);

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected
                      ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                      : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              selectedColor: primaryColor,
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              side: BorderSide(
                color: isSelected ? primaryColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoadingHistory = true;
      _error = null;
    });

    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _error = "User not logged in";
        _isLoadingHistory = false;
      });
      return;
    }

    try {
      final response = await supabase
          .from('analysis_history')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _history = response as List<dynamic>;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingHistory = false;
        });
      }
    }
  }

  String _getText(String key) {
    final translations = {
      'en': {
        'title': 'Health Timeline',
        'events': 'Events',
        'no_events': 'No health events found.',
        'unknown': 'Unknown',
        'prescription': 'Prescription Analysis',
        'report': 'Medical Report',
        'skin': 'Skin Analysis',
        'symptom': 'Symptom Check',
        'event': 'Health Event',
        'retry': 'Retry',
      },
      'hi': {
        'title': 'स्वास्थ्य समयरेखा',
        'events': 'घटनाएं',
        'no_events': 'कोई स्वास्थ्य घटना नहीं मिली।',
        'unknown': 'अज्ञात',
        'prescription': 'नुस्खा विश्लेषण',
        'report': 'मेडिकल रिपोर्ट',
        'skin': 'त्वचा विश्लेषण',
        'symptom': 'लक्षण जांच',
        'event': 'स्वास्थ्य घटना',
        'retry': 'पुनः प्रयास करें',
      },
      'kn': {
        'title': 'ಆರೋಗ್ಯ ಕಾಲಸೂಚಿ',
        'events': 'ಘಟನೆಗಳು',
        'no_events': 'ಯಾವುದೇ ಆರೋಗ್ಯ ಘಟನೆಗಳು ಕಂಡುಬಂದಿಲ್ಲ.',
        'unknown': 'ಅಪರಿಚಿತ',
        'prescription': 'ಪ್ರಿಸ್ಕ್ರಿಪ್ಷನ್ ವಿಶ್ಲೇಷಣೆ',
        'report': 'ವೈದ್ಯಕೀಯ ವರದಿ',
        'skin': 'ಚರ್ಮದ ವಿಶ್ಲೇಷಣೆ',
        'symptom': 'ರೋಗಲಕ್ಷಣದ ತಪಾಸಣೆ',
        'event': 'ಆರೋಗ್ಯ ಘಟನೆ',
        'retry': 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',
      },
      'ta': {
        'title': 'சுகாதார காலவரிசை',
        'events': 'நிகழ்வுகள்',
        'no_events': 'சுகாதார நிகழ்வுகள் எதுவும் காணப்படவில்லை.',
        'unknown': 'தெரியவில்லை',
        'prescription': 'மருந்துச் சீட்டு பகுப்பாய்வு',
        'report': 'மருத்துவ அறிக்கை',
        'skin': 'தோல் பகுப்பாய்வு',
        'symptom': 'அறிகுறி சரிபார்ப்பு',
        'event': 'சுகாதார நிகழ்வு',
        'retry': 'மீண்டும் முயற்சி செய்க',
      },
      'ml': {
        'title': 'ആരോഗ്യ രേഖ',
        'events': 'സംഭവങ്ങൾ',
        'no_events': 'ആരോഗ്യ സംഭവങ്ങൾ ഒന്നും കണ്ടെത്തിയില്ല.',
        'unknown': 'അജ്ഞാതം',
        'prescription': 'കുറിപ്പടി വിശകലനം',
        'report': 'മെഡിക്കൽ റിപ്പോർട്ട്',
        'skin': 'ചർമ്മ വിശകലനം',
        'symptom': 'ലക്ഷണ പരിശോധന',
        'event': 'ആരോഗ്യ സംഭവം',
        'retry': 'വീണ്ടും ശ്രമിക്കുക',
      },
      'te': {
        'title': 'ఆరోగ్య కాలక్రమం',
        'events': 'ఘటనలు',
        'no_events': 'ఆరోగ్య ఘటనలు ఏవీ కనుగొనబడలేదు.',
        'unknown': 'తెలియదు',
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
        return Icons.medical_services_rounded;
      case 'report':
        return Icons.assignment_rounded;
      case 'symptom':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  String _getTitleForType(String type) {
    switch (type.toLowerCase()) {
      case 'prescription':
        return _getText('prescription');
      case 'report':
        return _getText('report');
      case 'symptom':
        return _getText('symptom');
      default:
        return _getText('event');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF1CC8B5) : const Color(0xFF0F9D8A);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: Text(_getText('title')),
        backgroundColor: primaryColor,
        foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: _fetchData,
        child: _isLoadingHistory
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: $_error',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                          ),
                          child: Text(_getText('retry')),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildFilterChips(isDark),
                      ),
                      if (_filteredHistory.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                _getText('no_events'),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final event = _filteredHistory[index];
                              final isFirst = index == 0;
                              final isLast = index == _filteredHistory.length - 1;
                              return _buildTimelineTile(event, isFirst, isLast, isDark, primaryColor);
                            },
                            childCount: _filteredHistory.length,
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildTimelineTile(dynamic event, bool isFirst, bool isLast, bool isDark, Color primaryColor) {
    final String rawDateStr = event['created_at'] ?? '';
    final String dateStr = DateFormatter.formatISTDate(rawDateStr);
    final String timeStr = DateFormatter.formatISTTime(rawDateStr);
    final String type = event['type'] ?? 'event';
    final String result = event['result'] ?? '';

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
            color: primaryColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor, width: 2),
          ),
          child: Icon(
            _getIconForType(type),
            color: primaryColor,
            size: 20,
          ),
        ),
      ),
      beforeLineStyle: LineStyle(
        color: primaryColor.withValues(alpha: 0.4),
        thickness: 2,
      ),
      afterLineStyle: LineStyle(
        color: primaryColor.withValues(alpha: 0.4),
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 9,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
        child: _buildEventCard(type, result, isDark, primaryColor),
      ),
    );
  }

  Widget _buildEventCard(String type, String result, bool isDark, Color primaryColor) {
    String displayResult = result;
    if (type.toLowerCase() == 'report' && result.startsWith('{')) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(result));
        displayResult = decoded['summary'] ?? result;
      } catch (e) {
        // Fallback to raw result if not JSON
      }
    }

    String preview = displayResult.replaceAll(RegExp(r'[#*`_>-\\]'), ' ');
    preview = preview.replaceAll(RegExp(r'\s+'), ' ').trim();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          colorScheme: Theme.of(context).colorScheme.copyWith(
                onSurface: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
        ),
        child: ExpansionTile(
          dense: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          visualDensity: VisualDensity.compact,
          iconColor: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          collapsedIconColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_getIconForType(type), color: primaryColor, size: 18),
          ),
          title: Text(
            _getTitleForType(type),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            preview,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(
                displayResult,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
