import 'package:film_photography_platform/features/auth/presentation/login_screen.dart';
import 'package:film_photography_platform/features/auth/presentation/register_screen.dart';
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
}
