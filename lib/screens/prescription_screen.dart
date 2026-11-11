import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/export_service.dart';
import '../services/date_formatter.dart';

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

  @override
  void didUpdateWidget(covariant PrescriptionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      setState(() {});
    }
  }

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
        'set_reminders': 'ഓർമ്മപ്പെടുത്തലുകൾ സജ്ജമാക്കുക',
        'reminder_query': 'ഈ കുറിപ്പടി അടിസ്ഥാനമാക്കി മരുന്ന് ഓർമ്മപ്പെടുത്തലുകൾ സജ്ജമാക്കാൻ നിങ്ങൾ ആഗ്രഹിക്കുന്നുണ്ടോ?',
        'yes': 'അതെ',
        'no': 'ഇല്ല',
        'success': 'ഓർമ്മപ്പെടുത്തലുകൾ വിജയകരമായി ഷെഡ്യൂൾ ചെയ്തു!',
        'error_analyze': 'കുറിപ്പടി വിശകലനം ചെയ്യുന്നതിൽ പിശക്',
        'error_db': 'ഡാറ്റാബേസ് പിശക്',
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
      },
    };
    return translations[widget.language]?[key] ?? translations['en']![key]!;
  }

  DateTime parseReminderTime(String time) {
    final now = DateTime.now();
    try {
      final parts = time.trim().split(":");
      int hour = 8;
      int minute = 0;
      if (parts.isNotEmpty) {
        hour = int.parse(RegExp(r'\d+').stringMatch(parts[0]) ?? '8');
      }
      if (parts.length > 1) {
        minute = int.parse(RegExp(r'\d+').stringMatch(parts[1]) ?? '0');
        if (time.toLowerCase().contains('pm') && hour < 12) hour += 12;
        if (time.toLowerCase().contains('am') && hour == 12) hour = 0;
      }
      DateTime scheduled = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      return scheduled;
    } catch (_) {
      return now.add(const Duration(hours: 1));
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final localFile = await File(pickedFile.path).copy('${appDir.path}/${pickedFile.name}');

      setState(() {
        selectedPrescription = localFile;
        explanation = null;
        extractedText = null;
        detectedMedicines.clear();
        schedule.clear();
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final localFile = await File(pickedFile.path).copy('${appDir.path}/${pickedFile.name}');

      setState(() {
        selectedPrescription = localFile;
        explanation = null;
        extractedText = null;
        detectedMedicines.clear();
        schedule.clear();
      });
    }
  }

  int _loadingStep = 0;
  final List<String> _progressSteps = [
    "Uploading...",
    "OCR Reading...",
    "Medicine Detection...",
    "AI Understanding...",
    "Generating Schedule...",
    "Completed."
  ];

  Future<void> _analyzePrescription() async {
    if (selectedPrescription == null || isAnalyzing) return;

    setState(() {
      isAnalyzing = true;
      explanation = null;
      _loadingStep = 0;
    });

    _animateLoadingSteps();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final result = await ApiService.analyzePrescription(
        selectedPrescription!,
        lang: widget.language,
        userId: user?.id,
      );

      setState(() {
        _loadingStep = 5;
        explanation = result["explanation"];
        extractedText = result["extracted_text"];
        detectedMedicines = result["detected_medicines"] ?? [];
        schedule = result["schedule"] ?? [];
      });
      if (mounted && detectedMedicines.isNotEmpty && schedule.isNotEmpty) {
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

  void _animateLoadingSteps() async {
    for (int i = 1; i <= 4; i++) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted && isAnalyzing) {
        setState(() {
          _loadingStep = i;
        });
      }
    }
  }

  void _promptForReminders() {
    if (detectedMedicines.isEmpty || schedule.isEmpty) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF1CC8B5) : const Color(0xFF0F9D8A);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text(
            _getText('set_reminders'),
            style: TextStyle(color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
          ),
          content: Text(
            _getText('reminder_query'),
            style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_getText('no'), style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              ),
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

  DateTime _parseScheduledTime(String timeStr) {
    final now = DateTime.now();
    String clean = timeStr.trim();
    int hour = 8;
    int minute = 0;

    if (clean.toLowerCase().contains("am") || clean.toLowerCase().contains("pm")) {
      try {
        final dt = DateFormat('hh:mm a').parse(clean);
        hour = dt.hour;
        minute = dt.minute;
      } catch (_) {}
    } else {
      try {
        final parts = clean.split(":");
        if (parts.length >= 2) {
          hour = int.parse(parts[0]);
          minute = int.parse(parts[1].split(" ")[0]);
        }
      } catch (_) {}
    }

    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    return scheduledTime;
  }

  Future<void> _scheduleReminders() async {
    int idCounter = DateTime.now().millisecondsSinceEpoch % 100000;
    final user = Supabase.instance.client.auth.currentUser;
    final prefs = await SharedPreferences.getInstance();

    String mTime = prefs.getString('med_timing_morning') ?? '08:00 AM';
    String aTime = prefs.getString('med_timing_afternoon') ?? '02:00 PM';
    String dTime = prefs.getString('med_timing_dinner') ?? '08:00 PM';

    if (user != null) {
      final meta = user.userMetadata ?? {};
      if (meta['med_timing_morning'] != null) mTime = meta['med_timing_morning'].toString();
      if (meta['med_timing_afternoon'] != null) aTime = meta['med_timing_afternoon'].toString();
      if (meta['med_timing_dinner'] != null) dTime = meta['med_timing_dinner'].toString();
    }

    mTime = DateFormatter.format12HourTime(mTime);
    aTime = DateFormatter.format12HourTime(aTime);
    dTime = DateFormatter.format12HourTime(dTime);

    if (schedule.isEmpty) return;

    final now = DateTime.now();
    final todayDateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final List<Map<String, dynamic>> recordsToUpsert = [];
    final Set<String> seenKeys = {};

    for (final med in schedule) {
      final medicineName = med["medicine"] ?? "Medication";
      final dosage = (med["dosage"] ?? "").toString().trim();
      final timing = med["timing"] ?? "";

      List<String> times = [];
      if (med["reminder_times"] is List && (med["reminder_times"] as List).isNotEmpty) {
        times = (med["reminder_times"] as List).map((t) => DateFormatter.format12HourTime(t.toString())).toList();
      } else {
        if (dosage == "1-0-0") {
          times = [mTime];
        } else if (dosage == "0-1-0") {
          times = [aTime];
        } else if (dosage == "0-0-1") {
          times = [dTime];
        } else if (dosage == "1-0-1") {
          times = [mTime, dTime];
        } else if (dosage == "1-1-0") {
          times = [mTime, aTime];
        } else if (dosage == "0-1-1") {
          times = [aTime, dTime];
        } else if (dosage == "1-1-1") {
          times = [mTime, aTime, dTime];
        } else {
          times = [mTime];
        }
      }

      for (final time in times) {
        final formattedTimeStr = DateFormatter.format12HourTime(time);
        final scheduledTime = _parseScheduledTime(formattedTimeStr);

        NotificationService()
            .scheduleMedicationReminder(
              id: idCounter++,
              title: medicineName,
              body: "Time to take $medicineName ($dosage • $timing)",
              scheduledTime: scheduledTime,
            )
            .catchError((e) => debugPrint("Notification schedule warning: $e"));

        final dedupKey = "${medicineName.toLowerCase()}|$formattedTimeStr|$todayDateStr";
        if (seenKeys.add(dedupKey)) {
          recordsToUpsert.add({
            'user_id': user?.id ?? '',
            'medicine_name': medicineName,
            'dosage': dosage,
            'timing': timing,
            'reminder_time': formattedTimeStr,
            'reminder_date': todayDateStr,
            'status': 'pending',
          });
        }
      }
    }

    if (recordsToUpsert.isNotEmpty) {
      // Immediately surface reminders on the dashboard before DB round-trip finishes
      pendingRemindersNotifier.value = List<Map<String, dynamic>>.from(recordsToUpsert);

      if (user != null) {
        try {
          await Supabase.instance.client.from('medication_reminders').upsert(
            recordsToUpsert,
            onConflict: 'user_id,medicine_name,reminder_time,reminder_date',
          );
        } catch (upsertErr) {
          debugPrint("Upsert failed, falling back to safe insert: $upsertErr");
          try {
            final existing = await Supabase.instance.client
                .from('medication_reminders')
                .select('medicine_name, reminder_time')
                .eq('user_id', user.id)
                .eq('reminder_date', todayDateStr);
            final existingSet = <String>{};
            for (final row in (existing as List<dynamic>)) {
              existingSet.add("${(row['medicine_name'] ?? '').toString().toLowerCase()}|${row['reminder_time'] ?? ''}");
            }
            final toInsert = recordsToUpsert.where((r) {
              final k = "${(r['medicine_name'] ?? '').toString().toLowerCase()}|${r['reminder_time'] ?? ''}";
              return !existingSet.contains(k);
            }).toList();
            if (toInsert.isNotEmpty) {
              await Supabase.instance.client.from('medication_reminders').insert(toInsert);
            }
          } catch (insertErr) {
            debugPrint("Error inserting reminders to Supabase: $insertErr");
          }
        }
      }
    }

    // Notify DashboardScreen to refresh with persisted DB records
    dashboardRefreshNotifier.value++;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getText('success'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF1CC8B5) : const Color(0xFF0F9D8A);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: Text(
          _getText('title'),
          style: TextStyle(
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUploadCard(isDark, primaryColor),
            const SizedBox(height: 25),
            if (isAnalyzing) _buildLoadingState(isDark, primaryColor),
            if (explanation != null && !isAnalyzing) _buildResultsCard(isDark, primaryColor),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard(bool isDark, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
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
                color: primaryColor.withValues(alpha: isDark ? 0.1 : 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.15),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 50, color: primaryColor),
                  const SizedBox(height: 12),
                  Text(
                    _getText('upload'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getText('upload_sub'),
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
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
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  onPressed: _takePhoto,
                  icon: Icons.camera_alt_outlined,
                  label: _getText('camera'),
                  isPrimary: false,
                  isDark: isDark,
                  primaryColor: primaryColor,
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
            isDark: isDark,
            primaryColor: primaryColor,
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
    required bool isDark,
    required Color primaryColor,
    bool fullWidth = false,
  }) {
    final bgColor = isPrimary
        ? primaryColor
        : (isDark ? const Color(0xFF0F172A) : Colors.white);
    final fgColor = isPrimary
        ? (isDark ? const Color(0xFF0F172A) : Colors.white)
        : primaryColor;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: isPrimary ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: isDark ? const Color(0xFF334155) : primaryColor.withValues(alpha: 0.3)),
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(color: primaryColor),
          const SizedBox(height: 20),
          Text(
            _progressSteps[_loadingStep.clamp(0, 5)],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_loadingStep + 1) / 6.0,
            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            color: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(bool isDark, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
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
                  color: primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.medication_outlined, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                _getText('results'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          MarkdownBody(
            data: explanation!,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: isDark ? const Color(0xFFF8FAFC) : Colors.grey.shade800,
              ),
              h3: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
                height: 2.5,
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
              horizontalRuleDecoration: BoxDecoration(
                border: Border(
                  top: BorderSide(width: 1.0, color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                ),
              ),
            ),
          ),
          if (schedule.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  "Medication Schedule",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                ...schedule.map((med) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.medication,
                        color: primaryColor,
                      ),
                      title: Text(
                        med["medicine"] ?? "",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        ),
                      ),
                      subtitle: Text(
                        "${med["dosage"] ?? ""} • ${med["duration"] ?? ""}\n${med["timing"] ?? ""}",
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          const SizedBox(height: 25),
          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (schedule.isNotEmpty)
                _buildResultAction(
                  icon: Icons.alarm_add_outlined,
                  label: _getText('reminders'),
                  onTap: _promptForReminders,
                  primaryColor: primaryColor,
                ),
              _buildResultAction(
                icon: Icons.share_outlined,
                label: _getText('share'),
                onTap: () => ExportService.shareText(
                  explanation!,
                  subject: _getText('title'),
                ),
                primaryColor: primaryColor,
              ),
              _buildResultAction(
                icon: Icons.bookmark_border_outlined,
                label: _getText('save'),
                onTap: () => ExportService.generateAndPrintPdf(
                  title: _getText('title'),
                  content: explanation!,
                ),
                primaryColor: primaryColor,
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
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: primaryColor, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
