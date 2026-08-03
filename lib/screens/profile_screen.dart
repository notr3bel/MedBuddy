import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final String language;
  const ProfileScreen({super.key, this.language = 'en'});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _emailController.text = user.email ?? '';
        _nameController.text = user.userMetadata?['name'] ?? 'User';
      });
    }
  }

  String _getText(String key) {
    final translations = {
      'en': {
        'title': 'Profile',
        'voice_settings': 'Voice Settings',
        'manage_speech': 'Manage Speech Settings',
        'logout': 'Logout',
        'voice_soon': 'Voice Settings coming soon.',
      },
      'hi': {
        'title': 'प्रोफ़ाइल',
        'voice_settings': 'वॉइस सेटिंग्स',
        'manage_speech': 'भाषण सेटिंग्स प्रबंधित करें',
        'logout': 'लॉग आउट',
        'voice_soon': 'वॉइस सेटिंग्स जल्द ही आ रही हैं।',
      },
      'kn': {
        'title': 'ಪ್ರೊಫೈಲ್',
        'voice_settings': 'ಧ್ವನಿ ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
        'manage_speech': 'ಮಾತಿನ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ನಿರ್ವಹಿಸಿ',
        'logout': 'ಲಾಗ್ ಔಟ್',
        'voice_soon': 'ಧ್ವನಿ ಸೆಟ್ಟಿಂಗ್‌ಗಳು ಶೀಘ್ರದಲ್ಲೇ ಬರಲಿವೆ.',
      },
      'ta': {
        'title': 'சுயവിவரம்',
        'voice_settings': 'குரல் அமைப்புகள்',
        'manage_speech': 'பேச்சு அமைப்புகளை நிர்வகிக்கவும்',
        'logout': 'வெளியேறு',
        'voice_soon': 'குரல் அமைப்புகள் விரைவில் வரும்.',
      },
      'ml': {
        'title': 'പ്രൊഫൈൽ',
        'voice_settings': 'വോയിസ് ക്രമീകരണങ്ങൾ',
        'manage_speech': 'സംസാര ക്രമീകരണങ്ങൾ നിയന്ത്രിക്കുക',
        'logout': 'ലോഗ് ഔട്ട്',
        'voice_soon': 'വോയിസ് ക്രമീകരണങ്ങൾ ഉടൻ വരുന്നു.',
      },
      'te': {
        'title': 'ప్రొఫైల్',
        'voice_settings': 'వాయిస్ సెట్టింగ్‌లు',
        'manage_speech': 'స్పీచ్ సెట్టింగ్‌లను నిర్వహించండి',
        'logout': 'లాగ్ అవుట్',
        'voice_soon': 'వాయిస్ సెట్టింగ్‌లు త్వరలో వస్తాయి.',
      },
    };
    return translations[widget.language]?[key] ?? translations['en']![key]!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _nameController.text,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _emailController.text,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.record_voice_over, color: Colors.blue),
                          title: Text(_getText('voice_settings')),
                          subtitle: Text(_getText('manage_speech')),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                             ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(_getText('voice_soon'))),
                              );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: Text(_getText('logout'), style: const TextStyle(fontSize: 18)),
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                        });
                        await Supabase.instance.client.auth.signOut();
                        if (context.mounted) {
                           setState(() { _isLoading = false; });
                           Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
