import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SosScreen extends StatelessWidget {
  static const String routeName = '/sos';
  final String language;

  const SosScreen({super.key, this.language = 'en'});

  Future<void> callNumber(String number) async {
    final Uri phoneUri = Uri.parse("tel:$number");
    await launchUrl(phoneUri);
  }

  Future<void> openHospitalMap() async {
    final Uri mapUri = Uri.parse("https://www.google.com/maps/search/hospitals+near+me");
    await launchUrl(mapUri, mode: LaunchMode.externalApplication);
  }

  Future<void> openPoliceMap() async {
    final Uri mapUri = Uri.parse("https://www.google.com/maps/search/police+station+near+me");
    await launchUrl(mapUri, mode: LaunchMode.externalApplication);
  }

  String _getText(String key) {
    Map<String, Map<String, String>> localizedValues = {
      'en': {
        'Ambulance': 'Call Ambulance',
        'Police': 'Call Police',
        'Fire': 'Call Fire',
        'FindHospital': 'Find Nearby Hospitals',
        'FindPolice': 'Find Nearby Police Stations',
        'title': 'SOS Emergency',
      },
      'hi': {
        'Ambulance': 'एम्बुलेंस बुलाओ',
        'Police': 'पुलिस बुलाओ',
        'Fire': 'दमकल बुलाओ',
        'FindHospital': 'आस-पास के अस्पताल खोजें',
        'FindPolice': 'आस-पास के पुलिस स्टेशन खोजें',
        'title': 'एसओएस आपातकालीन',
      },
      'ta': {
        'Ambulance': 'ஆம்புலன்ஸ் அழைக்கவும்',
        'Police': 'காவல்துறையை அழைக்கவும்',
        'Fire': 'தீயணைப்பு அழைக்கவும்',
        'FindHospital': 'அருகிலுள்ள மருத்துவமனைகளைக் கண்டறியவும்',
        'FindPolice': 'அருகிலுள்ள காவல் நிலையங்களைக் கண்டறியவும்',
        'title': 'SOS அவசரநிலை',
      },
      'ml': {
        'Ambulance': 'ആംബുലൻസ് വിളിക്കുക',
        'Police': 'പോലീസിനെ വിളിക്കുക',
        'Fire': 'ഫയർ ഫോഴ്സിനെ വിളിക്കുക',
        'FindHospital': 'അടുത്തുള്ള ആശുപത്രികൾ കണ്ടെത്തുക',
        'FindPolice': 'അടുത്തുള്ള പോലീസ് സ്റ്റേഷനുകൾ കണ്ടെത്തുക',
        'title': 'SOS അടിയന്തരാവസ്ഥ',
      },
      'te': {
        'Ambulance': 'అంబులెన్స్‌కు కాల్ చేయండి',
        'Police': 'పోలీసులకు కాల్ చేయండి',
        'Fire': 'ఫైర్ ఇంజిన్ కి కాల్ చేయండి',
        'FindHospital': 'సమీపంలోని ఆసుపత్రులను కనుగొనండి',
        'FindPolice': 'సమీపంలోని పోలీస్ స్టేషన్లను కనుగొనండి',
        'title': 'SOS అత్యవసర పరిస్థితి',
      },
      'kn': {
        'Ambulance': 'ಆಂಬ್ಯುಲೆನ್ಸ್‌ಗೆ ಕರೆ ಮಾಡಿ',
        'Police': 'ಪೊಲೀಸರಿಗೆ ಕರೆ ಮಾಡಿ',
        'Fire': 'ಅಗ್ನಿಶಾಮಕ ದಳಕ್ಕೆ ಕರೆ ಮಾಡಿ',
        'FindHospital': 'ಹತ್ತಿರದ ಆಸ್ಪತ್ರೆಗಳನ್ನು ಹುಡುಕಿ',
        'FindPolice': 'ಹತ್ತಿರದ ಪೊಲೀಸ್ ಠಾಣೆಗಳನ್ನು ಹುಡುಕಿ',
        'title': 'SOS ತುರ್ತು',
      },
    };
    return localizedValues[language]?[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: Text(_getText('title')),
        backgroundColor: primaryColor,
        foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            _buildSosButton(
              title: "🚑 ${_getText('Ambulance')} (108)",
              color: const Color(0xFFEF4444),
              isDark: isDark,
              onPressed: () => callNumber("108"),
            ),
            const SizedBox(height: 14),
            _buildSosButton(
              title: "👮 ${_getText('Police')} (100)",
              color: const Color(0xFF2563EB),
              isDark: isDark,
              onPressed: () => callNumber("100"),
            ),
            const SizedBox(height: 14),
            _buildSosButton(
              title: "🔥 ${_getText('Fire')} (101)",
              color: const Color(0xFFD97706),
              isDark: isDark,
              onPressed: () => callNumber("101"),
            ),
            const SizedBox(height: 28),
            _buildSosButton(
              title: "📍 ${_getText('FindHospital')}",
              color: isDark ? const Color(0xFF1CC8B5) : const Color(0xFF0F9D8A),
              isDark: isDark,
              onPressed: openHospitalMap,
            ),
            const SizedBox(height: 14),
            _buildSosButton(
              title: "📍 ${_getText('FindPolice')}",
              color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
              isDark: isDark,
              onPressed: openPoliceMap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSosButton({
    required String title,
    required Color color,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
