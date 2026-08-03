import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _speechEnabled = false;

  // Request Microphone Permission
  Future<bool> requestPermission() async {
    var status = await Permission.speech.status;
    if (!status.isGranted) {
      status = await Permission.speech.request();
    }
    
    if (status.isGranted) {
      var micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        micStatus = await Permission.microphone.request();
      }
      return micStatus.isGranted;
    }
    
    return status.isGranted;
  }

  // Initialize Speech-to-Text
  Future<bool> initSpeech() async {
    bool hasPermission = await requestPermission();
    if (!hasPermission) {
      debugPrint('Speech/Mic permissions not granted');
    }

    _speechEnabled = await _speechToText.initialize(
      onError: (error) => debugPrint('STT Error: $error'),
      onStatus: (status) => debugPrint('STT Status: $status'),
    );
    return _speechEnabled && hasPermission;
  }

  // Start Listening with language support
  Future<void> startListening(Function(String) onResult, {String language = "en"}) async {
    if (!_speechEnabled) return;

    String localeId = _getLocaleId(language);
    
    await _speechToText.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      localeId: localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
    );
  }

  // Stop Listening
  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  // Text-to-Speech
  Future<void> speakText(String text, {String language = "en"}) async {
    String ttsLang = _getTtsLang(language);
    await _flutterTts.setLanguage(ttsLang);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  // Stop TTS
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  // Helper to map UI language to STT locale
  String _getLocaleId(String language) {
    switch (language) {
      case 'hi': return 'hi_IN';
      case 'ta': return 'ta_IN';
      case 'te': return 'te_IN';
      case 'ml': return 'ml_IN';
      case 'kn': return 'kn_IN';
      default: return 'en_US';
    }
  }

  // Helper to map UI language to TTS locale
  String _getTtsLang(String language) {
    switch (language) {
      case 'hi': return 'hi-IN';
      case 'kn': return 'kn-IN';
      case 'ta': return 'ta-IN';
      case 'ml': return 'ml-IN';
      case 'te': return 'te-IN';
      default: return 'en-US';
    }
  }

  bool get isListening => _speechToText.isListening;
}
