import 'package:film_photography_platform/features/booking/models/booking_api_models.dart';
import 'package:film_photography_platform/features/booking/models/booking_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('both resource parsing paths display opening and closing times', () {
    final json = <String, dynamic>{
      'details': {
        'operatingHours': {'open': '08:00', 'close': '21:00'},
      },
    };

    expect(BookingItem.fromJson(json).operatingHours, '08:00 - 21:00');
    expect(
      ResourceItemResponseDTO.fromJson(json).toBookingItem().operatingHours,
      '08:00 - 21:00',
    );
  });

  test('existing text and incomplete hours are preserved', () {
    expect(
      ResourceDetailDTO.fromJson({'operatingHours': 'Theo lịch hẹn'})
          .operatingHours,
      'Theo lịch hẹn',
    );
    expect(
      ResourceDetailDTO.fromJson({
        'operatingHours': {'open': '08:00'},
      }).operatingHours,
      '{open: 08:00}',
    );
    expect(ResourceDetailDTO.fromJson({}).operatingHours, isEmpty);
  });
}
