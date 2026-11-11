import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';
import '../main.dart';

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
  @override
  void didUpdateWidget(covariant SymptomChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      setState(() {});
    }
  }

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
      final response = await ApiService.checkSymptoms(
        text,
        userId: user?.id,
        lang: widget.language,
      );
      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'text': response});
        });
        dashboardRefreshNotifier.value++;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'text': _getText('error')});
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF1CC8B5) : const Color(0xFF0F9D8A);

    final suggestedSymptoms = [
      "Fever & Body Ache 🤒",
      "Persistent Headache 💆‍♂️",
      "Stomach Pain & Nausea 🤢",
      "Dry Cough & Sore Throat 😷",
      "Skin Rash & Itching 🧴",
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: Text(_getText('title')),
        backgroundColor: primaryColor,
        foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        actions: [
          if (_messages.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () {
                final chatExport = _messages
                    .map((m) => "${m['role'] == 'user' ? 'You' : 'Assistant'}: ${m['text']}")
                    .join('\n\n');
                ExportService.shareText(chatExport, subject: _getText('title'));
              },
              tooltip: 'Share chat',
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              onPressed: () {
                final chatExport = _messages
                    .map((m) => "${m['role'] == 'user' ? 'You' : 'Assistant'}: ${m['text']}")
                    .join('\n\n');
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
            child: _messages.isEmpty
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Container(
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
                                color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.health_and_safety_rounded, color: primaryColor, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "AI Symptom Checker",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Describe what you're feeling for immediate guidance.",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          "Popular Health Questions",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 10,
                          children: suggestedSymptoms.map((symptom) {
                            return ActionChip(
                              avatar: Icon(Icons.medical_services_outlined, size: 14, color: primaryColor),
                              label: Text(
                                symptom,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                ),
                              ),
                              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              side: BorderSide(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              onPressed: () {
                                _messageController.text = symptom.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), '').trim();
                                _sendMessage();
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14.0),
                          padding: const EdgeInsets.all(16.0),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.82,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? primaryColor
                                : (isDark ? const Color(0xFF1E293B) : Colors.white),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                              bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                            ),
                            border: Border.all(
                              color: isUser
                                  ? primaryColor
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
                                    size: 14,
                                    color: isUser
                                        ? (isDark ? const Color(0xFF0F172A) : Colors.white70)
                                        : primaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isUser ? "You" : "MedBuddy AI",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isUser
                                          ? (isDark ? const Color(0xFF0F172A) : Colors.white70)
                                          : primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              MarkdownBody(
                                data: msg['text'] ?? '',
                                styleSheet: MarkdownStyleSheet(
                                  p: TextStyle(
                                    fontSize: 15,
                                    color: isUser
                                        ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                        : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                                    height: 1.4,
                                  ),
                                  listBullet: TextStyle(
                                    color: isUser
                                        ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                        : primaryColor,
                                  ),
                                  blockquote: TextStyle(
                                    color: isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B),
                                  ),
                                  blockquoteDecoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF451A1A) : const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border(
                                      left: BorderSide(
                                        color: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                  blockquotePadding: const EdgeInsets.all(12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "MedIntel is analyzing your symptoms...",
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: _getText('hint'),
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.send_rounded,
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      size: 20,
                    ),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
