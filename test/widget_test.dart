import 'package:flutter_test/flutter_test.dart';
import 'package:film_photography_platform/app/main.dart';

void main() {
  testWidgets('Initial screen shows LoginScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FilmPhotographyApp());

    // Verify that the login title exists on initial render.
    expect(find.text('Đăng nhập'), findsWidgets);
  });
}
