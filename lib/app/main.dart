import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';
import '../core/theme/app_theme.dart';
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

import '../features/expert/presentation/expert_navigation_screen.dart';
import '../features/expert/presentation/expert_application_screen.dart';

// Global notifier for Theme Mode
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const FilmPhotographyApp());
}

class FilmPhotographyApp extends StatelessWidget {
  const FilmPhotographyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, ThemeMode currentMode, child) {
        return ToastificationWrapper(
          child: MaterialApp(
            title: 'Film Photography Platform',
            debugShowCheckedModeBanner: false,
            themeMode: currentMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
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

            '/expert-workspace': (context) => const ExpertNavigationScreen(),
            '/expert-application': (context) => const ExpertApplicationScreen(),
          },
        ),
      );
      }
    );
  }
}
