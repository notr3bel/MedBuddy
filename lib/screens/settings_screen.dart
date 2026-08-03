import 'package:flutter/material.dart';
import 'profile_screen.dart';

import 'privacy_security_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String currentLanguage;

  const SettingsScreen({super.key, required this.currentLanguage});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _selectedLanguage;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.currentLanguage;
  }

  String _getText(String key) {
    final translations = {
      'en': {
        'title': 'Settings',
        'account': 'Account',
        'profile': 'Profile Details',
        'profile_sub': 'Manage your personal identity',
        'privacy': 'Privacy & Security',
        'privacy_sub': 'Password, data and account security',
        'preferences': 'Preferences',
        'language': 'Language',
        'notifications': 'Notifications',
        'notif_sub': 'Stay updated with alerts',
        'support': 'Support',
        'help': 'Help Center',
        'help_sub': 'FAQs and support guides',
        'about': 'About MedIntel',
        'version': 'Version 1.0.0',
        'desc': 'Your personal medical assistant.',
      },
      'hi': {
        'title': 'सेटिंग्स',
        'account': 'खाता',
        'profile': 'प्रोफ़ाइल विवरण',
        'profile_sub': 'अपनी व्यक्तिगत पहचान प्रबंधित करें',
        'privacy': 'गोपनीयता और सुरक्षा',
        'privacy_sub': 'पासवर्ड, डेटा और खाता सुरक्षा',
        'preferences': 'वरीयताएँ',
        'language': 'भाषा',
        'notifications': 'सूचनाएं',
        'notif_sub': 'अलर्ट के साथ अपडेट रहें',
        'support': 'सहायता',
        'help': 'सहायता केंद्र',
        'help_sub': 'अक्सर पूछे जाने वाले प्रश्न और मार्गदर्शिकाएँ',
        'about': 'MedIntel के बारे में',
        'version': 'संस्करण 1.0.0',
        'desc': 'आपका व्यक्तिगत चिकित्सा सहायक।',
      },
      'kn': {
        'title': 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
        'account': 'ಖಾತೆ',
        'profile': 'ಪ್ರೊಫೈಲ್ ವಿವರಗಳು',
        'profile_sub': 'ನಿಮ್ಮ ವೈಯಕ್ತಿಕ ಗುರುತನ್ನು ನಿರ್ವಹಿಸಿ',
        'privacy': 'ಗೌಪ್ಯತೆ ಮತ್ತು ಭದ್ರತೆ',
        'privacy_sub': 'ಪಾಸ್‌ವರ್ಡ್, ಡೇಟಾ ಮತ್ತು ಖಾತೆ ಭದ್ರತೆ',
        'preferences': 'ಆದ್ಯತೆಗಳು',
        'language': 'ಭಾಷೆ',
        'notifications': 'ಅಧಿಸೂಚನೆಗಳು',
        'notif_sub': 'ಎಚ್ಚರಿಕೆಗಳೊಂದಿಗೆ ನವೀಕೃತವಾಗಿರಿ',
        'support': 'ಬೆಂಬಲ',
        'help': 'ಸಹಾಯ ಕೇಂದ್ರ',
        'help_sub': 'FAQ ಗಳು ಮತ್ತು ಬೆಂಬಲ ಮಾರ್ಗದರ್ಶಿಗಳು',
        'about': 'MedIntel ಬಗ್ಗೆ',
        'version': 'ಆವೃತ್ತಿ 1.0.0',
        'desc': 'ನಿಮ್ಮ ವೈಯಕ್ತಿಕ ವೈದ್ಯಕೀಯ ಸಹಾಯಕ.',
      },
      'ta': {
        'title': 'அமைப்புகள்',
        'account': 'கணக்கு',
        'profile': 'சுயவிவர விவரங்கள்',
        'profile_sub': 'உங்கள் தனிப்பட்ட அடையாளத்தை நிர்வகிக்கவும்',
        'privacy': 'தனியுரிமை மற்றும் பாதுகாப்பு',
        'privacy_sub': 'கடவுச்சொல், தரவு மற்றும் கணக்கு பாதுகாப்பு',
        'preferences': 'விருப்பத்தேர்வுகள்',
        'language': 'மொழி',
        'notifications': 'அறிவிப்புகள்',
        'notif_sub': 'விழிப்பூட்டல்களுடன் புதுப்பித்த நிலையில் இருக்கவும்',
        'support': 'ஆதரவு',
        'help': 'உதவி மையம்',
        'help_sub': 'அடிக்கடி கேட்கப்படும் கேள்விகள் மற்றும் வழிகாட்டிகள்',
        'about': 'MedIntel பற்றி',
        'version': 'பதிப்பு 1.0.0',
        'desc': 'உங்கள் தனிப்பட்ட மருத்துவ உதவியாளர்.',
      },
      'ml': {
        'title': 'ക്രമീകരണങ്ങൾ',
        'account': 'അക്കൗണ്ട്',
        'profile': 'പ്രൊഫൈൽ വിശദാംശങ്ങൾ',
        'profile_sub': 'നിങ്ങളുടെ വ്യക്തിഗത ഐഡന്റിറ്റി നിയന്ത്രിക്കുക',
        'privacy': 'സ്വകാര്യതയും സുരക്ഷയും',
        'privacy_sub': 'പാസ്‌വേഡ്, ഡാറ്റ, അക്കൗണ്ട് സുരക്ഷ',
        'preferences': 'മുൻഗണനകൾ',
        'language': 'ഭാഷ',
        'notifications': 'അറിയിപ്പുകൾ',
        'notif_sub': 'അലേർട്ടുകൾക്കൊപ്പം അപ്‌ഡേറ്റ് ആയിരിക്കുക',
        'support': 'പിന്തുണ',
        'help': 'സഹായ കേന്ദ്രം',
        'help_sub': 'പതിവുചോദ്യങ്ങളും പിന്തുണ ഗൈഡുകളും',
        'about': 'MedIntel-നെ കുറിച്ച്',
        'version': 'പതിപ്പ് 1.0.0',
        'desc': 'നിങ്ങളുടെ വ്യക്തിഗത മെഡിക്കൽ സഹായി.',
      },
      'te': {
        'title': 'సెట్టింగులు',
        'account': 'ఖాతా',
        'profile': 'ప్రొఫైల్ వివరాలు',
        'profile_sub': 'మీ వ్యక్తిగత గుర్తింపును నిర్వహించండి',
        'privacy': 'గోప్యత మరియు భద్రత',
        'privacy_sub': 'పాస్‌వర్డ్, డేటా మరియు ఖాతా భద్రత',
        'preferences': 'ప్రాధాన్యతలు',
        'language': 'భాష',
        'notifications': 'నోటిఫికేషన్లు',
        'notif_sub': 'అలర్ట్‌లతో అప్‌డేట్‌గా ఉండండి',
        'support': 'మద్దతు',
        'help': 'సహాయ కేంద్రం',
        'help_sub': 'తరచుగా అడిగే ప్రశ్నలు మరియు మద్దతు గైడ్‌లు',
        'about': 'MedIntel గురించి',
        'version': 'వెర్షన్ 1.0.0',
        'desc': 'మీ వ్యక్తిగత వైద్య సహాయకుడు.',
      },
    };
    return translations[_selectedLanguage]?[key] ?? translations['en']![key]!;
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
          onPressed: () => Navigator.pop(context, _selectedLanguage),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildSectionHeader(_getText('account')),
            const SizedBox(height: 12),
            _buildSettingsCard(
              children: [
                _buildSettingsTile(
                  icon: Icons.person_outline,
                  title: _getText('profile'),
                  subtitle: _getText('profile_sub'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: _getText('privacy'),
                  subtitle: _getText('privacy_sub'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PrivacySecurityScreen(language: _selectedLanguage)),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 25),
            _buildSectionHeader(_getText('preferences')),
            const SizedBox(height: 12),
            _buildSettingsCard(
              children: [
                _buildSettingsTile(
                  icon: Icons.language_outlined,
                  title: _getText('language'),
                  subtitle: _getLanguageName(_selectedLanguage),
                  trailing: _buildLanguageDropdown(),
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.notifications_none_outlined,
                  title: _getText('notifications'),
                  subtitle: _getText('notif_sub'),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (val) => setState(() => _notificationsEnabled = val),
                    activeThumbColor: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            _buildSectionHeader(_getText('support')),
            const SizedBox(height: 12),
            _buildSettingsCard(
              children: [
                _buildSettingsTile(
                  icon: Icons.help_outline,
                  title: _getText('help'),
                  subtitle: _getText('help_sub'),
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.info_outline,
                  title: _getText('about'),
                  subtitle: _getText('version'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'MedIntel',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(Icons.local_hospital, size: 40, color: Colors.teal),
                      children: [Text(_getText('desc'))],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.teal, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 70, endIndent: 20, color: Colors.grey.shade100);
  }

  Widget _buildLanguageDropdown() {
    return DropdownButton<String>(
      value: _selectedLanguage,
      underline: const SizedBox(),
      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
      items: const [
        DropdownMenuItem(value: "en", child: Text("EN")),
        DropdownMenuItem(value: "hi", child: Text("HI")),
        DropdownMenuItem(value: "kn", child: Text("KN")),
        DropdownMenuItem(value: "ta", child: Text("TA")),
        DropdownMenuItem(value: "ml", child: Text("ML")),
        DropdownMenuItem(value: "te", child: Text("TE")),
      ],
      onChanged: (val) { if (val != null) setState(() => _selectedLanguage = val); },
    );
  }

  String _getLanguageName(String code) {
    final translations = {
      'en': 'English',
      'hi': 'हिंदी (Hindi)',
      'kn': 'ಕನ್ನಡ (Kannada)',
      'ta': 'தமிழ் (Tamil)',
      'ml': 'മലയാളം (Malayalam)',
      'te': 'తెలుగు (Telugu)',
    };
    return translations[code] ?? 'English';
  }
}
