import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/main_navigation.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'services/notification_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);
final ValueNotifier<String> languageNotifier = ValueNotifier<String>('en');
final ValueNotifier<int> dashboardRefreshNotifier = ValueNotifier<int>(0);
final ValueNotifier<List<Map<String, dynamic>>> pendingRemindersNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);

Future<void> updateAppTheme(ThemeMode mode) async {
  themeNotifier.value = mode;
  final themeStr = mode == ThemeMode.dark ? 'dark' : 'light';
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', themeStr);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final meta = Map<String, dynamic>.from(user.userMetadata ?? {});
      meta['theme'] = themeStr;
      await Supabase.instance.client.auth.updateUser(UserAttributes(data: meta));
    }
  } catch (e) {
    debugPrint("Error saving theme preference: $e");
  }
}

Future<void> updateAppLanguage(String lang) async {
  languageNotifier.value = lang;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final meta = Map<String, dynamic>.from(user.userMetadata ?? {});
      meta['language'] = lang;
      await Supabase.instance.client.auth.updateUser(UserAttributes(data: meta));
    }
  } catch (e) {
    debugPrint("Error saving language preference: $e");
  }
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint("Initializing Dotenv...");
    await dotenv.load(fileName: ".env");

    debugPrint("Initializing Supabase...");
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );

    debugPrint("Initializing Notification Service...");
    await NotificationService().init();

    debugPrint("Loading User Preferences...");
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('app_theme');
      final userTheme = Supabase.instance.client.auth.currentUser?.userMetadata?['theme'];
      final effectiveTheme = savedTheme ?? userTheme ?? 'light';
      themeNotifier.value = effectiveTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;

      final savedLang = prefs.getString('app_language');
      final userLang = Supabase.instance.client.auth.currentUser?.userMetadata?['language'];
      languageNotifier.value = savedLang ?? userLang ?? 'en';
    } catch (e) {
      debugPrint("Error loading saved preferences: $e");
    }

    debugPrint("Starting App...");
    runApp(const MedIntelApp());
  } catch (e, stacktrace) {
    debugPrint("Initialization Error: $e");
    debugPrint(stacktrace.toString());
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text("Error during startup: $e")),
      ),
    ));
  }
}

class MedIntelApp extends StatefulWidget {
  const MedIntelApp({super.key});

  @override
  State<MedIntelApp> createState() => _MedIntelAppState();
}

class _MedIntelAppState extends State<MedIntelApp> {
  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        final userTheme = user.userMetadata?['theme'];
        if (userTheme != null) {
          final mode = userTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
          themeNotifier.value = mode;
        }
        final userLang = user.userMetadata?['language'];
        if (userLang != null) {
          languageNotifier.value = userLang;
        }
      }
    });
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('app_theme');
      final userTheme = Supabase.instance.client.auth.currentUser?.userMetadata?['theme'];
      final effectiveTheme = savedTheme ?? userTheme ?? 'light';
      themeNotifier.value = effectiveTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;

      final savedLang = prefs.getString('app_language');
      final userLang = Supabase.instance.client.auth.currentUser?.userMetadata?['language'];
      languageNotifier.value = savedLang ?? userLang ?? 'en';
    } catch (e) {
      debugPrint("Error loading saved preferences in initState: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F9D8A);
    const darkPrimaryColor = Color(0xFF1CC8B5);
    const accentColor = Color(0xFF1CC8B5);
    const lightBg = Color(0xFFF7FAFC);
    const darkBg = Color(0xFF0F172A);
    const darkCard = Color(0xFF1E293B);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'MedIntel',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            primaryColor: primaryColor,
            scaffoldBackgroundColor: lightBg,
            cardColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              primary: primaryColor,
              secondary: accentColor,
              surface: Colors.white,
              onSurface: const Color(0xFF0F172A),
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              ),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Colors.white,
              modalBackgroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: const BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: darkPrimaryColor,
            scaffoldBackgroundColor: darkBg,
            cardColor: darkCard,
            colorScheme: ColorScheme.fromSeed(
              seedColor: darkPrimaryColor,
              primary: darkPrimaryColor,
              secondary: primaryColor,
              surface: darkCard,
              onSurface: const Color(0xFFF8FAFC),
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: darkBg,
              foregroundColor: Color(0xFFF8FAFC),
              elevation: 0,
              centerTitle: false,
            ),
            cardTheme: CardThemeData(
              color: darkCard,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF334155), width: 1.5),
              ),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: darkCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: darkCard,
              modalBackgroundColor: darkCard,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: darkPrimaryColor,
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: darkPrimaryColor,
                side: const BorderSide(color: darkPrimaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
          initialRoute: Supabase.instance.client.auth.currentUser == null
              ? '/login'
              : '/navigation',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/navigation': (context) => const MainNavigation(),
            '/home': (context) => const MainNavigation(),
          },
        );
      },
    );
  }
}
