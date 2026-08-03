import 'package:flutter/material.dart';
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
      String response = await ApiService.queryAssistant(query, lang: widget.language);
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_getText('title')),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSpeaking)
            IconButton(
              icon: const Icon(Icons.stop_circle, color: Colors.orangeAccent),
              onPressed: _stopSpeaking,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildChatBubble(_recognizedText, isUser: true),
                      const SizedBox(height: 20),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(color: Colors.blue),
                        ),
                      if (_assistantResponse.isNotEmpty)
                        _buildChatBubble(_assistantResponse, isUser: false),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onLongPressStart: (_) => _handleMicDown(),
                onLongPressEnd: (_) => _handleMicUp(),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(_getText('hold_to_speak')),
                    duration: const Duration(seconds: 1),
                  ));
                },
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening ? Colors.redAccent : Colors.blue,
                    boxShadow: [
                      BoxShadow(
                        color: _isListening
                            ? Colors.red.withValues(alpha: 0.4)
                            : Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isListening ? _getText('release_to_send') : _getText('hold_to_speak'),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(String text, {required bool isUser}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isUser ? 50 : 0,
          right: isUser ? 0 : 50,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
          border: Border.all(
            color: isUser ? Colors.blue.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
          ),
          boxShadow: isUser ? null : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
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
                  isUser ? Icons.person : Icons.assistant,
                  size: 16,
                  color: isUser ? Colors.blue : Colors.teal,
                ),
                const SizedBox(width: 8),
                Text(
                  isUser ? _getText('you') : _getText('assistant'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isUser ? Colors.blue : Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
