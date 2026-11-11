import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/voice_service.dart';
import '../services/api_service.dart';

class VoiceScreen extends StatefulWidget {
  final String language;

  const VoiceScreen({super.key, this.language = "en"});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isLoading = false;
  late String _recognizedText;
  String _assistantResponse = "";

  String _getText(String key) {
    final translations = {
      'en': {
        'title': 'Voice Assistant',
        'ask_title': 'Ask MedIntel AI Voice',
        'ask_sub': 'Hold the mic button below to ask health questions or tap a suggestion:',
        'prompt_rx': 'Explain my prescription',
        'prompt_report': 'Explain my report',
        'prompt_symptoms': 'Check symptoms',
        'prompt_diet': 'Diet suggestions',
        'prompt_side_effects': 'Medicine side effects',
        'tap_to_speak': 'Tap the microphone and start speaking...',
        'listening': 'Listening...',
        'release_to_send': 'Release to send',
        'hold_to_speak': 'Hold to speak',
        'error': 'Error getting response. Please try again.',
        'perm_denied': 'Microphone or Speech permission denied. Please enable them in settings.',
        'you': 'You',
        'assistant': 'Assistant',
      },
      'hi': {
        'title': 'वॉइस असिस्टेंट',
        'ask_title': 'MedIntel AI वॉइस से पूछें',
        'ask_sub': 'स्वास्थ्य प्रश्न पूछने के लिए नीचे दिए गए माइक बटन को दबाकर रखें या सुझाव पर टैप करें:',
        'prompt_rx': 'मेरा नुस्खा समझाइए',
        'prompt_report': 'मेरी रिपोर्ट समझाइए',
        'prompt_symptoms': 'लक्षणों की जाँच करें',
        'prompt_diet': 'आहार सुझाव',
        'prompt_side_effects': 'दवा के दुष्प्रभाव',
        'tap_to_speak': 'माइक्रोफोन पर टैप करें और बोलना शुरू करें...',
        'listening': 'सुन रहा हूँ...',
        'release_to_send': 'भेजने के लिए छोड़ें',
        'hold_to_speak': 'बोलने के लिए दबाकर रखें',
        'error': 'जवाब मिलने में त्रुटि। कृपया पुनः प्रयास करें।',
        'perm_denied': 'माइक्रोफ़ोन या भाषण की अनुमति नहीं दी गई। कृपया उन्हें सेटिंग में सक्षम करें।',
        'you': 'आप',
        'assistant': 'सहायक',
      },
      'kn': {
        'title': 'ಧ್ವನಿ ಸಹಾಯಕ',
        'ask_title': 'MedIntel AI ಧ್ವನಿಯನ್ನು ಕೇಳಿ',
        'ask_sub': 'ಆರೋಗ್ಯ ಪ್ರಶ್ನೆಗಳನ್ನು ಕೇಳಲು ಕೆಳಗಿನ ಮೈಕ್ ಬಟನ್ ಹಿಡಿದುಕೊಳ್ಳಿ ಅಥವಾ ಸಲಹೆಯನ್ನು ಟ್ಯಾಪ್ ಮಾಡಿ:',
        'prompt_rx': 'ನನ್ನ ಪ್ರಿಸ್ಕ್ರಿಪ್ಷನ್ ವಿವರಿಸಿ',
        'prompt_report': 'ನನ್ನ ವರದಿಯನ್ನು ವಿವರಿಸಿ',
        'prompt_symptoms': 'ರೋಗಲಕ್ಷಣಗಳನ್ನು ಪರೀಕ್ಷಿಸಿ',
        'prompt_diet': 'ಆಹಾರ ಸಲಹೆಗಳು',
        'prompt_side_effects': 'ಔಷಧಿಯ ಅಡ್ಡಪರಿಣಾಮಗಳು',
        'tap_to_speak': 'ಮೈಕ್ರೊಫೋನ್ ಟ್ಯಾಪ್ ಮಾಡಿ ಮತ್ತು ಮಾತನಾಡಲು ಪ್ರಾರಂಭಿಸಿ...',
        'listening': 'ಕೇಳಿಸಿಕೊಳ್ಳುತ್ತಿದ್ದೇನೆ...',
        'release_to_send': 'ಕಳುಹಿಸಲು ಬಿಡುಗಡೆ ಮಾಡಿ',
        'hold_to_speak': 'ಮಾತನಾಡಲು ಹಿಡಿದುಕೊಳ್ಳಿ',
        'error': 'ಪ್ರತಿಕ್ರಿಯೆ ಪಡೆಯುವಲ್ಲಿ ದೋಷ. ದಯವಿಟ್ಟು ಮತ್ತೊಮ್ಮೆ ಪ್ರಯತ್ನಿಸಿ.',
        'perm_denied': 'ಮೈಕ್ರೊಫೋನ್ ಅಥವಾ ಭಾಷಣ ಅನುಮತಿಯನ್ನು ನಿರಾಕರಿಸಲಾಗಿದೆ. ದಯವಿಟ್ಟು ಅವುಗಳನ್ನು ಸೆಟ್ಟಿಂಗ್‌ಗಳಲ್ಲಿ ಸಕ್ರಿಯಗೊಳಿಸಿ.',
        'you': 'ನೀವು',
        'assistant': 'ಸಹಾಯಕ',
      },
      'ta': {
        'title': 'குரல் உதவியாளர்',
        'ask_title': 'MedIntel AI குரலிடம் கேளுங்கள்',
        'ask_sub': 'சுகாதாரக் கேள்விகளைக் கேட்க கீழே உள்ள மைக் பொத்தானை அழுத்திப் பிடிக்கவும் அல்லது ஆலோசனையைத் தட்டவும்:',
        'prompt_rx': 'என் மருந்துச் சீட்டை விளக்குங்கள்',
        'prompt_report': 'என் அறிக்கையை விளக்குங்கள்',
        'prompt_symptoms': 'அறிகுறிகளைச் சரிபார்க்கவும்',
        'prompt_diet': 'உணவு ஆலோசனைகள்',
        'prompt_side_effects': 'மருந்து பக்க விளைவுகள்',
        'tap_to_speak': 'மைக்ரோஃபோனைத் தட்டி பேசத் தொடங்குங்கள்...',
        'listening': 'கேட்கிறது...',
        'release_to_send': 'அனுப்ப விடுவிக்கவும்',
        'hold_to_speak': 'பேச அழுத்திப் பிடிக்கவும்',
        'error': 'பதில் பெறுவதில் பிழை. மீண்டும் முயற்சிக்கவும்.',
        'perm_denied': 'மைக்ரோஃபோன் அல்லது பேச்சு அனுமதி மறுக்கப்பட்டது. அமைப்புகளில் அவற்றை இயக்கவும்.',
        'you': 'நீங்கள்',
        'assistant': 'உதவியாளர்',
      },
      'ml': {
        'title': 'വോയിസ് അസിസ്റ്റന്റ്',
        'ask_title': 'MedIntel AI വോയിസിനോട് ചോദിക്കുക',
        'ask_sub': 'ആരോഗ്യ ചോദ്യങ്ങൾ ചോദിക്കാൻ താഴെയുള്ള മൈക്ക് ബട്ടൺ അമർത്തിപ്പിടിക്കുക അല്ലെങ്കിൽ നിർദ്ദേശത്തിൽ ടാപ്പ് ചെയ്യുക:',
        'prompt_rx': 'എന്റെ മരുന്ന് കുറിപ്പടി വിശദീകരിക്കുക',
        'prompt_report': 'എന്റെ റിപ്പോർട്ട് വിശദീകരിക്കുക',
        'prompt_symptoms': 'ലക്ഷണങ്ങൾ പരിശോധിക്കുക',
        'prompt_diet': 'ഭക്ഷണ നിർദ്ദേശങ്ങൾ',
        'prompt_side_effects': 'മരുന്നിന്റെ പാർശ്വഫലങ്ങൾ',
        'tap_to_speak': 'മൈക്രോഫോണിൽ ടാപ്പ് ചെയ്ത് സംസാരിക്കാൻ തുടങ്ങുക...',
        'listening': 'ശ്രദ്ധിക്കുന്നു...',
        'release_to_send': 'അയയ്ക്കാൻ വിടുക',
        'hold_to_speak': 'സംസാരിക്കാൻ അമർത്തിപ്പിടിക്കുക',
        'error': 'പ്രതികരണം ലഭിക്കുന്നതിൽ പിശക്. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
        'perm_denied': 'മൈക്രോഫോൺ അല്ലെങ്കിൽ സംസാര അനുമതി നിഷേധിക്കപ്പെട്ടു. ക്രമീകരണങ്ങളിൽ അവ പ്രവർത്തനക്ഷമമാക്കുക.',
        'you': 'നിങ്ങൾ',
        'assistant': 'അസിസ്റ്റന്റ്',
      },
      'te': {
        'title': 'వాయిస్ అసిస్టెంట్',
        'ask_title': 'MedIntel AI వాయిస్‌ని అడగండి',
        'ask_sub': 'ఆరోగ్య ప్రశ్నలను అడగడానికి దిగువన ఉన్న మైక్ బటన్‌ను పట్టుకోండి లేదా సూచనను నొక్కండి:',
        'prompt_rx': 'నా ప్రిస్క్రిప్షన్‌ను వివరించండి',
        'prompt_report': 'నా నివేదికను వివరించండి',
        'prompt_symptoms': 'లక్షణాలను తనిఖీ చేయండి',
        'prompt_diet': 'ఆహార సూచనలు',
        'prompt_side_effects': 'ఔషధ పార్శ్వ ప్రభావాలు',
        'tap_to_speak': 'మైక్రోఫోన్‌ను నొక్కి మాట్లాడటం ప్రారంభించండి...',
        'listening': 'వింటున్నాను...',
        'release_to_send': 'పంపడానికి వదలండి',
        'hold_to_speak': 'మాట్లాడటానికి పట్టుకోండి',
        'error': 'ప్రతిస్పందన పొందడంలో లోపం. దయచేసి మళ్ళీ ప్రయత్నించండి.',
        'perm_denied': 'మైక్రోఫోన్ లేదా స్పీచ్ అనుమతి నిరాకరించబడింది. దయచేసి వాటిని సెట్టింగ్‌లలో ప్రారంభించండి.',
        'you': 'మీరు',
        'assistant': 'సహాయకుడు',
      },
    };
    return translations[widget.language]?[key] ?? translations['en']![key]!;
  }

  @override
  void initState() {
    super.initState();
    _recognizedText = _getText('tap_to_speak');
    _initVoice();
  }

  @override
  void didUpdateWidget(covariant VoiceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      setState(() {
        if (!_isListening && _assistantResponse.isEmpty) {
          _recognizedText = _getText('tap_to_speak');
        }
      });
    }
  }

  Future<void> _initVoice() async {
    await _voiceService.initSpeech();
  }

  Future<void> _handleMicDown() async {
    bool ready = await _voiceService.initSpeech();
    if (!ready) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_getText('perm_denied'))),
        );
      }
      return;
    }

    setState(() {
      _isListening = true;
      _recognizedText = _getText('listening');
      _assistantResponse = "";
    });

    await _voiceService.startListening((text) {
      setState(() {
        _recognizedText = text;
      });
    }, language: widget.language);
  }

  Future<void> _handleMicUp() async {
    await _voiceService.stopListening();
    setState(() {
      _isListening = false;
    });

    if (_recognizedText.isNotEmpty && _recognizedText != _getText('listening')) {
      _processQuery(_recognizedText);
    } else {
      setState(() {
        _recognizedText = _getText('tap_to_speak');
      });
    }
  }

  Future<void> _processQuery(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      String response = await ApiService.queryAssistant(
        query,
        lang: widget.language,
        userId: user?.id,
      );
      setState(() {
        _assistantResponse = response;
        _isSpeaking = true;
        _isLoading = false;
      });
      await _voiceService.speakText(response, language: widget.language);
      if (!mounted) return;
      setState(() {
        _isSpeaking = false;
      });
    } catch (e) {
      setState(() {
        _assistantResponse = _getText('error');
        _isLoading = false;
      });
      debugPrint("Query Error: $e");
    }
  }

  Future<void> _stopSpeaking() async {
    await _voiceService.stopSpeaking();
    setState(() {
      _isSpeaking = false;
    });
  }

  @override
  void deactivate() {
    _voiceService.stopSpeaking();
    _voiceService.stopListening();
    super.deactivate();
  }

  @override
  void dispose() {
    _voiceService.stopSpeaking();
    _voiceService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF1CC8B5) : const Color(0xFF0F9D8A);

    final suggestedPrompts = [
      _getText('prompt_rx'),
      _getText('prompt_report'),
      _getText('prompt_symptoms'),
      _getText('prompt_diet'),
      _getText('prompt_side_effects'),
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: Text(_getText('title')),
        backgroundColor: primaryColor,
        foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        actions: [
          if (_isSpeaking)
            IconButton(
              icon: const Icon(Icons.stop_circle_rounded, color: Colors.amberAccent),
              onPressed: _stopSpeaking,
              tooltip: "Stop speaking",
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Banner Card: "Ask MedIntel"
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _getText('ask_title'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getText('ask_sub'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: suggestedPrompts.map((prompt) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            avatar: Icon(Icons.record_voice_over_rounded, size: 14, color: primaryColor),
                            label: Text(
                              prompt,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                              ),
                            ),
                            backgroundColor: primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                            side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onPressed: () {
                              setState(() {
                                _recognizedText = prompt;
                              });
                              _processQuery(prompt);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Speech & Conversation Area
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildChatBubble(_recognizedText, isUser: true, isDark: isDark, primaryColor: primaryColor),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(color: primaryColor),
                      ),
                    ),
                  if (_assistantResponse.isNotEmpty)
                    _buildChatBubble(_assistantResponse, isUser: false, isDark: isDark, primaryColor: primaryColor),
                ],
              ),
            ),

            // Animated Microphone Controls
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 12.0),
              child: Column(
                children: [
                  GestureDetector(
                    onLongPressStart: (_) => _handleMicDown(),
                    onLongPressEnd: (_) => _handleMicUp(),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(_getText('hold_to_speak')),
                        duration: const Duration(seconds: 1),
                      ));
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: _isListening ? 110 : 90,
                      width: _isListening ? 110 : 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening ? const Color(0xFFEF4444) : primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: _isListening
                                ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                                : primaryColor.withValues(alpha: 0.35),
                            blurRadius: _isListening ? 30 : 16,
                            spreadRadius: _isListening ? 8 : 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        size: _isListening ? 46 : 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _isListening ? _getText('release_to_send') : _getText('hold_to_speak'),
                    style: TextStyle(
                      color: _isListening
                          ? const Color(0xFFEF4444)
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(String text, {required bool isUser, required bool isDark, required Color primaryColor}) {
    final bubbleBg = isUser
        ? primaryColor.withValues(alpha: isDark ? 0.2 : 0.1)
        : (isDark ? const Color(0xFF1E293B) : Colors.white);
    final borderColor = isUser
        ? primaryColor.withValues(alpha: 0.3)
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isUser ? 40 : 0,
          right: isUser ? 0 : 40,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bubbleBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
          ),
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.03),
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
                  size: 16,
                  color: isUser ? primaryColor : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)),
                ),
                const SizedBox(width: 6),
                Text(
                  isUser ? _getText('you') : _getText('assistant'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isUser ? primaryColor : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: textColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
