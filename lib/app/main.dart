import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../features/ai_tools/presentation/ai_assistant_screen.dart';
import '../features/ai_tools/presentation/ai_restoration_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/booking/presentation/booking_checkin_screen.dart';
import '../features/booking/presentation/item_detail_screen.dart';
import '../features/booking/presentation/payment_screen.dart';
import '../features/booking/presentation/service_packages_screen.dart';
import '../features/booking/presentation/studio_comparison_screen.dart';
import '../features/home/presentation/main_navigation_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/profile/presentation/digital_collections_screen.dart';

// Global notifier for Theme Mode
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() {
  runApp(const FilmPhotographyApp());
}

class FilmPhotographyApp extends StatelessWidget {
  const FilmPhotographyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Film Photography Platform',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              surface: AppColors.background,
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: AppColors.textPrimary),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              surface: const Color(0xFF1E1E1E),
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: Colors.white),
            ),
          ),
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/reset-password': (context) => const ResetPasswordScreen(),
            '/home': (context) => const MainNavigationScreen(),
            '/detail': (context) => const ItemDetailScreen(),
            '/service-packages': (context) => const ServicePackagesScreen(),
            '/studio-comparison': (context) => const StudioComparisonScreen(),
            '/booking-checkin': (context) => const BookingCheckinScreen(),
            '/payment': (context) => const PaymentScreen(),
            '/ai-restoration': (context) => const AIRestorationScreen(),
            '/ai-assistant': (context) => const AIAssistantScreen(),
            '/digital-collections': (context) => const DigitalCollectionsScreen(),
            '/notifications': (context) => const NotificationsScreen(),
          },
        );
      }
    );
  }
}
