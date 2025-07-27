import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/logo_splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/activity_preferences_screen.dart';
import 'screens/onboarding/photo_upload_screen.dart';
import 'screens/home/main_navigation_screen.dart';
import 'screens/map/workout_map_screen.dart';

void main() {
  runApp(const AGoodFitApp());
}

class AGoodFitApp extends StatelessWidget {
  const AGoodFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A Good Fit',
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/logo-splash': (context) => const LogoSplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/activity-preferences': (context) => const ActivityPreferencesScreen(),
        '/photo-upload': (context) => const PhotoUploadScreen(),
        '/home': (context) => const MainNavigationScreen(),
        '/map': (context) => const WorkoutMapScreen(),
      },
    );
  }
}