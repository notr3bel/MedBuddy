import 'package:flutter/material.dart';
import '../main.dart';
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
  late bool _darkModeEnabled;
  bool _reminderAlertsEnabled = true;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.currentLanguage;
    _darkModeEnabled = themeNotifier.value == ThemeMode.dark;
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
        'dark_mode': 'Dark Mode',
        'dark_mode_sub': 'Switch app theme to dark mode',
        'notifications': 'Notifications',
        'notif_sub': 'Stay updated with alerts',
        'med_reminders': 'Medication Reminders',
        'med_reminders_sub': 'Push alerts & sound notifications for medicine doses',
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
        'dark_mode': 'डार्क मोड',
        'dark_mode_sub': 'ऐप थीम को डार्क मोड में बदलें',
        'notifications': 'सूचनाएं',
        'notif_sub': 'अलर्ट के साथ अपडेट रहें',
        'med_reminders': 'दवा अनुस्मारक',
        'med_reminders_sub': 'दवा की खुराक के लिए पुश अलर्ट और ध्वनि सूचनाएं',
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
        'dark_mode': 'ಡಾರ್ಕ್ ಮೋಡ್',
        'dark_mode_sub': 'ಆ್ಯಪ್ ಥೀಮ್ ಅನ್ನು ಡಾರ್ಕ್ ಮೋಡ್‌ಗೆ ಬದಲಾಯಿಸಿ',
        'notifications': 'ಅಧಿಸೂಚನೆಗಳು',
        'notif_sub': 'ಎಚ್ಚರಿಕೆಗಳೊಂದಿಗೆ ನವೀಕೃತವಾಗಿರಿ',
        'med_reminders': 'ಔಷಧಿ ಜ್ಞಾಪನೆಗಳು',
        'med_reminders_sub': 'ಔಷಧಿ ಡೋಸ್‌ಗಳಿಗೆ ಪುಶ್ ಅಲರ್ಟ್‌ಗಳು ಮತ್ತು ಧ್ವನಿ ಅಧಿಸೂಚನೆಗಳು',
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
        'dark_mode': 'இருண்ட பயன்முறை',
        'dark_mode_sub': 'செயலி தீமை இருண்ட பயன்முறைக்கு மாற்றவும்',
        'notifications': 'அறிவிப்புகள்',
        'notif_sub': 'விழிப்பூட்டல்களுடன் புதுப்பித்த நிலையில் இருக்கவும்',
        'med_reminders': 'மருந்து நினைவூட்டல்கள்',
        'med_reminders_sub': 'மருந்து நேரங்களுக்கான எச்சரிக்கை மற்றும் ஒலி அறிவிப்புகள்',
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
        'dark_mode': 'ഡാർക്ക് മോഡ്',
        'dark_mode_sub': 'ആപ്പ് തീം ഡാർക്ക് മോഡിലേക്ക് മാറ്റുക',
        'notifications': 'അറിയിപ്പുകൾ',
        'notif_sub': 'അലേർട്ടുകൾക്കൊപ്പം അപ്‌ഡേറ്റ് ആയിരിക്കുക',
        'med_reminders': 'മരുന്ന് ഓർമ്മപ്പെടുത്തലുകൾ',
        'med_reminders_sub': 'മരുന്ന് ഡോസുകൾക്കുള്ള പുഷ് അലേർട്ടുകളും ശബ്ദ അറിയിപ്പുകളും',
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
        'dark_mode': 'డార్క్ మోడ్',
        'dark_mode_sub': 'యాప్ థీమ్‌ను డార్క్ మోడ్‌కి మార్చండి',
        'notifications': 'నోటిఫికేషన్లు',
        'notif_sub': 'అలర్ట్‌లతో అప్‌డేట్‌గా ఉండండి',
        'med_reminders': 'మందుల రిమైండర్లు',
        'med_reminders_sub': 'మందుల మోతాదుల కోసం పుష్ అలర్ట్‌లు మరియు శబ్ద నోటిఫికేషన్‌లు',
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
          onPressed: () => Navigator.pop(context, _selectedLanguage),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildSectionHeader(_getText('account'), isDark),
            const SizedBox(height: 12),
            _buildSettingsCard(
              isDark: isDark,
              children: [
                _buildSettingsTile(
                  isDark: isDark,
                  primaryColor: primaryColor,
                  icon: Icons.person_outline_rounded,
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
                _buildDivider(isDark),
                _buildSettingsTile(
                  isDark: isDark,
                  primaryColor: primaryColor,
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
            _buildSectionHeader(_getText('preferences'), isDark),
            const SizedBox(height: 12),
            _buildSettingsCard(
              isDark: isDark,
              children: [
                _buildSettingsTile(
                  isDark: isDark,
                  primaryColor: primaryColor,
                  icon: Icons.language_rounded,
                  title: _getText('language'),
                  subtitle: _getLanguageName(_selectedLanguage),
                  trailing: _buildLanguageDropdown(isDark),
                ),
                _buildDivider(isDark),
                _buildSettingsTile(
                  isDark: isDark,
                  primaryColor: primaryColor,
                  icon: Icons.dark_mode_outlined,
                  title: _getText('dark_mode'),
                  subtitle: _getText('dark_mode_sub'),
                  trailing: Switch(
                    value: _darkModeEnabled,
                    onChanged: (val) {
                      setState(() {
                        _darkModeEnabled = val;
                        updateAppTheme(val ? ThemeMode.dark : ThemeMode.light);
                      });
                    },
                    activeThumbColor: primaryColor,
                  ),
                ),
                _buildDivider(isDark),
                _buildSettingsTile(
                  isDark: isDark,
                  primaryColor: primaryColor,
                  icon: Icons.notifications_none_rounded,
                  title: _getText('notifications'),
                  subtitle: _getText('notif_sub'),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (val) => setState(() => _notificationsEnabled = val),
                    activeThumbColor: primaryColor,
                  ),
                ),
                _buildDivider(isDark),
                _buildSettingsTile(
                  isDark: isDark,
                  primaryColor: primaryColor,
                  icon: Icons.alarm_on_rounded,
                  title: _getText('med_reminders'),
                  subtitle: _getText('med_reminders_sub'),
                  trailing: Switch(
                    value: _reminderAlertsEnabled,
                    onChanged: (val) => setState(() => _reminderAlertsEnabled = val),
                    activeThumbColor: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            _buildSectionHeader(_getText('support'), isDark),
            const SizedBox(height: 12),
            _buildSettingsCard(
              isDark: isDark,
              children: [
                _buildSettingsTile(
                  isDark: isDark,
                  primaryColor: primaryColor,
                  icon: Icons.help_outline_rounded,
                  title: _getText('help'),
                  subtitle: _getText('help_sub'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Help Center & FAQs opened.")),
                    );
                  },
                ),
                _buildDivider(isDark),
                _buildSettingsTile(
                  isDark: isDark,
                  primaryColor: primaryColor,
                  icon: Icons.info_outline_rounded,
                  title: _getText('about'),
                  subtitle: _getText('version'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'MedIntel',
                      applicationVersion: '1.0.0',
                      applicationIcon: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset('assets/images/logo.png', width: 44, height: 44, fit: BoxFit.cover),
                      ),
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

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
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
    required bool isDark,
    required Color primaryColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primaryColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          fontSize: 13,
        ),
      ),
      trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 70,
      endIndent: 20,
      color: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
    );
  }

  Widget _buildLanguageDropdown(bool isDark) {
    return DropdownButton<String>(
      value: _selectedLanguage,
      underline: const SizedBox(),
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      icon: Icon(
        Icons.keyboard_arrow_down,
        size: 18,
        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
      ),
      items: [
        for (var code in ["en", "hi", "kn", "ta", "ml", "te"])
          DropdownMenuItem(
            value: code,
            child: Text(
              code.toUpperCase(),
              style: TextStyle(
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
          ),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedLanguage = val);
          updateAppLanguage(val);
        }
      },
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
