import 'package:film_photography_platform/features/auth/presentation/login_screen.dart';
import 'package:film_photography_platform/features/auth/presentation/register_screen.dart';
import 'package:film_photography_platform/features/auth/presentation/forgot_password_screen.dart';
import 'package:film_photography_platform/features/auth/presentation/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('login uses username instead of email', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Nhập tên đăng nhập'), findsOneWidget);
    expect(find.text('Nhập địa chỉ Email'), findsNothing);
    await tester.enterText(find.byType(TextFormField).first, 'film@example.test');
    await tester.ensureVisible(find.text('Đăng nhập'));
    await tester.tap(find.text('Đăng nhập'));
    await tester.pump();
    expect(find.textContaining('Tên đăng nhập phải có 3-50 ký tự'), findsOneWidget);
  });

  testWidgets('registration asks for a username', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    expect(find.text('Tên đăng nhập'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('unsupported password recovery does not report success', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));
    await tester.ensureVisible(find.text('Gửi mã xác minh'));
    await tester.tap(find.text('Gửi mã xác minh'));
    await tester.pump();
    expect(find.textContaining('chưa được hỗ trợ'), findsWidgets);
    expect(find.byType(ResetPasswordScreen), findsNothing);
  });

  testWidgets('unsupported Google login does not navigate home', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Google'));
    await tester.tap(find.byTooltip('Google'));
    await tester.pump();
    expect(find.text('Đăng nhập Google chưa được hỗ trợ.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
