import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';

class SymptomChatScreen extends StatefulWidget {
  final String language;
  const SymptomChatScreen({super.key, this.language = 'en'});

  @override
  State<SymptomChatScreen> createState() => _SymptomChatScreenState();
}

class _SymptomChatScreenState extends State<SymptomChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  String _getText(String key) {
    final translations = {
      'en': {
        'title': 'Symptom Checker',
        'hint': 'Describe your symptoms...',
        'error': 'Error: Could not process request.',
      },
      'hi': {
        'title': 'लक्षण जाँचकर्ता',
        'hint': 'अपने लक्षणों का वर्णन करें...',
        'error': 'त्रुटि: अनुरोध संसाधित नहीं किया जा सका।',
      },
      'kn': {
        'title': 'ರೋಗಲಕ್ಷಣ ಪರೀಕ್ಷಕ',
        'hint': 'ನಿಮ್ಮ ರೋಗಲಕ್ಷಣಗಳನ್ನು ವಿವರಿಸಿ...',
        'error': 'ದೋಷ: ವಿನಂತಿಯನ್ನು ಪ್ರಕ್ರಿಯೆಗೊಳಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ.',
      },
      'ta': {
        'title': 'அறிகுறி சரிபார்ப்பவர்',
        'hint': 'உங்கள் அறிகுறிகளை விவரிக்கவும்...',
        'error': 'பிழை: கோரிக்கையைச் செயல்படுத்த முடியவில்லை.',
      },
      'ml': {
        'title': 'ലക്ഷണ പരിശോധകൻ',
        'hint': 'നിങ്ങളുടെ ലക്ഷണങ്ങൾ വിവരിക്കുക...',
        'error': 'പിശക്: അഭ്യർത്ഥന പ്രോസസ്സ് ചെയ്യാൻ കഴിഞ്ഞില്ല.',
      },
      'te': {
        'title': 'లక్షణాల తనిఖీ',
        'hint': 'మీ లక్షణాలను వివరించండి...',
        'error': 'లోపం: అభ్యర్థనను ప్రాసెస్ చేయడం సాధ్యపడలేదు.',
      },
    };
    return translations[widget.language]?[key] ?? translations['en']![key]!;
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _messageController.clear();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final response = await ApiService.checkSymptoms(text, 
        userId: user?.id, 
        lang: widget.language
      );
      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'text': response});
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages
              .add({'role': 'ai', 'text': _getText('error')});
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getText('title')),
        actions: [
          if (_messages.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                final chatExport = _messages.map((m) => "${m['role'] == 'user' ? 'You' : 'Assistant'}: ${m['text']}").join('\n\n');
                ExportService.shareText(chatExport, subject: _getText('title'));
              },
              tooltip: 'Share chat',
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () {
                final chatExport = _messages.map((m) => "${m['role'] == 'user' ? 'You' : 'Assistant'}: ${m['text']}").join('\n\n');
                ExportService.generateAndPrintPdf(title: _getText('title'), content: chatExport);
              },
              tooltip: 'Save as PDF',
            ),
          ]
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.teal[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: MarkdownBody(
                      data: msg['text'] ?? '',
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 16),
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
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _getText('hint'),
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.teal),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
