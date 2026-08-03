import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrivacySecurityScreen extends StatefulWidget {
  final String language;
  const PrivacySecurityScreen({super.key, this.language = 'en'});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  String _getText(String key) {
    final translations = {
      'en': {
        'title': 'Privacy & Security',
        'pass_auth': 'Password & Auth',
        'change_pass': 'Change Password',
        'update_pass_sub': 'Update your account password',
        '2fa': 'Two-Factor Authentication',
        '2fa_sub': 'Add an extra layer of security',
        'data_privacy': 'Data Privacy',
        'med_access': 'Medical Data Access',
        'med_access_sub': 'Control who can view your medical reports',
        'activity': 'Activity Log',
        'activity_sub': 'View recent account activity',
        'danger': 'Danger Zone',
        'delete': 'Delete Account',
        'delete_sub': 'Permanently remove your account and data',
        'new_pass': 'New Password',
        'confirm_pass': 'Confirm Password',
        'update_btn': 'Update Password',
        'enter_new': 'Enter your new password below.',
        'pass_match': 'Passwords do not match',
        'pass_len': 'Password must be at least 6 characters',
        'pass_success': 'Password updated successfully',
        '2fa_soon': '2FA configuration coming soon',
        'error_prefix': 'Error',
      },
      'hi': {
        'title': 'गोपनीयता और सुरक्षा',
        'pass_auth': 'पासवर्ड और प्रमाणीकरण',
        'change_pass': 'पासवर्ड बदलें',
        'update_pass_sub': 'अपना खाता पासवर्ड अपडेट करें',
        '2fa': 'दो-कारक प्रमाणीकरण',
        '2fa_sub': 'सुरक्षा की एक अतिरिक्त परत जोड़ें',
        'data_privacy': 'डेटा गोपनीयता',
        'med_access': 'स्वास्थ्य डेटा एक्सेस',
        'med_access_sub': 'नियंत्रित करें कि आपकी मेडिकल रिपोर्ट कौन देख सकता है',
        'activity': 'गतिविधि लॉग',
        'activity_sub': 'हालिया खाता गतिविधि देखें',
        'danger': 'खतरा क्षेत्र',
        'delete': 'खाता हटाएं',
        'delete_sub': 'अपना खाता और डेटा स्थायी रूप से हटाएं',
        'new_pass': 'नया पासवर्ड',
        'confirm_pass': 'पासवर्ड की पुष्टि करें',
        'update_btn': 'पासवर्ड अपडेट करें',
        'enter_new': 'नीचे अपना नया पासवर्ड दर्ज करें।',
        'pass_match': 'पासवर्ड मेल नहीं खाते',
        'pass_len': 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए',
        'pass_success': 'पासवर्ड सफलतापूर्वक अपडेट किया गया',
        '2fa_soon': '2FA कॉन्फ़िगरेशन जल्द आ रहा है',
        'error_prefix': 'त्रुटि',
      },
      'kn': {
        'title': 'ಗೌಪ್ಯತೆ ಮತ್ತು ಭದ್ರತೆ',
        'pass_auth': 'ಪಾಸ್‌ವರ್ಡ್ ಮತ್ತು ದೃಢೀಕರಣ',
        'change_pass': 'ಪಾಸ್‌ವರ್ಡ್ ಬದಲಾಯಿಸಿ',
        'update_pass_sub': 'ನಿಮ್ಮ ಖಾತೆಯ ಪಾಸ್‌ವರ್ಡ್ ಅನ್ನು ನವೀಕರಿಸಿ',
        '2fa': 'ಎರಡು-ಹಂತದ ದೃಢೀಕರಣ',
        '2fa_sub': 'ಹೆಚ್ಚುವರಿ ಭದ್ರತೆಯನ್ನು ಸೇರಿಸಿ',
        'data_privacy': 'ಡೇಟಾ ಗೌಪ್ಯತೆ',
        'med_access': 'ವೈದ್ಯಕೀಯ ಡೇಟಾ ಪ್ರವೇಶ',
        'med_access_sub': 'ನಿಮ್ಮ ವೈದ್ಯಕೀಯ ವರದಿಗಳನ್ನು ಯಾರು ವೀಕ್ಷಿಸಬಹುದು ಎಂಬುದನ್ನು ನಿಯಂತ್ರಿಸಿ',
        'activity': 'ಚಟುವಟಿಕೆ ಲಾಗ್',
        'activity_sub': 'ಇತ್ತೀಚಿನ ಖಾತೆ ಚಟುವಟಿಕೆಯನ್ನು ವೀಕ್ಷಿಸಿ',
        'danger': 'ಅಪಾಯಕಾರಿ ವಲಯ',
        'delete': 'ಖಾತೆಯನ್ನು ಅಳಿಸಿ',
        'delete_sub': 'ನಿಮ್ಮ ಖಾತೆ ಮತ್ತು ಡೇಟಾವನ್ನು ಶಾಶ್ವತವಾಗಿ ಅಳಿಸಿ',
        'new_pass': 'ಹೊಸ ಪಾಸ್‌ವರ್ಡ್',
        'confirm_pass': 'ಪಾಸ್‌ವರ್ಡ್ ಅನ್ನು ದೃಢೀಕರಿಸಿ',
        'update_btn': 'ಪಾಸ್‌ವರ್ಡ್ ಅನ್ನು ನವೀಕರಿಸಿ',
        'enter_new': 'ಕೆಳಗೆ ನಿಮ್ಮ ಹೊಸ ಪಾಸ್‌ವರ್ಡ್ ಅನ್ನು ನಮೂದಿಸಿ.',
        'pass_match': 'ಪಾಸ್‌ವರ್ಡ್‌ಗಳು ಹೊಂದಿಕೆಯಾಗುತ್ತಿಲ್ಲ',
        'pass_len': 'ಪಾಸ್‌ವರ್ಡ್ ಕನಿಷ್ಠ 6 ಅಕ್ಷರಗಳನ್ನು ಹೊಂದಿರಬೇಕು',
        'pass_success': 'ಪಾಸ್‌ವರ್ಡ್ ಅನ್ನು ಯಶಸ್ವಿಯಾಗಿ ನವೀಕರಿಸಲಾಗಿದೆ',
        '2fa_soon': '2FA ಶೀಘ್ರದಲ್ಲೇ ಬರಲಿದೆ',
        'error_prefix': 'ದೋಷ',
      },
      'ta': {
        'title': 'தனியுரிமை மற்றும் பாதுகாப்பு',
        'pass_auth': 'கடவுச்சொல் மற்றும் அங்கீகாரம்',
        'change_pass': 'கடவுச்சொல்லை மாற்றவும்',
        'update_pass_sub': 'உங்கள் கணக்கு கடவுச்சொல்லைப் புதுப்பிக்கவும்',
        '2fa': 'இரண்டு காரணி அங்கீகாரம்',
        '2fa_sub': 'கூடுதல் பாதுகாப்பைச் சேர்க்கவும்',
        'data_privacy': 'தரவுத் தனியுரிமை',
        'med_access': 'மருத்துவ தரவு அணுகல்',
        'med_access_sub': 'உங்கள் மருத்துவ அறிக்கைகளை யார் பார்க்கலாம் என்பதைக் கட்டுப்படுத்தவும்',
        'activity': 'செயல்பாட்டு பதிவு',
        'activity_sub': 'சமீபத்திய கணக்கு செயல்பாட்டைப் பார்க்கவும்',
        'danger': 'அபாய மண்டலம்',
        'delete': 'கணக்கை நீக்கு',
        'delete_sub': 'உங்கள் கணக்கு மற்றும் தரவை நிரந்தரமாக அகற்றவும்',
        'new_pass': 'புதிய கடவுச்சொல்',
        'confirm_pass': 'கடவுச்சொல்லை உறுதிப்படுத்தவும்',
        'update_btn': 'கடவுச்சொல்லைப் புதுப்பிக்கவும்',
        'enter_new': 'உங்கள் புதிய கடவுச்சொல்லைக் கீழே உள்ளிடவும்.',
        'pass_match': 'கடவுச்சொற்கள் பொருந்தவில்லை',
        'pass_len': 'கடவுச்சொல் குறைந்தது 6 எழுத்துகளாக இருக்க வேண்டும்',
        'pass_success': 'கடவுச்சொல் வெற்றிகரமாகப் புதுப்பிக்கப்பட்டது',
        '2fa_soon': '2FA விரைவில் வரும்',
        'error_prefix': 'பிழை',
      },
      'ml': {
        'title': 'സ്വകാര്യതയും സുരക്ഷയും',
        'pass_auth': 'പാസ്‌വേഡ് & ഓതന്റിക്കേഷൻ',
        'change_pass': 'പാസ്‌വേഡ് മാറ്റുക',
        'update_pass_sub': 'നിങ്ങളുടെ അക്കൗണ്ട് പാസ്‌വേഡ് അപ്‌ഡേറ്റ് ചെയ്യുക',
        '2fa': 'ടു-ഫാക്ടർ ഓതന്റിക്കേഷൻ',
        '2fa_sub': 'സുരക്ഷയ്ക്ക് ഒരു അധിക ലെയർ ചേർക്കുക',
        'data_privacy': 'ഡാറ്റ സ്വകാര്യത',
        'med_access': 'മെഡിക്കൽ ഡാറ്റ ആക്സസ്',
        'med_access_sub': 'നിങ്ങളുടെ മെഡിക്കൽ റിപ്പോർട്ടുകൾ ആർക്കൊക്കെ കാണാമെന്ന് നിയന്ത്രിക്കുക',
        'activity': 'ആക്ടിവിറ്റി ലോഗ്',
        'activity_sub': 'സമീപകാല അക്കൗണ്ട് ആക്ടിവിറ്റി കാണുക',
        'danger': 'അപകട മേഖല',
        'delete': 'അക്കൗണ്ട് ഇല്ലാതാക്കുക',
        'delete_sub': 'നിങ്ങളുടെ അക്കൗണ്ടും ഡാറ്റയും ശാശ്വതമായി നീക്കം ചെയ്യുക',
        'new_pass': 'പുതിയ പാസ്‌വേഡ്',
        'confirm_pass': 'പാസ്‌വേഡ് സ്ഥിരീകരിക്കുക',
        'update_btn': 'പാസ്‌വേഡ് അപ്‌ഡേറ്റ് ചെയ്യുക',
        'enter_new': 'നിങ്ങളുടെ പുതിയ പാസ്‌വേഡ് താഴെ നൽകുക.',
        'pass_match': 'പാസ്‌വേഡുകൾ പൊരുത്തപ്പെടുന്നില്ല',
        'pass_len': 'പാസ്‌വേഡിന് കുറഞ്ഞത് 6 അക്ഷരങ്ങളുണ്ടാകണം',
        'pass_success': 'പാസ്‌വേഡ് വിജയകരമായി അപ്‌ഡേറ്റ് ചെയ്തു',
        '2fa_soon': '2FA ഉടൻ വരുന്നു',
        'error_prefix': 'പിശക്',
      },
      'te': {
        'title': 'గోప్యత మరియు భద్రత',
        'pass_auth': 'పాస్‌వర్డ్ మరియు ప్రమాణీకరణ',
        'change_pass': 'పాస్‌వర్డ్ మార్చండి',
        'update_pass_sub': 'మీ ఖాతా పాస్‌వర్డ్‌ను నవీకరించండి',
        '2fa': 'ద్వి-కారక ప్రమాణీకరణ',
        '2fa_sub': 'అదనపు భద్రతా పొరను జోడించండి',
        'data_privacy': 'డేటా గోప్యత',
        'med_access': 'వైద్య డేటా యాక్సెస్',
        'med_access_sub': 'మీ వైద్య నివేదికలను ఎవరు చూడవచ్చో నియంత్రించండి',
        'activity': 'యాక్టివిటీ లాగ్',
        'activity_sub': 'ఇటీవలి ఖాతా కార్యకలాపాలను చూడండి',
        'danger': 'ప్రమాదకర మండలం',
        'delete': 'ఖాతాను తొలగించండి',
        'delete_sub': 'మీ ఖాతా మరియు డేటాను శాశ్వతంగా తొలగించండి',
        'new_pass': 'కొత్త పాస్‌వర్డ్',
        'confirm_pass': 'పాస్‌వర్డ్‌ను నిర్ధారించండి',
        'update_btn': 'పాస్‌వర్డ్‌ను నవీకరించండి',
        'enter_new': 'మీ కొత్త పాస్‌వర్డ్‌ను క్రింద నమోదు చేయండి.',
        'pass_match': 'పాస్‌వర్డ్‌లు సరిపోలడం లేదు',
        'pass_len': 'పాస్‌వర్డ్ కనీసం 6 అక్షరాలు ఉండాలి',
        'pass_success': 'పాస్‌వర్డ్ విజయవంతంగా నవీకరించబడింది',
        '2fa_soon': '2FA త్వరలో అందుబాటులోకి వస్తుంది',
        'error_prefix': 'లోపం',
      },
    };
    return translations[widget.language]?[key] ?? translations['en']![key]!;
  }

  Future<void> _updatePassword() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getText('pass_match'))),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getText('pass_len'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getText('pass_success'))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${_getText('error_prefix')}: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(_getText('pass_auth')),
            const SizedBox(height: 15),
            _buildSecurityCard(
              title: _getText('change_pass'),
              subtitle: _getText('update_pass_sub'),
              icon: Icons.lock_outline,
              onTap: () => _showChangePasswordDialog(),
            ),
            const SizedBox(height: 10),
            _buildSecurityCard(
              title: _getText('2fa'),
              subtitle: _getText('2fa_sub'),
              icon: Icons.vibration,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_getText('2fa_soon'))),
                );
              },
            ),
            const SizedBox(height: 30),
            _buildSectionHeader(_getText('data_privacy')),
            const SizedBox(height: 15),
            _buildSecurityCard(
              title: _getText('med_access'),
              subtitle: _getText('med_access_sub'),
              icon: Icons.visibility_outlined,
              onTap: () {},
            ),
             const SizedBox(height: 10),
            _buildSecurityCard(
              title: _getText('activity'),
              subtitle: _getText('activity_sub'),
              icon: Icons.history,
              onTap: () {},
            ),
            const SizedBox(height: 30),
            _buildSectionHeader(_getText('danger')),
            const SizedBox(height: 15),
            _buildSecurityCard(
              title: _getText('delete'),
              subtitle: _getText('delete_sub'),
              icon: Icons.delete_forever_outlined,
              iconColor: Colors.red,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.teal.shade700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSecurityCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.teal,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }

  void _showChangePasswordDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 30,
          top: 30,
          left: 25,
          right: 25,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getText('change_pass'), 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(_getText('enter_new'), 
              style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 25),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: _inputDecoration(_getText('new_pass'), Icons.lock_outline),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: _inputDecoration(_getText('confirm_pass'), Icons.lock_clock_outlined),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_getText('update_btn'), 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.teal),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.teal, width: 2),
      ),
    );
  }
}
