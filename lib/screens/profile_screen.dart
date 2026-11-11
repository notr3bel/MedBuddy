import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/date_formatter.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  final String language;
  const ProfileScreen({super.key, this.language = 'en'});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _allergiesController = TextEditingController();

  String _morningTiming = '08:00 AM';
  String _afternoonTiming = '02:00 PM';
  String _dinnerTiming = '08:00 PM';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      setState(() {});
    }
  }

  Future<void> _loadProfileData() async {
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

      setState(() {
        _emailController.text = user.email ?? '';
        _nameController.text = meta['name']?.toString() ?? '';
        _ageController.text = meta['age']?.toString() ?? '';
        _genderController.text = meta['gender']?.toString() ?? '';
        _bloodGroupController.text = meta['blood_group']?.toString() ?? '';
        _emergencyContactController.text = meta['emergency_contact']?.toString() ?? '';
        _conditionsController.text = meta['medical_conditions']?.toString() ?? '';
        _allergiesController.text = meta['allergies']?.toString() ?? '';
      });
    }

    if (mounted) {
      setState(() {
        _morningTiming = DateFormatter.format12HourTime(mTime);
        _afternoonTiming = DateFormatter.format12HourTime(aTime);
        _dinnerTiming = DateFormatter.format12HourTime(dTime);
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
        'edit_profile': 'Edit Profile',
        'save_changes': 'Save Profile',
        'profile_updated': 'Profile updated successfully!',
      },
      'hi': {
        'title': 'प्रोफ़ाइल',
        'voice_settings': 'वॉइस सेटिंग्स',
        'manage_speech': 'भाषण सेटिंग्स प्रबंधित करें',
        'logout': 'लॉग आउट',
        'voice_soon': 'वॉइस सेटिंग्स जल्द ही आ रही हैं।',
        'edit_profile': 'प्रोफ़ाइल संपादित करें',
        'save_changes': 'सहेजें',
        'profile_updated': 'प्रोफ़ाइल अपडेट हो गई!',
      },
      'kn': {
        'title': 'ಪ್ರೊಫೈಲ್',
        'voice_settings': 'ಧ್ವನಿ ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
        'manage_speech': 'ಮಾತಿನ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ನಿರ್ವಹಿಸಿ',
        'logout': 'ಲಾಗ್ ಔಟ್',
        'voice_soon': 'ಧ್ವನಿ ಸೆಟ್ಟಿಂಗ್‌ಗಳು ಶೀಘ್ರದಲ್ಲೇ ಬರಲಿವೆ.',
        'edit_profile': 'ಪ್ರೊಫೈಲ್ ಸಂಪಾದಿಸಿ',
        'save_changes': 'ಉಳಿಸಿ',
        'profile_updated': 'ಪ್ರೊಫೈಲ್ ನವೀಕರಿಸಲಾಗಿದೆ!',
      },
      'ta': {
        'title': 'சுயவிவரம்',
        'voice_settings': 'குரல் அமைப்புகள்',
        'manage_speech': 'பேச்சு அமைப்புகளை நிர்வகிக்கவும்',
        'logout': 'வெளியேறு',
        'voice_soon': 'குரல் அமைப்புகள் விரைவில் வரும்.',
        'edit_profile': 'சுயவிவரத்தைத் திருத்து',
        'save_changes': 'சேமி',
        'profile_updated': 'சுயவிவரம் புதுப்பிக்கப்பட்டது!',
      },
      'ml': {
        'title': 'പ്രൊഫൈൽ',
        'voice_settings': 'വോയിസ് ക്രമീകരണങ്ങൾ',
        'manage_speech': 'സംസാര ക്രമീകരണങ്ങൾ നിയന്ത്രിക്കുക',
        'logout': 'ലോഗ് ഔട്ട്',
        'voice_soon': 'വോയിസ് ക്രമീകരണങ്ങൾ ഉടൻ വരുന്നു.',
        'edit_profile': 'പ്രൊഫൈൽ എഡിറ്റ് ചെയ്യുക',
        'save_changes': 'സേവ് ചെയ്യുക',
        'profile_updated': 'പ്രൊഫൈൽ പുതുക്കി!',
      },
      'te': {
        'title': 'ప్రొఫైల్',
        'voice_settings': 'వాయిస్ సెట్టింగ్‌లు',
        'manage_speech': 'స్పీచ్ సెట్టింగ్‌లను నిర్వహించండి',
        'logout': 'లాగ్ అవుట్',
        'voice_soon': 'వాయిస్ సెట్టింగ్‌లు త్వరలో వస్తాయి.',
        'edit_profile': 'ప్రొఫైల్‌ను సవరించండి',
        'save_changes': 'సేవ్ చేయండి',
        'profile_updated': 'ప్రొఫైల్ నవీకరించబడింది!',
      },
    };
    return translations[widget.language]?[key] ?? translations['en']![key]!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _bloodGroupController.dispose();
    _emergencyContactController.dispose();
    _conditionsController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  void _showEditProfileModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF1CC8B5) : const Color(0xFF0F9D8A);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getText('edit_profile'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTextField(_nameController, "Full Name", Icons.person_outline, isDark, primaryColor),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_ageController, "Age", Icons.cake_outlined, isDark, primaryColor)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(_genderController, "Gender", Icons.face_outlined, isDark, primaryColor)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_bloodGroupController, "Blood Group", Icons.water_drop_outlined, isDark, primaryColor)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(_emergencyContactController, "Emergency Contact", Icons.phone_outlined, isDark, primaryColor)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(_conditionsController, "Medical Conditions", Icons.medical_information_outlined, isDark, primaryColor),
                      const SizedBox(height: 14),
                      _buildTextField(_allergiesController, "Allergies", Icons.warning_amber_outlined, isDark, primaryColor),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: Text(_getText('save_changes'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final nav = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            final user = Supabase.instance.client.auth.currentUser;
                            if (user != null) {
                              try {
                                await Supabase.instance.client.auth.updateUser(
                                  UserAttributes(
                                    data: {
                                      'name': _nameController.text.trim(),
                                      'age': _ageController.text.trim(),
                                      'gender': _genderController.text.trim(),
                                      'blood_group': _bloodGroupController.text.trim(),
                                      'emergency_contact': _emergencyContactController.text.trim(),
                                      'medical_conditions': _conditionsController.text.trim(),
                                      'allergies': _allergiesController.text.trim(),
                                    },
                                  ),
                                );
                              } catch (_) {}
                            }
                            if (mounted) {
                              setState(() {});
                              nav.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(_getText('profile_updated')),
                                  backgroundColor: primaryColor,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMedicineTimingsModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF1CC8B5) : const Color(0xFF0F9D8A);

    String tempMorning = _morningTiming;
    String tempAfternoon = _afternoonTiming;
    String tempDinner = _dinnerTiming;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickSlotTime(String slot) async {
              String currentVal = slot == 'morning'
                  ? tempMorning
                  : (slot == 'afternoon' ? tempAfternoon : tempDinner);

              int initialHour = 8;
              int initialMinute = 0;
              try {
                final parts = DateFormatter.format24HourTime(currentVal).split(':');
                initialHour = int.parse(parts[0]);
                initialMinute = int.parse(parts[1]);
              } catch (_) {}

              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
              );

              if (picked != null) {
                final dt = DateTime(2026, 1, 1, picked.hour, picked.minute);
                final formatted = DateFormatter.format12HourTime("${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}");
                setModalState(() {
                  if (slot == 'morning') tempMorning = formatted;
                  if (slot == 'afternoon') tempAfternoon = formatted;
                  if (slot == 'dinner') tempDinner = formatted;
                });
              }
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF475569) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Medicine Timings",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          "Set default reminder times for Morning, Afternoon, and Dinner slots. These will be applied to all future medicine analyses.",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTimingSlotTile(
                          title: "Morning Slot",
                          subtitle: "Default breakfast / morning dose",
                          icon: Icons.wb_sunny_rounded,
                          color: const Color(0xFFF59E0B),
                          timeVal: tempMorning,
                          isDark: isDark,
                          onTap: () => pickSlotTime('morning'),
                        ),
                        const SizedBox(height: 12),
                        _buildTimingSlotTile(
                          title: "Afternoon Slot",
                          subtitle: "Default lunch / afternoon dose",
                          icon: Icons.wb_twilight_rounded,
                          color: const Color(0xFF3B82F6),
                          timeVal: tempAfternoon,
                          isDark: isDark,
                          onTap: () => pickSlotTime('afternoon'),
                        ),
                        const SizedBox(height: 12),
                        _buildTimingSlotTile(
                          title: "Dinner Slot",
                          subtitle: "Default dinner / night dose",
                          icon: Icons.nights_stay_rounded,
                          color: const Color(0xFF8B5CF6),
                          timeVal: tempDinner,
                          isDark: isDark,
                          onTap: () => pickSlotTime('dinner'),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.check_circle_outline_rounded),
                            label: const Text("Save Timings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              final nav = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('med_timing_morning', tempMorning);
                              await prefs.setString('med_timing_afternoon', tempAfternoon);
                              await prefs.setString('med_timing_dinner', tempDinner);

                              final user = Supabase.instance.client.auth.currentUser;
                              if (user != null) {
                                try {
                                  final meta = Map<String, dynamic>.from(user.userMetadata ?? {});
                                  meta['med_timing_morning'] = tempMorning;
                                  meta['med_timing_afternoon'] = tempAfternoon;
                                  meta['med_timing_dinner'] = tempDinner;
                                  await Supabase.instance.client.auth.updateUser(UserAttributes(data: meta));
                                } catch (_) {}
                              }

                              if (mounted) {
                                setState(() {
                                  _morningTiming = tempMorning;
                                  _afternoonTiming = tempAfternoon;
                                  _dinnerTiming = tempDinner;
                                });
                                dashboardRefreshNotifier.value++;
                                nav.pop();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: const Text("Medicine timings updated successfully!"),
                                    backgroundColor: primaryColor,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimingSlotTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String timeVal,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            timeVal,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isDark, Color primaryColor) {
    return TextField(
      controller: controller,
      style: TextStyle(color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    Color color = const Color(0xFF0F9D8A),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: _getText('edit_profile'),
            onPressed: _showEditProfileModal,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Header Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: primaryColor,
                              child: Text(
                                _nameController.text.isNotEmpty 
                                    ? _nameController.text[0].toUpperCase() 
                                    : (Supabase.instance.client.auth.currentUser?.email?[0].toUpperCase() ?? 'U'),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _showEditProfileModal,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F9D8A) : const Color(0xFF1CC8B5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    size: 14,
                                    color: isDark ? const Color(0xFFF8FAFC) : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _nameController.text.isNotEmpty 
                              ? _nameController.text 
                              : (Supabase.instance.client.auth.currentUser?.email?.split('@').first ?? 'User'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _emailController.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: Text(_getText('edit_profile'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          onPressed: _showEditProfileModal,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Health Profile Info Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.75,
                    children: [
                      _buildProfileTile(
                        icon: Icons.cake_rounded,
                        title: "AGE",
                        value: _ageController.text.isNotEmpty ? "${_ageController.text} Yrs" : "--",
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                        isDark: isDark,
                      ),
                      _buildProfileTile(
                        icon: Icons.person_rounded,
                        title: "GENDER",
                        value: _genderController.text.isNotEmpty ? _genderController.text : "--",
                        color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                        isDark: isDark,
                      ),
                      _buildProfileTile(
                        icon: Icons.water_drop_rounded,
                        title: "BLOOD GROUP",
                        value: _bloodGroupController.text.isNotEmpty ? _bloodGroupController.text : "--",
                        color: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
                        isDark: isDark,
                      ),
                      _buildProfileTile(
                        icon: Icons.phone_in_talk_rounded,
                        title: "EMERGENCY CONTACT",
                        value: _emergencyContactController.text.isNotEmpty ? _emergencyContactController.text : "--",
                        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Medical History Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.2 : 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.medical_information_rounded,
                              color: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
                              size: 20,
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Medical Conditions",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit_outlined, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                onPressed: _showEditProfileModal,
                              ),
                            ],
                          ),
                          subtitle: Text(
                            _conditionsController.text.isNotEmpty ? _conditionsController.text : "Not specified",
                            style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ),
                        Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withValues(alpha: isDark ? 0.2 : 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                              size: 20,
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Allergies",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit_outlined, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                onPressed: _showEditProfileModal,
                              ),
                            ],
                          ),
                          subtitle: Text(
                            _allergiesController.text.isNotEmpty ? _allergiesController.text : "Not specified",
                            style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Preferences Card
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.alarm_on_rounded, color: primaryColor, size: 20),
                          ),
                          title: Text(
                            "Medicine Timings",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                            ),
                          ),
                          subtitle: Text(
                            "Morning: $_morningTiming • Afternoon: $_afternoonTiming • Dinner: $_dinnerTiming",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          onTap: _showMedicineTimingsModal,
                        ),
                        Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.record_voice_over_rounded, color: primaryColor, size: 20),
                          ),
                          title: Text(
                            _getText('voice_settings'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                            ),
                          ),
                          subtitle: Text(
                            _getText('manage_speech'),
                            style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_getText('voice_soon'))),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF451A1A) : const Color(0xFFFEF2F2),
                        foregroundColor: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
                        elevation: 0,
                        side: BorderSide(color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(_getText('logout'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
