import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/main_navigation.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'services/notification_service.dart';

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

class MedIntelApp extends StatelessWidget {
  const MedIntelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedIntel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
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
  }
}
