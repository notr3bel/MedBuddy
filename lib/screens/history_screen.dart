import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/export_service.dart';
import '../services/date_formatter.dart';
import '../main.dart';

class HistoryScreen extends StatefulWidget {
  static const String routeName = '/history';
  final String language;

  const HistoryScreen({super.key, this.language = 'en'});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _history = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _sortAscending = false;
  final TextEditingController _searchController = TextEditingController();

  String _getText(String key) {
    final translations = {
      'en': {
        'title': 'Analysis History',
        'no_history': 'No history found',
        'load_failed': 'Failed to load history',
        'delete_title': 'Delete Entry',
        'delete_query': 'Are you sure you want to delete this analysis entry?',
        'cancel': 'Cancel',
        'delete': 'Delete',
        'entry_removed': 'Entry removed',
        'delete_failed': 'Failed to delete entry',
        'delete_not_found': 'Entry not found or already deleted',
        'date': 'Date',
        'close': 'Close',
        'export': 'Export',
        'share': 'Share',
        'save_pdf': 'Save as PDF',
      },
      'hi': {
        'title': 'विश्लेषण इतिहास',
        'no_history': 'कोई इतिहास नहीं मिला',
        'load_failed': 'इतिहास लोड करने में विफल',
        'delete_title': 'प्रविष्टि हटाएं',
        'delete_query': 'क्या आप वाकई इस प्रविष्टि को हटाना चाहते हैं?',
        'cancel': 'रद्द करें',
        'delete': 'हटाएं',
        'entry_removed': 'प्रविष्टि हटा दी गई',
        'delete_failed': 'प्रविष्टि हटाने में विफल',
        'delete_not_found': 'प्रविष्टि नहीं मिली या पहले ही हटा दी गई',
        'date': 'तारीख',
        'close': 'बंद करें',
        'export': 'निर्यात',
        'share': 'साझा करें',
        'save_pdf': 'पीडीएफ के रूप में सहेजें',
      },
      'kn': {
        'title': 'ವಿಶ್ಲೇಷಣೆಯ ಇತಿಹಾಸ',
        'no_history': 'ಯಾವುದೇ ಇತಿಹಾಸ ಕಂಡುಬಂದಿಲ್ಲ',
        'load_failed': 'ಇತಿಹಾಸವನ್ನು ಲೋಡ್ ಮಾಡಲು ವಿಫಲವಾಗಿದೆ',
        'delete_title': 'ನಮೂದನ್ನು ಅಳಿಸಿ',
        'delete_query': 'ನೀವು ಖಚಿತವಾಗಿ ಈ ವಿಶ್ಲೇಷಣೆಯ ನಮೂದನ್ನು ಅಳಿಸಲು ಬಯಸುವಿರಾ?',
        'cancel': 'ರದ್ದುಮಾಡಿ',
        'delete': 'ಅಳಿಸಿ',
        'entry_removed': 'ನಮೂದನ್ನು ತೆಗೆದುಹಾಕಲಾಗಿದೆ',
        'delete_failed': 'ನಮೂದನ್ನು ಅಳಿಸಲು ವಿಫಲವಾಗಿದೆ',
        'delete_not_found': 'ನಮೂದು ಕಂಡುಬಂದಿಲ್ಲ ಅಥವಾ ಈಗಾಗಲೇ ಅಳಿಸಲಾಗಿದೆ',
        'date': 'ದಿನಾಂಕ',
        'close': 'ಮುಚ್ಚಿ',
        'export': 'ರಫ್ತು ಮಾಡಿ',
        'share': 'ಹಂಚಿಕೊಳ್ಳಿ',
        'save_pdf': 'PDF ಆಗಿ ಉಳಿಸಿ',
      },
      'ta': {
        'title': 'பகுப்பாய்வு வரலாறு',
        'no_history': 'வரலாறு எதுவும் இல்லை',
        'load_failed': 'வரலாற்றை ஏற்றுவதில் தோல்வி',
        'delete_title': 'பதிவை நீக்கு',
        'delete_query': 'இந்த பகுப்பாய்வுப் பதிவை நீக்க நிச்சயமாக விரும்புகிறீர்களா?',
        'cancel': 'ரத்துசெய்',
        'delete': 'நீக்கு',
        'entry_removed': 'பதிவு அகற்றப்பட்டது',
        'delete_failed': 'பதிவை நீக்குவதில் தோல்வி',
        'delete_not_found': 'பதிவு கிடைக்கவில்லை அல்லது ஏற்கனவே நீக்கப்பட்டது',
        'date': 'தேதி',
        'close': 'மூடு',
        'export': 'ஏற்றுமதி',
        'share': 'பகிர்',
        'save_pdf': 'PDF ஆக சேமி',
      },
      'ml': {
        'title': 'വിശകലന ചരിത്രം',
        'no_history': 'ചരിത്രമൊന്നും കണ്ടെത്തിയില്ല',
        'load_failed': 'ചരിത്രം ലോഡ് ചെയ്യുന്നതിൽ പരാജയപ്പെട്ടു',
        'delete_title': 'എൻട്രി ഇല്ലാതാക്കുക',
        'delete_query': 'ഈ വിശകലന എൻട്രി ഇല്ലാതാക്കാൻ നിങ്ങൾ ആഗ്രഹിക്കുന്നുവെന്ന് ഉറപ്പാണോ?',
        'cancel': 'റദ്ദാക്കുക',
        'delete': 'ഇല്ലാതാക്കുക',
        'entry_removed': 'എൻട്രി നീക്കം ചെയ്തു',
        'delete_failed': 'എൻട്രി ഇല്ലാതാക്കുന്നതിൽ പരാജയപ്പെട്ടു',
        'delete_not_found': 'എൻട്രി കണ്ടെത്തിയില്ല അല്ലെങ്കിൽ മുൻപേ ഇല്ലാതാക്കി',
        'date': 'തീയതി',
        'close': 'അടയ്ക്കുക',
        'export': 'എക്സ്പോർട്ട് ചെയ്യുക',
        'share': 'പങ്കിടുക',
        'save_pdf': 'PDF ആയി സംരക്ഷിക്കുക',
      },
      'te': {
        'title': 'విశ్లేషణ చరిత్ర',
        'no_history': 'చరిత్ర కనుగొనబడలేదు',
        'load_failed': 'చరిత్రను లోడ్ చేయడంలో విఫలమైంది',
        'delete_title': 'ఎంట్రీని తొలగించండి',
        'delete_query': 'మీరు ఖచ్చితంగా ఈ విశ్లేషణ ఎంట్రీని తొలగించాలనుకుంటున్నారా?',
        'cancel': 'రద్దు చేయండి',
        'delete': 'తొలగించండి',
        'entry_removed': 'ఎంట్రీ తీసివేయబడింది',
        'delete_failed': 'ఎంట్రీని తొలగించడంలో విఫలమైంది',
        'delete_not_found': 'ఎంట్రీ కనుగొనబడలేదు లేదా ఇప్పటికే తొలగించబడింది',
        'date': 'తేదీ',
        'close': 'మూసివేయి',
        'export': 'ఎగుమతి చేయండి',
        'share': 'షేర్ చేయండి',
        'save_pdf': 'PDFగా సేవ్ చేయండి',
      },
    };
    return translations[widget.language]?[key] ?? translations['en']![key]!;
  }

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _error = "User not logged in";
          _isLoading = false;
        });
        return;
      }

      final response = await supabase
          .from('analysis_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _history = response as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "${_getText('load_failed')}: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteHistoryItem(dynamic id) async {
    try {
      final response = await supabase
          .from('analysis_history')
          .delete()
          .eq('id', id)
          .select();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.isEmpty
                ? _getText('delete_not_found')
                : _getText('entry_removed')),
          ),
        );
      }
      dashboardRefreshNotifier.value++;
      _fetchHistory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${_getText('delete_failed')}: $e")),
        );
      }
    }
  }

  void _confirmDelete(dynamic id) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          _getText('delete_title'),
          style: TextStyle(color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
        ),
        content: Text(
          _getText('delete_query'),
          style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getText('cancel'), style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteHistoryItem(id);
            },
            child: Text(_getText('delete'),
                style: TextStyle(color: isDark ? const Color(0xFFF87171) : Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'prescription':
        return Icons.receipt_long_rounded;
      case 'report':
        return Icons.description_rounded;
      case 'symptom':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.event_note_rounded;
    }
  }

  Color _getColorForType(String type, bool isDark) {
    switch (type.toLowerCase()) {
      case 'prescription':
        return isDark ? const Color(0xFF1CC8B5) : const Color(0xFF0F9D8A);
      case 'report':
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
      case 'symptom':
        return isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);
      default:
        return isDark ? const Color(0xFF1CC8B5) : const Color(0xFF0F9D8A);
    }
  }

  String _getTitleForType(String type) {
    switch (type.toLowerCase()) {
      case 'prescription':
        return 'Prescription Analysis';
      case 'report':
        return 'Medical Report Analysis';
      case 'symptom':
        return 'Symptom Chat Consultation';
      default:
        return 'Health Analysis';
    }
  }

  String _getPreviewText(String type, String resultStr) {
    if (resultStr.isEmpty) return "No preview content available.";
    final clean = ExportService.cleanMarkdown(resultStr).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= 120) return clean;
    return "${clean.substring(0, 120)}...";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF1CC8B5) : const Color(0xFF0F9D8A);

    final categories = ['All', 'Prescription', 'Report', 'Symptom'];

    List<dynamic> items = _history.where((item) {
      final type = (item['type'] ?? '').toString();
      if (type.toLowerCase() == 'skin') return false;
      final resultStr = (item['result'] ?? '').toString();

      final matchesCategory = _selectedCategory == 'All' ||
          type.toLowerCase() == _selectedCategory.toLowerCase();

      final matchesSearch = _searchQuery.isEmpty ||
          type.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          resultStr.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();

    items.sort((a, b) {
      final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
      final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
      return _sortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: Text(_getText('title')),
        backgroundColor: primaryColor,
        foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_sortAscending ? Icons.sort_by_alpha_rounded : Icons.swap_vert_rounded),
            tooltip: _sortAscending ? "Sort Newest First" : "Sort Oldest First",
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search history & medical reports...",
                    hintStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, size: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSel = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              color: isSel
                                  ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                  : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: primaryColor,
                          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          side: BorderSide(
                            color: isSel ? primaryColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : _error != null
                    ? Center(
                        child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : items.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.search_off_rounded, size: 48, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _getText('no_history'),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Try adjusting your search terms or filter selection.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchHistory,
                            color: primaryColor,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final String type = item['type'] ?? 'Unknown';
                                final String resultStr = item['result'] ?? '';
                                final String dateStr = item['created_at'] ?? '';
                                DateTime createdDate = DateFormatter.parseUtcToIst(dateStr);
                                final color = _getColorForType(type, isDark);
                                final icon = _getIconForType(type);
                                final title = _getTitleForType(type);
                                final preview = _getPreviewText(type, resultStr);
                                String formattedDate = DateFormatter.formatIST(dateStr);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.04),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        _showFullResult(context, title, resultStr, createdDate, isDark, primaryColor);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(icon, color: color, size: 20),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        title,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        formattedDate,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.ios_share_rounded,
                                                    color: primaryColor,
                                                    size: 20,
                                                  ),
                                                  tooltip: _getText('export'),
                                                  onPressed: () => _showExportMenu(context, title, resultStr, primaryColor, isDark),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.delete_outline_rounded,
                                                    color: isDark ? const Color(0xFFF87171) : Colors.redAccent,
                                                    size: 20,
                                                  ),
                                                  onPressed: () => _confirmDelete(item['id']),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              preview,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                height: 1.4,
                                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  void _showExportMenu(
      BuildContext context, String title, String content, Color primaryColor, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.share_outlined, color: primaryColor),
                  title: Text(
                    _getText('share'),
                    style: TextStyle(
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ExportService.shareText(content, subject: title);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.picture_as_pdf_outlined, color: primaryColor),
                  title: Text(
                    _getText('save_pdf'),
                    style: TextStyle(
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ExportService.generateAndPrintPdf(title: title, content: content);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullResult(
      BuildContext context, String title, String result, DateTime? date, bool isDark, Color primaryColor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            ),
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
                        "${_getText('date')}: ${DateFormat('MMM dd, yyyy • hh:mm a').format(date.toLocal())}",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  MarkdownBody(
                    data: result,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark ? const Color(0xFFF8FAFC) : Colors.grey.shade800,
                      ),
                      h3: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        height: 2.0,
                      ),
                      listBullet: TextStyle(color: primaryColor),
                      blockquote: TextStyle(color: isDark ? const Color(0xFFFBBF24) : Colors.orange.shade900),
                      blockquoteDecoration: BoxDecoration(
                        color: isDark ? const Color(0xFF451A03) : Colors.orange.withValues(alpha: 0.05),
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
            TextButton.icon(
              icon: const Icon(Icons.share_outlined, size: 18),
              label: Text(_getText('share')),
              style: TextButton.styleFrom(foregroundColor: primaryColor),
              onPressed: () => ExportService.shareText(result, subject: title),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: Text(_getText('save_pdf')),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => ExportService.generateAndPrintPdf(title: title, content: result),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                _getText('close'),
                style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }
}
