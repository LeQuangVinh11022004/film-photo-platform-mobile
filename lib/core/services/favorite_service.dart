import 'package:flutter/foundation.dart';
import '../../features/booking/models/booking_item.dart';

/// Singleton service quản lý danh sách yêu thích (Studio & Phòng tối đã lưu).
/// Dùng ValueNotifier để các widget có thể lắng nghe thay đổi realtime.
class FavoriteService {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  FavoriteService._internal();

  /// Danh sách các BookingItem đã được yêu thích (không phân biệt loại).
  final ValueNotifier<List<BookingItem>> favorites =
      ValueNotifier<List<BookingItem>>([]);

  /// Kiểm tra item có đang được yêu thích không
  bool isFavorite(String id) {
    return favorites.value.any((e) => e.id == id);
  }

  /// Thêm vào danh sách yêu thích (nếu chưa có)
  void add(BookingItem item) {
    if (!isFavorite(item.id)) {
      item.isFavorite = true;
      favorites.value = [...favorites.value, item];
    }
  }

  /// Xóa khỏi danh sách yêu thích
  void remove(String id) {
    final updated = favorites.value.where((e) => e.id != id).toList();
    // Cập nhật flag trên item gốc nếu còn tham chiếu
    for (final item in favorites.value) {
      if (item.id == id) item.isFavorite = false;
    }
    favorites.value = updated;
  }

  /// Toggle: thêm nếu chưa có, xóa nếu đã có
  /// Trả về true nếu sau khi toggle item đang được yêu thích
  bool toggle(BookingItem item) {
    if (isFavorite(item.id)) {
      remove(item.id);
      item.isFavorite = false;
      return false;
    } else {
      add(item);
      item.isFavorite = true;
      return true;
    }
  }
}
