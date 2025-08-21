import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/fitness_provider.dart';
import 'providers/routes_provider.dart';
import 'providers/goals_provider.dart';
import 'providers/achievements_provider.dart';
import 'providers/personal_records_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'services/api_service.dart';
import 'services/local_storage_service.dart';
import 'screens/splash_screen.dart';
import 'screens/logo_splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/activity_preferences_screen.dart';
import 'screens/onboarding/photo_upload_screen.dart';
import 'screens/home/main_navigation_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/map/workout_map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();
  runApp(const AGoodFitApp());
}

class AGoodFitApp extends StatelessWidget {
  const AGoodFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (context) => ApiService()..init()),
        ChangeNotifierProvider(create: (context) => AuthProvider()..init()),
        ChangeNotifierProxyProvider<ApiService, FitnessProvider>(
          create: (context) => FitnessProvider(),
          update: (context, apiService, previous) => previous ?? FitnessProvider(),
        ),
        ChangeNotifierProxyProvider<ApiService, RoutesProvider>(
          create: (context) => RoutesProvider(apiService: context.read<ApiService>()),
          update: (context, apiService, previous) => previous ?? RoutesProvider(apiService: apiService),
        ),
        ChangeNotifierProxyProvider<ApiService, GoalsProvider>(
          create: (context) => GoalsProvider(apiService: context.read<ApiService>()),
          update: (context, apiService, previous) => previous ?? GoalsProvider(apiService: apiService),
        ),
        ChangeNotifierProxyProvider<ApiService, AchievementsProvider>(
          create: (context) => AchievementsProvider(apiService: context.read<ApiService>()),
          update: (context, apiService, previous) => previous ?? AchievementsProvider(apiService: apiService),
        ),
        ChangeNotifierProxyProvider<ApiService, PersonalRecordsProvider>(
          create: (context) => PersonalRecordsProvider(apiService: context.read<ApiService>()),
          update: (context, apiService, previous) => previous ?? PersonalRecordsProvider(apiService: apiService),
        ),
        ChangeNotifierProxyProvider<ApiService, LeaderboardProvider>(
          create: (context) => LeaderboardProvider(apiService: context.read<ApiService>()),
          update: (context, apiService, previous) => previous ?? LeaderboardProvider(apiService: apiService),
        ),
      ],
      child: MaterialApp(
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
          '/edit-profile': (context) => const EditProfileScreen(),
          '/map': (context) => const WorkoutMapScreen(),
        },
      ),
    );
  }
}