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
    final Uri mapUri = Uri.parse(
        "https://www.google.com/maps/search/hospitals+near+me");

    await launchUrl(mapUri, mode: LaunchMode.externalApplication);
  }

  Future<void> openPoliceMap() async {
    final Uri mapUri =
        Uri.parse("https://www.google.com/maps/search/police+station+near+me");

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
    return Scaffold(
      appBar: AppBar(
        title: Text(_getText('title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => callNumber("108"),
              child: Text("🚑 ${_getText('Ambulance')} (108)"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => callNumber("100"),
              child: Text("👮 ${_getText('Police')} (100)"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => callNumber("101"),
              child: Text("🔥 ${_getText('Fire')} (101)"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: openHospitalMap,
              child: Text("📍 ${_getText('FindHospital')}"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: openPoliceMap,
              child: Text("📍 ${_getText('FindPolice')}"),
            ),
          ],
        ),
      ),
    );
  }
}

