import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'scan_screen.dart';
import 'voice_screen.dart';
import 'health_timeline_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  String _selectedLanguage = "en"; // Lift state up if needed for sub-screens

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initScreens();
  }

  void _initScreens() {
    _screens = [
      DashboardScreen(
        language: _selectedLanguage,
        onLanguageChanged: _handleLanguageChanged,
      ),
      ScanScreen(language: _selectedLanguage),
      VoiceScreen(language: _selectedLanguage),
      HealthTimelineScreen(language: _selectedLanguage),
      ProfileScreen(language: _selectedLanguage),
    ];
  }

  void _handleLanguageChanged(String newLang) {
    setState(() {
      _selectedLanguage = newLang;
      // Re-initialize screens to pass down the new language
      _initScreens();
    });
  }

  String _getText(String key) {
    final translations = {
      'en': {
        'home': 'Home',
        'scan': 'Scan',
        'voice': 'Voice',
        'timeline': 'Timeline',
        'profile': 'Profile',
      },
      'hi': {
        'home': 'होम',
        'scan': 'स्कैन',
        'voice': 'वॉइस',
        'timeline': 'समयरेखा',
        'profile': 'प्रोफ़ाइल',
      },
      'kn': {
        'home': 'ಮನೆ',
        'scan': 'ಸ್ಕ್ಯಾನ್',
        'voice': 'ಧ್ವನಿ',
        'timeline': 'ಕಾಲಸೂಚಿ',
        'profile': 'ಪ್ರೊಫೈಲ್',
      },
      'ta': {
        'home': 'முகப்பு',
        'scan': 'ஸ்கேன்',
        'voice': 'குரல்',
        'timeline': 'காலவரிசை',
        'profile': 'சுயவிவரம்',
      },
      'ml': {
        'home': 'ഹോം',
        'scan': 'സ്കാൻ',
        'voice': 'വോയിസ്',
        'timeline': 'രേഖ',
        'profile': 'പ്രൊഫൈൽ',
      },
      'te': {
        'home': 'హోమ్',
        'scan': 'స్కాన్',
        'voice': 'వాయిస్',
        'timeline': 'టైమ్ లైన్',
        'profile': 'ప్రొఫైల్',
      },
    };
    return translations[_selectedLanguage]?[key] ?? translations['en']![key]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, Icons.home_rounded, _getText('home')),
              _buildNavItem(1, Icons.camera_alt_rounded, _getText('scan')),
              _buildNavItem(2, Icons.mic_rounded, _getText('voice')),
              _buildNavItem(3, Icons.timeline_rounded, _getText('timeline')),
              _buildNavItem(4, Icons.person_rounded, _getText('profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.teal : Colors.grey,
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                crossFadeState: isSelected
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
