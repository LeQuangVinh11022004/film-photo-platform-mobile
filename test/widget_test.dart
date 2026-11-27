import 'package:flutter_test/flutter_test.dart';
import 'package:film_photography_platform/app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Initial screen shows LoginScreen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FilmPhotographyApp());
    await tester.pumpAndSettle();

    // Verify that the login title exists on initial render.
    expect(find.text('Đăng nhập'), findsWidgets);
  });
}
