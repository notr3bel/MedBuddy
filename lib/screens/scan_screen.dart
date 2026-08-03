import 'package:flutter/material.dart';
import 'prescription_screen.dart';
import 'report_screen.dart';
import 'skin_screen.dart';

class ScanScreen extends StatelessWidget {
  final String language;

  const ScanScreen({super.key, this.language = "en"});

  String _getText(String key) {
    final translations = {
      'en': {
        'title': 'Scan & Analyze',
        'question': 'What would you like to analyze?',
        'subtitle': 'Upload an image securely for instant AI analysis.',
        'scan_prescription': 'Scan Prescription',
        'upload_report': 'Upload Medical Report',
        'skin_analysis': 'Skin Condition Analysis',
      },
      'hi': {
        'title': 'स्कैन और विश्लेषण',
        'question': 'आप क्या विश्लेषण करना चाहेंगे?',
        'subtitle': 'AI विश्लेषण के लिए तस्वीर अपलोड करें।',
        'scan_prescription': 'नुस्खा स्कैन करें',
        'upload_report': 'मेडिकल रिपोर्ट अपलोड करें',
        'skin_analysis': 'त्वचा की स्थिति का विश्लेषण',
      },
      'kn': {
        'title': 'ಸ್ಕ್ಯಾನ್ ಮತ್ತು ವಿಶ್ಲೇಷಣೆ',
        'question': 'ನೀವು ಏನನ್ನು ವಿಶ್ಲೇಷಿಸಲು ಬಯಸುತ್ತೀರಿ?',
        'subtitle': 'ತತ್ಕ್ಷಣ AI ವಿಶ್ಲೇಷಣೆಗಾಗಿ ಚಿತ್ರವನ್ನು ಅಪ್‌ಲೋಡ್ ಮಾಡಿ.',
        'scan_prescription': 'ಪ್ರಿಸ್ಕ್ರಿಪ್ಷನ್ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ',
        'upload_report': 'ವೈದ್ಯಕೀಯ ವರದಿ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ',
        'skin_analysis': 'ಚರ್ಮದ ವಿಶ್ಲೇಷಣೆ',
      },
      'ta': {
        'title': 'ஸ்கேன் மற்றும் பகுப்பாய்வு',
        'question': 'நீங்கள் எதை பகுப்பாய்வு செய்ய விரும்புகிறீர்கள்?',
        'subtitle': 'AI பகுப்பாய்விற்கு படத்தைப் பதிவேற்றவும்.',
        'scan_prescription': 'மருந்துச் சீட்டை ஸ்கேன் செய்க',
        'upload_report': 'மருத்துவ அறிக்கையைப் பதிவேற்றவும்',
        'skin_analysis': 'தோல் பகுப்பாய்வு',
      },
      'ml': {
        'title': 'സ്കാൻ & വിശകലനം',
        'question': 'നിങ്ങൾക്ക് എന്താണ് വിശകലനം ചെയ്യേണ്ടത്?',
        'subtitle': 'AI വിശകലനത്തിനായി ചിത്രം അപ്‌ലോഡ് ചെയ്യുക.',
        'scan_prescription': 'കുറിപ്പടി സ്കാൻ ചെയ്യുക',
        'upload_report': 'മെഡിക്കൽ റിപ്പോർട്ട് അപ്‌ലോഡ് ചെയ്യുക',
        'skin_analysis': 'ചർമ്മ വിശകലനം',
      },
      'te': {
        'title': 'స్కాన్ & విశ్లేషణ',
        'question': 'మీరు దేనిని విశ్లేషించాలనుకుంటున్నారు?',
        'subtitle': 'AI విశ్లేషణ కోసం చిత్రాన్ని అప్‌లోడ్ చేయండి.',
        'scan_prescription': 'ప్రిస్క్రిప్షన్ స్కాన్ చేయండి',
        'upload_report': 'వైద్య నివేదికను అప్‌లోడ్ చేయండి',
        'skin_analysis': 'చర్మ విశ్లేషణ',
      },
    };
    return translations[language]?[key] ?? translations['en']![key]!;
  }

  Widget _buildScanCard(BuildContext context, String title, IconData icon, Widget destination) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: Colors.blue),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getText('question'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _getText('subtitle'),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              _buildScanCard(
                context,
                _getText('scan_prescription'),
                Icons.receipt_long,
                PrescriptionScreen(language: language),
              ),
              _buildScanCard(
                context,
                _getText('upload_report'),
                Icons.description,
                ReportScreen(language: language),
              ),
              _buildScanCard(
                context,
                _getText('skin_analysis'),
                Icons.face,
                SkinScreen(language: language),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
