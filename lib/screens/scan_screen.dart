import 'package:flutter/material.dart';
import 'prescription_screen.dart';
import 'report_screen.dart';

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
        'rx_sub': 'Extract medication names & dosage times automatically',
        'upload_report': 'Upload Medical Report',
        'report_sub': 'AI analysis of lab test results & medical reports',
        'skin_analysis': 'Skin Condition Analysis',
        'skin_sub': 'Scan rashes, spots or skin conditions instantly',
      },
      'hi': {
        'title': 'स्कैन और विश्लेषण',
        'question': 'आप क्या विश्लेषण करना चाहेंगे?',
        'subtitle': 'AI विश्लेषण के लिए तस्वीर अपलोड करें।',
        'scan_prescription': 'नुस्खा स्कैन करें',
        'rx_sub': 'दवा के नाम और खुराक का समय स्वचालित रूप से निकालें',
        'upload_report': 'मेडिकल रिपोर्ट अपलोड करें',
        'report_sub': 'लैब परीक्षण परिणामों और मेडिकल रिपोर्ट का AI विश्लेषण',
        'skin_analysis': 'त्वचा की स्थिति का विश्लेषण',
        'skin_sub': 'चकत्ते, धब्बे या त्वचा की स्थिति तुरंत स्कैन करें',
      },
      'kn': {
        'title': 'ಸ್ಕ್ಯಾನ್ ಮತ್ತು ವಿಶ್ಲೇಷಣೆ',
        'question': 'ನೀವು ಏನನ್ನು ವಿಶ್ಲೇಷಿಸಲು ಬಯಸುತ್ತೀರಿ?',
        'subtitle': 'ತತ್ಕ್ಷಣ AI ವಿಶ್ಲೇಷಣೆಗಾಗಿ ಚಿತ್ರವನ್ನು ಅಪ್‌ಲೋಡ್ ಮಾಡಿ.',
        'scan_prescription': 'ಪ್ರಿಸ್ಕ್ರಿಪ್ಷನ್ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ',
        'rx_sub': 'ಔಷಧಿಯ ಹೆಸರುಗಳು ಮತ್ತು ಡೋಸೇಜ್ ಸಮಯವನ್ನು ಸ್ವಯಂಚಾಲಿತವಾಗಿ ಪಡೆದುಕೊಳ್ಳಿ',
        'upload_report': 'ವೈದ್ಯಕೀಯ ವರದಿ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ',
        'report_sub': 'ಲ್ಯಾಬ್ ಪರೀಕ್ಷಾ ಫಲಿತಾಂಶಗಳು ಮತ್ತು ವೈದ್ಯಕೀಯ ವರದಿಗಳ AI ವಿಶ್ಲೇಷಣೆ',
        'skin_analysis': 'ಚರ್ಮದ ವಿಶ್ಲೇಷಣೆ',
        'skin_sub': 'ದಾದ್ದುಗಳು, ಕಲೆಗಳು ಅಥವಾ ಚರ್ಮದ ಪರಿಸ್ಥಿತಿಗಳನ್ನು ತಕ್ಷಣ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ',
      },
      'ta': {
        'title': 'ஸ்கேன் மற்றும் பகுப்பாய்வு',
        'question': 'நீங்கள் எதை பகுப்பாய்வு செய்ய விரும்புகிறீர்கள்?',
        'subtitle': 'AI பகுப்பாய்விற்கு படத்தைப் பதிவேற்றவும்.',
        'scan_prescription': 'மருந்துச் சீட்டை ஸ்கேன் செய்க',
        'rx_sub': 'மருந்து பெயர்கள் மற்றும் நேரங்களை தானாகவே பிரித்தெடுக்கவும்',
        'upload_report': 'மருத்துவ அறிக்கையைப் பதிவேற்றவும்',
        'report_sub': 'ஆய்வக சோதனை முடிவுகள் மற்றும் மருத்துவ அறிக்கைகளின் AI பகுப்பாய்வு',
        'skin_analysis': 'தோல் பகுப்பாய்வு',
        'skin_sub': 'தடிப்புகள், புள்ளிகள் அல்லது தோல் நிலைகளை உடனடியாக ஸ்கேன் செய்யவும்',
      },
      'ml': {
        'title': 'സ്കാൻ & വിശകലനം',
        'question': 'നിങ്ങൾക്ക് എന്താണ് വിശകലനം ചെയ്യേണ്ടത്?',
        'subtitle': 'AI വിശകലനത്തിനായി ചിത്രം അപ്‌ലോഡ് ചെയ്യുക.',
        'scan_prescription': 'കുറിപ്പടി സ്കാൻ ചെയ്യുക',
        'rx_sub': 'മരുന്നുകളുടെ പേരുകളും സമയവും സ്വയമേവ വേർതിരിച്ചെടുക്കുക',
        'upload_report': 'മെഡിക്കൽ റിപ്പോർട്ട് അപ്‌ലോഡ് ചെയ്യുക',
        'report_sub': 'ലാബ് പരിശോധനാ ഫലങ്ങളുടെയും മെഡിക്കൽ റിപ്പോർട്ടുകളുടെയും AI വിശകലനം',
        'skin_analysis': 'ചർമ്മ വിശകലനം',
        'skin_sub': 'പാടുകൾ അല്ലെങ്കിൽ ചർമ്മ അവസ്ഥകൾ ഉടനടി സ്കാൻ ചെയ്യുക',
      },
      'te': {
        'title': 'స్కాన్ & విశ్లేషణ',
        'question': 'మీరు దేనిని విశ్లేషించాలనుకుంటున్నారు?',
        'subtitle': 'AI విశ్లేషణ కోసం చిత్రాన్ని అప్‌లోడ్ చేయండి.',
        'scan_prescription': 'ప్రిస్క్రిప్షన్ స్కాన్ చేయండి',
        'rx_sub': 'మందుల పేర్లు మరియు మోతాదు సమయాలను స్వయంచాలకంగా తీయండి',
        'upload_report': 'వైద్య నివేదికను అప్‌లోడ్ చేయండి',
        'report_sub': 'ల్యాబ్ పరీక్ష ఫలితాలు మరియు వైద్య నివేదికల AI విశ్లేషణ',
        'skin_analysis': 'చర్మ విశ్లేషణ',
        'skin_sub': 'దద్దుర్లు, మచ్చలు లేదా చర్మ పరిస్థితులను తక్షణం స్కాన్ చేయండి',
      },
    };
    return translations[language]?[key] ?? translations['en']![key]!;
  }

  Widget _buildScanCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
    required bool isDark,
  }) {
    final primaryColor = isDark ? const Color(0xFF1CC8B5) : const Color(0xFF0F9D8A);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.18 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 30, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded, color: primaryColor, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF1CC8B5) : const Color(0xFF0F9D8A);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: Text(_getText('title')),
        backgroundColor: primaryColor,
        foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
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
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _getText('subtitle'),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              _buildScanCard(
                context: context,
                title: _getText('scan_prescription'),
                subtitle: _getText('rx_sub'),
                icon: Icons.receipt_long_rounded,
                color: isDark ? const Color(0xFF1CC8B5) : const Color(0xFF0F9D8A),
                destination: PrescriptionScreen(language: language),
                isDark: isDark,
              ),
              _buildScanCard(
                context: context,
                title: _getText('upload_report'),
                subtitle: _getText('report_sub'),
                icon: Icons.description_rounded,
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                destination: ReportScreen(language: language),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
