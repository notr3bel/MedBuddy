import 'package:flutter/material.dart';
import '../main.dart';
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

  void _handleLanguageChanged(String newLang) {
    updateAppLanguage(newLang);
  }

  String _getText(String key, String currentLang) {
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
    return translations[currentLang]?[key] ?? translations['en']![key]!;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, currentLang, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final navBg = isDark ? const Color(0xFF1E293B) : Colors.white;

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              DashboardScreen(
                language: currentLang,
                onLanguageChanged: _handleLanguageChanged,
              ),
              ScanScreen(language: currentLang),
              VoiceScreen(language: currentLang),
              HealthTimelineScreen(language: currentLang),
              ProfileScreen(language: currentLang),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: navBg,
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFF0F172A).withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Container(
                height: 68,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, _getText('home', currentLang), isDark),
                    _buildNavItem(1, Icons.center_focus_strong_rounded, Icons.center_focus_weak_rounded, _getText('scan', currentLang), isDark),
                    _buildNavItem(2, Icons.mic_rounded, Icons.mic_none_rounded, _getText('voice', currentLang), isDark),
                    _buildNavItem(3, Icons.timeline_rounded, Icons.timeline_outlined, _getText('timeline', currentLang), isDark),
                    _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, _getText('profile', currentLang), isDark),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData selectedIcon, IconData unselectedIcon, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    final activeColor = isDark ? const Color(0xFF1CC8B5) : const Color(0xFF0F9D8A);
    final unselectedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        if (index == 0) {
          dashboardRefreshNotifier.value++;
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: isDark ? 0.2 : 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? activeColor : unselectedColor,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
