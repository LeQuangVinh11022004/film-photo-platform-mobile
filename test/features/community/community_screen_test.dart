import 'package:film_photography_platform/features/auth/models/auth_models.dart';
import 'package:film_photography_platform/features/auth/services/auth_service.dart';
import 'package:film_photography_platform/features/community/presentation/community_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final role in ['PHOTOGRAPHER', 'EXPERT']) {
    testWidgets('$role can open the community post form', (tester) async {
      AuthService().currentUser = UserDTO(
        userId: 'user-id',
        fullName: 'User',
        username: 'film_user',
        email: 'film@example.test',
        role: role,
        status: 'Active',
      );
      await tester.pumpWidget(const MaterialApp(home: CommunityScreen()));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Đăng bài chia sẻ cộng đồng'), findsOneWidget);
      expect(find.byTooltip('Tạo bài viết chuyên gia (Article)'), findsNothing);
      expect(find.text('Không thể tải bài đăng. Nhấn để thử lại.'), findsOneWidget);
      await tester.tap(find.byTooltip('Đăng bài chia sẻ cộng đồng'));
      await tester.pumpAndSettle();
      expect(find.text('Đăng Bài Chia Sẻ Cộng Đồng'), findsOneWidget);
      AuthService().currentUser = null;
    });
  }
}
