import 'package:film_photography_platform/features/booking/models/booking_api_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ResourceDetailDTO.parseStringList strips {}, [] and quotes across formats', () {
    expect(
      ResourceDetailDTO.parseStringList('["Đèn Profoto", "Điều hòa", "Wifi"]'),
      ['Đèn Profoto', 'Điều hòa', 'Wifi'],
    );

    expect(
      ResourceDetailDTO.parseStringList({
        'wifi': true,
        'air_conditioning': true,
        'parking': false,
        'items': ['Phông nền', 'Đèn liên tục'],
      }),
      ['Wifi', 'Air conditioning', 'Phông nền', 'Đèn liên tục'],
    );

    expect(
      ResourceDetailDTO.parseStringList(
        '{"enlargers": ["Leica", "Kaiser"], "safe_light": true}',
      ),
      ['Enlargers: Leica, Kaiser', 'Safe light'],
    );

    final dto = ResourceDetailDTO.fromJson({
      'amenities': {'items': ['Máy rọi', 'Hóa chất Kodak']},
      'supportedProcesses': '["B&W", "C-41"]',
      'operatingHours': {'open': '08:00', 'close': '21:00'},
    });

    expect(dto.amenitiesList, ['Máy rọi', 'Hóa chất Kodak']);
    expect(dto.supportedProcesses, 'B&W, C-41');
    expect(dto.operatingHours, '08:00 - 21:00');
  });
}
