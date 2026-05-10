import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  runApp(const ArdhiApp());
}

class ArdhiApp extends StatelessWidget {
  const ArdhiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARDHI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Once the user has completed onboarding, hot reload (or any rebuild)
      // skips the onboarding flow and resumes on the recommendations screen.
      home: const OnboardingScreen(),
    );
  }
}
