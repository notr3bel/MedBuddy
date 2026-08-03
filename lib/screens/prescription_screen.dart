import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/export_service.dart';

class PrescriptionScreen extends StatefulWidget {
  static const String routeName = '/prescriptions';
  final String language;

  const PrescriptionScreen({super.key, this.language = "en"});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  bool isAnalyzing = false;
  File? selectedPrescription;
  String? explanation;
  String? extractedText;

  List<dynamic> detectedMedicines = [];
  List<dynamic> schedule = [];

  final ImagePicker _picker = ImagePicker();

  String _getText(String key) {
    final translations = {
      'en': {
        'title': 'Prescriptions',
        'upload': 'Upload Prescription',
        'upload_sub': 'Select an image of your prescription',
        'gallery': 'Gallery',
        'camera': 'Camera',
        'analyze': 'Analyze Prescription',
        'analyzing': 'AI is reading your prescription...',
        'results': 'Analysis Results',
        'reminders': 'Reminders',
        'share': 'Share',
        'save': 'Save',
        'set_reminders': 'Set Reminders',
        'reminder_query': 'Would you like to set medication reminders based on this prescription?',
        'yes': 'Yes',
        'no': 'No',
        'success': 'Reminders successfully scheduled!',
        'error_analyze': 'Error analyzing prescription',
        'error_db': 'Database Error',
        'notif_morning_title': 'Morning Medication',
        'notif_afternoon_title': 'Afternoon Medication',
        'notif_night_title': 'Night Medication',
        'notif_general_title': 'Medication Reminder',
        'notif_morning_body': 'Time to take your morning medication.',
        'notif_afternoon_body': 'Time to take your afternoon medication.',
        'notif_night_body': 'Time to take your night medication.',
        'notif_general_body': 'It is time to take your prescribed medication.',
      },
      'hi': {
        'title': 'नुस्खे',
        'upload': 'नुस्खा अपलोड करें',
        'upload_sub': 'अपने नुस्खे की एक छवि चुनें',
        'gallery': 'गैलरी',
        'camera': 'कैमरा',
        'analyze': 'नुस्खे का विश्लेषण करें',
        'analyzing': 'AI आपका नुस्खा पढ़ रहा है...',
        'results': 'विश्लेषण परिणाम',
        'reminders': 'अनुस्मारक',
        'share': 'शेयर करें',
        'save': 'सहेजें',
        'set_reminders': 'अनुस्मारक सेट करें',
        'reminder_query': 'क्या आप इस नुस्खे के आधार पर दवा अनुस्मारक सेट करना चाहेंगे?',
        'yes': 'हाँ',
        'no': 'नहीं',
        'success': 'अनुस्मारक सफलतापूर्वक निर्धारित किए गए!',
        'error_analyze': 'नुस्खे के विश्लेषण में त्रुटि',
        'error_db': 'डेटाबेस त्रुटि',
        'notif_morning_title': 'सुबह की दवा',
        'notif_afternoon_title': 'दोपहर की दवा',
        'notif_night_title': 'रात की दवा',
        'notif_general_title': 'दवा अनुस्मारक',
        'notif_morning_body': 'आपकी सुबह की दवा लेने का समय हो गया है।',
        'notif_afternoon_body': 'आपकी दोपहर की दवा लेने का समय हो गया है।',
        'notif_night_body': 'आपकी रात की दवा लेने का समय हो गया है।',
        'notif_general_body': 'आपकी निर्धारित दवा लेने का समय आ गया है।',
      },
      'kn': {
        'title': 'ಪ್ರಿಸ್ಕ್ರಿಪ್ಷನ್‌ಗಳು',
        'upload': 'ಪ್ರಿಸ್ಕ್ರಿಪ್ಷನ್ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ',
        'upload_sub': 'ನಿಮ್ಮ ಪ್ರಿಸ್ಕ್ರಿಪ್ಷನ್‌ನ ಚಿತ್ರವನ್ನು ಆಯ್ಕೆಮಾಡಿ',
        'gallery': 'ಗ್ಯಾಲರಿ',
        'camera': 'ಕ್ಯಾಮರಾ',
        'analyze': 'ಪ್ರಿಸ್ಕ್ರಿಪ್ಷನ್ ವಿಶ್ಲೇಷಿಸಿ',
        'analyzing': 'AI ನಿಮ್ಮ ಪ್ರಿಸ್ಕ್ರಿಪ್ಷನ್ ಅನ್ನು ಓದುತ್ತಿದೆ...',
        'results': 'ವಿಶ್ಲೇಷಣೆ ಫಲಿತಾಂಶಗಳು',
        'reminders': 'ಜ್ಞಾಪನೆಗಳು',
        'share': 'ಹಂಚಿಕೊಳ್ಳಿ',
        'save': 'ಉಳಿಸಿ',
        'set_reminders': 'ಜ್ಞಾಪನೆಗಳನ್ನು ಹೊಂದಿಸಿ',
        'reminder_query': 'ಈ ಪ್ರಿಸ್ಕ್ರಿಪ್ಷನ್ ಆಧಾರದ ಮೇಲೆ ನೀವು ಔಷಧಿ ಜ್ಞಾಪನೆಗಳನ್ನು ಹೊಂದಿಸಲು ಬಯಸುವಿರಾ?',
        'yes': 'ಹೌದು',
        'no': 'ಇಲ್ಲ',
        'success': 'ಜ್ಞಾಪನೆಗಳನ್ನು ಯಶಸ್ವಿಯಾಗಿ ನಿಗದಿಪಡಿಸಲಾಗಿದೆ!',
        'error_analyze': 'ಪ್ರಿಸ್ಕ್ರಿಪ್ಷನ್ ವಿಶ್ಲೇಷಿಸುವಲ್ಲಿ ದೋಷ',
        'error_db': 'ಡೇಟಾಬೇಸ್ ದೋಷ',
        'notif_morning_title': 'ಬೆಳಗಿನ ಔಷಧಿ',
        'notif_afternoon_title': 'ಮಧ್ಯಾಹ್ನದ ಔಷಧಿ',
        'notif_night_title': 'ರಾತ್ರಿಯ ಔಷಧಿ',
        'notif_general_title': 'ಔಷಧಿ ಜ್ಞಾಪನೆ',
        'notif_morning_body': 'ನಿಮ್ಮ ಬೆಳಗಿನ ಔಷಧಿ ತೆಗೆದುಕೊಳ್ಳುವ ಸಮಯವಾಗಿದೆ.',
        'notif_afternoon_body': 'ನಿಮ್ಮ ಮಧ್ಯಾಹ್ನದ ಔಷಧಿ ತೆಗೆದುಕೊಳ್ಳುವ ಸಮಯವಾಗಿದೆ.',
        'notif_night_body': 'ನಿಮ್ಮ ರಾತ್ರಿಯ ಔಷಧಿ ತೆಗೆದುಕೊಳ್ಳುವ ಸಮಯವಾಗಿದೆ.',
        'notif_general_body': 'ನಿಮ್ಮ ಸೂಚಿಸಿದ ಔಷಧಿ ತೆಗೆದುಕೊಳ್ಳುವ ಸಮಯ ಸಂಭವಿಸಿದೆ.',
      },
      'ta': {
        'title': 'மருந்துச் சீட்டுகள்',
        'upload': 'மருந்துச் சீட்டைப் பதிவேற்றவும்',
        'upload_sub': 'உங்கள் மருந்துச் சீட்டின் படத்தைத் தேர்ந்தெடுக்கவும்',
        'gallery': 'கேலரி',
        'camera': 'கேமரா',
        'analyze': 'மருந்துச் சீட்டைப் பகுப்பாய்வு செய்க',
        'analyzing': 'AI உங்கள் மருந்துச் சீட்டைப் படிக்கிறது...',
        'results': 'பகுப்பாய்வு முடிவுகள்',
        'reminders': 'நினைவூட்டல்கள்',
        'share': 'பகிர்',
        'save': 'சேமி',
        'set_reminders': 'நினைவூட்டல்களை அமைக்கவும்',
        'reminder_query': 'இந்த மருந்துச் சீட்டின் அடிப்படையில் மருந்து நினைவூட்டல்களை அமைக்க விரும்புகிறீர்களா?',
        'yes': 'ஆம்',
        'no': 'இல்லை',
        'success': 'நினைவூட்டல்கள் வெற்றிகரமாக திட்டமிடப்பட்டன!',
        'error_analyze': 'மருந்துச் சீட்டைப் பகுப்பாய்வு செய்வதில் பிழை',
        'error_db': 'தரவுத்தள பிழை',
        'notif_morning_title': 'காலை மருந்து',
        'notif_afternoon_title': 'மதிய மருந்து',
        'notif_night_title': 'இரவு மருந்து',
        'notif_general_title': 'மருந்து நினைவூட்டல்',
        'notif_morning_body': 'உங்கள் காலை மருந்தை உட்கொள்ளும் நேரம் இது.',
        'notif_afternoon_body': 'உங்கள் மதிய மருந்தை உட்கொள்ளும் நேரம் இது.',
        'notif_night_body': 'உங்கள் இரவு மருந்தை உட்கொள்ளும் நேரம் இது.',
        'notif_general_body': 'உங்கள் பரிந்துரைக்கப்பட்ட மருந்தை உட்கொள்ள வேண்டிய நேரம் வந்துவிட்டது.',
      },
      'ml': {
        'title': 'കുറിപ്പടികൾ',
        'upload': 'കുറിപ്പടി അപ്‌ലോഡ് ചെയ്യുക',
        'upload_sub': 'നിങ്ങളുടെ കുറിപ്പടിയുടെ ഒരു ചിത്രം തിരഞ്ഞെടുക്കുക',
        'gallery': 'ഗാലറി',
        'camera': 'ക്യാമറ',
        'analyze': 'കുറിപ്പടി വിശകലനം ചെയ്യുക',
        'analyzing': 'AI നിങ്ങളുടെ കുറിപ്പടി വായിക്കുന്നു...',
        'results': 'വിശകലന ഫലങ്ങൾ',
        'reminders': 'ഓർമ്മപ്പെടുത്തലുകൾ',
        'share': 'പങ്കിടുക',
        'save': 'സേവ് ചെയ്യുക',
        'set_reminders': 'ഓർമ്മപ്പെടുത്തലുകൾ സജ്ಜമാക്കുക',
        'reminder_query': 'ഈ കുറിപ്പടി അടിസ്ഥാനമാക്കി മരുന്ന് ഓർമ്മപ്പെടുത്തലുകൾ സജ്ಜമാക്കാൻ നിങ്ങൾ ആഗ്രഹിക്കുന്നുണ്ടോ?',
        'yes': 'അതെ',
        'no': 'ഇല്ല',
        'success': 'ഓർമ്മപ്പെടുത്തലുകൾ വിജയകരമായി ഷെഡ്യൂൾ ചെയ്തു!',
        'error_analyze': 'കുറിപ്പടി വിശകലനം ചെയ്യുന്നതിൽ പിശക്',
        'error_db': 'ഡാറ്റാബേസ് പിശക്',
        'notif_morning_title': 'രാവിലത്തെ മരുന്ന്',
        'notif_afternoon_title': 'ഉച്ചയ്ക്കത്തെ മരുന്ന്',
        'notif_night_title': 'രാത്രിയിലെ മരുന്ന്',
        'notif_general_title': 'മരുന്ന് ഓർമ്മപ്പെടുത്തൽ',
        'notif_morning_body': 'നിങ്ങളുടെ പ്രഭാത മരുന്ന് കഴിക്കാനുള്ള സമയമായി.',
        'notif_afternoon_body': 'നിങ്ങളുടെ ഉച്ചഭക്ഷണ മരുന്ന് കഴിക്കാനുള്ള സമയമായി.',
        'notif_night_body': 'നിങ്ങളുടെ രാത്രികാല മരുന്ന് കഴിക്കാനുള്ള സമയമായി.',
        'notif_general_body': 'നിങ്ങൾ നിർദ്ദേശിച്ച മരുന്ന് കഴിക്കാനുള്ള സമയമായി.',
      },
      'te': {
        'title': 'ప్రిస్క్రిప్షన్లు',
        'upload': 'ప్రిస్క్రిప్షన్ అప్‌లోడ్ చేయండి',
        'upload_sub': 'మీ ప్రిస్క్రిప్షన్ చిత్రాన్ని ఎంచుకోండి',
        'gallery': 'గ్యాలరీ',
        'camera': 'కెమెరా',
        'analyze': 'ప్రిస్క్రిప్షన్ విశ్లేషించండి',
        'analyzing': 'AI మీ ప్రిస్క్రిప్షన్ చదువుతోంది...',
        'results': 'విశ్లేషణ ఫలితాలు',
        'reminders': 'రిమైండర్లు',
        'share': 'షేర్ చేయండి',
        'save': 'సేవ్ చేయండి',
        'set_reminders': 'రిమైండర్లు సెట్ చేయండి',
        'reminder_query': 'మీరు ఈ ప్రిస్క్రిప్షన్ ఆధారంగా మందుల రిమైండర్‌లను సెట్ చేయాలనుకుంటున్నారా?',
        'yes': 'అవును',
        'no': 'వద్దు',
        'success': 'రిమైండర్లు విజయవంతంగా షెడ్యూల్ చేయబడ్డాయి!',
        'error_analyze': 'ప్రిస్క్రిప్షన్ విశ్లేషించడంలో లోపం',
        'error_db': 'డేటాబేస్ లోపం',
        'notif_morning_title': 'ఉదయం మందులు',
        'notif_afternoon_title': 'మధ్యాహ్నం మందులు',
        'notif_night_title': 'రాత్రి మందులు',
        'notif_general_title': 'మందుల రిమైండర్',
        'notif_morning_body': 'మీ ఉదయం మందులు తీసుకునే సమయం ఆసన్నమైంది.',
        'notif_afternoon_body': 'మీ మధ్యాహ్నం మందులు తీసుకునే సమయం ఆసన్నమైంది.',
        'notif_night_body': 'మీ రాత్రి మందులు తీసుకునే సమయం ఆసన్నమైంది.',
        'notif_general_body': 'మీరు సూచించిన మందులు తీసుకునే సమయం జరిగింది.',
      },
    };
    return translations[widget.language]?[key] ?? translations['en']![key]!;
  }

  DateTime getReminderTime(String time) {
    final now = DateTime.now();
    if (time == "morning") {
      return DateTime(now.year, now.month, now.day, 8, 0);
    }
    if (time == "afternoon") {
      return DateTime(now.year, now.month, now.day, 13, 0);
    }
    if (time == "night") {
      return DateTime(now.year, now.month, now.day, 21, 0);
    }
    return now;
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedPrescription = File(pickedFile.path);
        explanation = null;
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        selectedPrescription = File(pickedFile.path);
        explanation = null;
      });
    }
  }

  Future<void> _analyzePrescription() async {
    if (selectedPrescription == null) return;

    setState(() {
      isAnalyzing = true;
      explanation = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final result = await ApiService.analyzePrescription(
        selectedPrescription!,
        lang: widget.language,
        userId: user?.id,
      );

      setState(() {
        explanation = result["explanation"];
        extractedText = result["extracted_text"];
        detectedMedicines = result["detected_medicines"] ?? [];
        schedule = result["schedule"] ?? [];
      });
      if (mounted) {
        _promptForReminders();
      }
    } catch (e) {
      setState(() {
        explanation = "${_getText('error_analyze')}: $e";
      });
    } finally {
      setState(() {
        isAnalyzing = false;
      });
    }
  }

  void _promptForReminders() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_getText('set_reminders')),
          content: Text(_getText('reminder_query')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_getText('no')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _scheduleReminders();
              },
              child: Text(_getText('yes')),
            ),
          ],
        );
      },
    );
  }

  void _scheduleReminders() async {
    final text = explanation?.toLowerCase() ?? '';
    bool scheduled = false;
    int idCounter = DateTime.now().millisecondsSinceEpoch % 100000;
    final user = Supabase.instance.client.auth.currentUser;

    // Improved diagnostic: Find medicine names
    List<String> medsToSave = [];
    
    // 1. Try to find headers starting with ### (which we just updated the backend to provide)
    final RegExp nameRegex = RegExp(r'^###\s+(.*)$', multiLine: true);
    final Iterable<RegExpMatch> matches = nameRegex.allMatches(explanation ?? '');
    
    if (matches.isNotEmpty) {
      for (final match in matches) {
        final name = match.group(1)?.trim();
        if (name != null && name.isNotEmpty) medsToSave.add(name);
      }
    } 
    
    // 2. Fallback: If no ### found, try to find lines that look like titles 
    // (Non-empty lines that don't contains 'Description:', 'Instructions:', etc.)
    if (medsToSave.isEmpty) {
      final lines = (explanation ?? '').split('\n');
      for (var line in lines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty && 
            !trimmed.startsWith('Description:') && 
            !trimmed.startsWith('Reason:') && 
            !trimmed.startsWith('Instructions:') &&
            !trimmed.startsWith('---') &&
            trimmed.length < 40) {
          medsToSave.add(trimmed);
        }
      }
    }

    if (text.contains('morning')) {
      await NotificationService().scheduleMedicationReminder(
        id: idCounter++,
        title: _getText('notif_morning_title'),
        body: _getText('notif_morning_body'),
        scheduledTime: getReminderTime("morning"),
      );
      scheduled = true;
    }
    if (text.contains('afternoon')) {
      await NotificationService().scheduleMedicationReminder(
        id: idCounter++,
        title: _getText('notif_afternoon_title'),
        body: _getText('notif_afternoon_body'),
        scheduledTime: getReminderTime("afternoon"),
      );
      scheduled = true;
    }
    if (text.contains('night') || text.contains('evening')) {
      await NotificationService().scheduleMedicationReminder(
        id: idCounter++,
        title: _getText('notif_night_title'),
        body: _getText('notif_night_body'),
        scheduledTime: getReminderTime("night"),
      );
      scheduled = true;
    }

    if (!scheduled && medsToSave.isEmpty) {
      await NotificationService().scheduleMedicationReminder(
        id: idCounter++,
        title: _getText('notif_general_title'),
        body: _getText('notif_general_body'),
        scheduledTime: DateTime.now().add(const Duration(hours: 1)),
      );
      medsToSave.add("New Medication");
    }

    // Save to Supabase so it shows up in the Dashboard
    if (user != null && medsToSave.isNotEmpty) {
      try {
        for (var medName in medsToSave) {
          await Supabase.instance.client.from('user_medications').upsert({
            'user_id': user.id,
            'name': medName,
            'last_updated': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id, name');
        }
      } catch (e) {
        debugPrint("Error saving meds to DB: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getText('error_db')}: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getText('success'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_getText('title'), 
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUploadCard(),
            const SizedBox(height: 25),
            if (isAnalyzing) _buildLoadingState(),
            if (explanation != null && !isAnalyzing) _buildResultsCard(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (selectedPrescription != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                   Image.file(
                    selectedPrescription!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        selectedPrescription = null;
                        explanation = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.1), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 50, color: Colors.teal.shade300),
                  const SizedBox(height: 12),
                  Text(_getText('upload'), 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
                  const SizedBox(height: 4),
                  Text(_getText('upload_sub'), 
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  onPressed: _pickImage,
                  icon: Icons.photo_library_outlined,
                  label: _getText('gallery'),
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  onPressed: _takePhoto,
                  icon: Icons.camera_alt_outlined,
                  label: _getText('camera'),
                  isPrimary: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            onPressed: isAnalyzing || selectedPrescription == null ? null : _analyzePrescription,
            icon: Icons.auto_awesome,
            label: _getText('analyze'),
            isPrimary: true,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    bool fullWidth = false,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.teal : Colors.white,
          foregroundColor: isPrimary ? Colors.white : Colors.teal,
          elevation: isPrimary ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: isPrimary ? BorderSide.none : BorderSide(color: Colors.teal.shade100),
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const CircularProgressIndicator(color: Colors.teal),
          const SizedBox(height: 16),
          Text(_getText('analyzing'), 
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildResultsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medication_outlined, color: Colors.teal, size: 20),
              ),
              const SizedBox(width: 12),
              Text(_getText('results'), 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          MarkdownBody(
            data: explanation!,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.grey.shade800,
              ),
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
              horizontalRuleDecoration: BoxDecoration(
                border: Border(
                  top: BorderSide(width: 1.0, color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          if (schedule.isNotEmpty)
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 20),

                const Text(
                  "Medication Schedule",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

              ...schedule.map((med) {
                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.medication,
                      color: Colors.teal,
                    ),
                    title: Text(med["medicine"] ?? ""),
                    subtitle: Text("${med["dosage"]} • ${med["duration"]}\n${med["timing"]}"),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
          const SizedBox(height: 25),
          const Divider(),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildResultAction(
                icon: Icons.alarm_add_outlined,
                label: _getText('reminders'),
                onTap: _promptForReminders,
              ),
              _buildResultAction(
                icon: Icons.share_outlined,
                label: _getText('share'),
                onTap: () => ExportService.shareText(
                  explanation!,
                  subject: _getText('title'),
                ),
              ),
              _buildResultAction(
                icon: Icons.bookmark_border_outlined,
                label: _getText('save'),
                onTap: () => ExportService.generateAndPrintPdf(
                  title: _getText('title'),
                  content: explanation!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.teal, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
