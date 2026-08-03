import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class HistoryScreen extends StatefulWidget {
  final String language;
  const HistoryScreen({super.key, this.language = 'en'});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _history = [];
  String? _error;

  String _getText(String key) {
    final translations = {
      'en': {
        'title': 'History',
        'no_history': 'No history found.',
        'delete_title': 'Delete History',
        'delete_query': 'Are you sure you want to delete this entry?',
        'cancel': 'Cancel',
        'delete': 'Delete',
        'close': 'Close',
        'date': 'Date',
        'entry_removed': 'Entry removed from history',
        'delete_failed': 'Failed to delete',
        'delete_not_found': 'Could not delete item. It may already be removed.',
        'load_failed': 'Failed to load history',
        'not_logged_in': 'User not logged in',
      },
      'hi': {
        'title': 'इतिहास',
        'no_history': 'कोई इतिहास नहीं मिला।',
        'delete_title': 'इतिहास हटाएं',
        'delete_query': 'क्या आप वाकई इस प्रविष्टि को हटाना चाहते हैं?',
        'cancel': 'रद्द करें',
        'delete': 'हटाएं',
        'close': 'बंद करें',
        'date': 'दिनांक',
        'entry_removed': 'प्रविष्टि इतिहास से हटा दी गई',
        'delete_failed': 'हटाने में विफल',
        'delete_not_found': 'आइटम नहीं हटाया जा सका। हो सकता है कि यह पहले ही हटा दिया गया हो।',
        'load_failed': 'इतिहास लोड करने में विफल',
        'not_logged_in': 'उपयोगकर्ता लॉग इन नहीं है',
      },
      'kn': {
        'title': 'ಇತಿಹಾಸ',
        'no_history': 'ಯಾವುದೇ ಇತಿಹಾಸ ಕಂಡುಬಂದಿಲ್ಲ.',
        'delete_title': 'ಇತಿಹಾಸವನ್ನು ಅಳಿಸಿ',
        'delete_query': 'ನೀವು ಈ ನಮೂದನ್ನು ಅಳಿಸಲು ಖಚಿತವಾಗಿ ಬಯಸುವಿರಾ?',
        'cancel': 'ರದ್ದುಗೊಳಿಸಿ',
        'delete': 'ಅಳಿಸಿ',
        'close': 'ಮುಚ್ಚಿ',
        'date': 'ದಿನಾಂಕ',
        'entry_removed': 'ಇತಿಹಾಸದಿಂದ ನಮೂದನ್ನು ತೆಗೆದುಹಾಕಲಾಗಿದೆ',
        'delete_failed': 'ಅಳಿಸಲು ವಿಫಲವಾಗಿದೆ',
        'delete_not_found': 'ಐಟಂ ಅನ್ನು ಅಳಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ಅದು ಈಗಾಗಲೇ ತೆಗೆದುಹಾಕಲ್ಪಟ್ಟಿರಬಹುದು.',
        'load_failed': 'ಇತಿಹಾಸವನ್ನು ಲೋಡ್ ಮಾಡಲು ವಿಫಲವಾಗಿದೆ',
        'not_logged_in': 'ಬಳಕೆದಾರರು ಲಾಗಿನ್ ಆಗಿಲ್ಲ',
      },
      'ta': {
        'title': 'வரலாறு',
        'no_history': 'வரலாறு எதுவுமில்லை.',
        'delete_title': 'வரலாற்றை நீக்கு',
        'delete_query': 'இந்த பதிவை நீக்க விரும்புகிறீர்களா?',
        'cancel': 'ரத்துசெய்',
        'delete': 'நீக்கு',
        'close': 'மூடு',
        'date': 'தேதி',
        'entry_removed': 'பதிவு வரலாற்றிலிருந்து அகற்றப்பட்டது',
        'delete_failed': 'நீக்க முடியவில்லை',
        'delete_not_found': 'பொருளை நீக்க முடியவில்லை. அது ஏற்கனவே அகற்றப்பட்டிருக்கலாம்.',
        'load_failed': 'வரலாற்றை ஏற்றுவதில் தோல்வி',
        'not_logged_in': 'பயனர் உள்நுழையவில்லை',
      },
      'ml': {
        'title': 'ചരിത്രം',
        'no_history': 'ചരിത്രമൊന്നും കണ്ടെത്തിയില്ല.',
        'delete_title': 'ചരിത്രം ഇല്ലാതാക്കുക',
        'delete_query': 'ഈ എൻട്രി ഇല്ലാതാക്കണമെന്ന് നിങ്ങൾക്ക് ഉറപ്പാണോ?',
        'cancel': 'റദ്ദാക്കുക',
        'delete': 'ഇല്ലാതാക്കുക',
        'close': 'അടയ്ക്കുക',
        'date': 'തീയതി',
        'entry_removed': 'എൻട്രി ചരിത്രത്തിൽ നിന്ന് നീക്കംചെയ്തു',
        'delete_failed': 'ഇല്ലാതാക്കുന്നതിൽ പരാജയപ്പെട്ടു',
        'delete_not_found': 'ഇനം ഇല്ലാതാക്കാൻ കഴിഞ്ഞില്ല. ഇത് ഇതിനകം നീക്കംചെയ്തിട്ടുണ്ടാകാം.',
        'load_failed': 'ചരിത്രം ലോഡ് ചെയ്യുന്നതിൽ പരാജയപ്പെട്ടു',
        'not_logged_in': 'ഉപയോക്താവ് ലോഗിൻ ചെയ്തിട്ടില്ല',
      },
      'te': {
        'title': 'చరిత్ర',
        'no_history': 'చరిత్ర ఏమీ లేదు.',
        'delete_title': 'చరిత్రను తొలగించండి',
        'delete_query': 'మీరు ఈ ఎంట్రీని తొలగించాలనుకుంటున్నారా?',
        'cancel': 'రద్దు చేయండి',
        'delete': 'తొలగించండి',
        'close': 'మూసివేయండి',
        'date': 'తేదీ',
        'entry_removed': 'చరిత్ర నుండి ఎంట్రీ తొలగించబడింది',
        'delete_failed': 'తొలగించడంలో విఫలమైంది',
        'delete_not_found': 'అంశాన్ని తొలగించలేకపోయాము. అది ఇప్పటికే తొలగించబడి ఉండవచ్చు.',
        'load_failed': 'చరిత్రను లోడ్ చేయడం విఫలమైంది',
        'not_logged_in': 'వినియోగదారు లాగిన్ అవ్వలేదు',
      },
    };
    return translations[widget.language]?[key] ?? translations['en']![key]!;
  }

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _error = _getText('not_logged_in');
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

      if (response.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
                content:
                    Text(_getText('delete_not_found'))),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(_getText('entry_removed'))),
          );
        }
      }

      // Refresh the list
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getText('delete_title')),
        content: Text(_getText('delete_query')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getText('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteHistoryItem(id);
            },
            child: Text(_getText('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_getText('title'))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)))
              : _history.isEmpty
                  ? Center(child: Text(_getText('no_history')))
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        final String type = item['type'] ?? 'Unknown';
                        final String resultStr = item['result'] ?? '';
                        final String dateStr = item['created_at'] ?? '';
                        DateTime? createdDate = DateTime.tryParse(dateStr);

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: ListTile(
                            title: Text(type.toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 40,
                                  child: MarkdownBody(
                                    data: resultStr,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  createdDate != null
                                      ? '${createdDate.toLocal()}'
                                      : dateStr,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              onPressed: () => _confirmDelete(item['id']),
                            ),
                            onTap: () {
                              _showFullResult(
                                  context, type, resultStr, createdDate);
                            },
                          ),
                        );
                      },
                    ),
    );
  }

  void _showFullResult(
      BuildContext context, String type, String result, DateTime? date) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(type.toUpperCase()),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (date != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      "${_getText('date')}: ${date.toLocal()}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                MarkdownBody(
                  data: result,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(fontSize: 15, height: 1.5),
                    h3: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                      height: 2.5,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_getText('close')),
            ),
          ],
        );
      },
    );
  }
}
