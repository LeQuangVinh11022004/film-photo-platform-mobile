import 'booking_api_models.dart';

enum BookingCategory { studio, darkroom, equipment }

class BookingItem {
  final String id;
  final String name;
  final BookingCategory category;
  final String location;
  final double pricePerHour;
  final double rating;
  final String imageUrl;
  final String description;
  final List<String> amenities;
  final List<String> previewImages;
  bool isFavorite;

  // Chi tiết kỹ thuật & tiện ích từ API
  final int capacity;
  final String providerName;
  final double lengthM;
  final double widthM;
  final double heightM;
  final String artisticStyle;
  final String supportedProcesses;
  final String lightingConditions;
  final String ventilationDetails;
  final String acousticDetails;
  final String operatingHours;
  final String usagePolicies;
  final List<Map<String, dynamic>> availableSlots;

  BookingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.pricePerHour,
    required this.rating,
    required this.imageUrl,
    required this.description,
    required this.amenities,
    required this.previewImages,
    this.isFavorite = false,
    this.capacity = 1,
    this.providerName = '',
    this.lengthM = 0,
    this.widthM = 0,
    this.heightM = 0,
    this.artisticStyle = '',
    this.supportedProcesses = '',
    this.lightingConditions = '',
    this.ventilationDetails = '',
    this.acousticDetails = '',
    this.operatingHours = '',
    this.usagePolicies = '',
    this.availableSlots = const [],
  });

  String get categoryName {
    switch (category) {
      case BookingCategory.studio:
        return 'Phòng chụp Studio';
      case BookingCategory.darkroom:
        return 'Phòng tối (Darkroom)';
      case BookingCategory.equipment:
        return 'Trang thiết bị';
    }
  }

  /// Factory parse trực tiếp từ JSON API (GET /api/photographer/studios hoặc darkrooms)
  factory BookingItem.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['resourceType'] ?? '').toString().toLowerCase();
    final isDarkroom = typeStr.contains('darkroom');

    final defaultImg = isDarkroom
        ? 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800&auto=format&fit=crop&q=80'
        : 'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=800&auto=format&fit=crop&q=80';

    final imagesList = (json['images'] as List<dynamic>?) ?? [];
    String mainImage = defaultImg;
    List<String> previews = [];

    if (imagesList.isNotEmpty) {
      for (var img in imagesList) {
        if (img is Map<String, dynamic> && img['imageUrl'] != null && img['imageUrl'].toString().isNotEmpty) {
          previews.add(img['imageUrl'].toString());
        }
      }
      if (previews.isNotEmpty) {
        mainImage = previews.first;
      }
    }

    if (previews.isEmpty) {
      previews.add(defaultImg);
    }

    // Amenities parsing từ details
    List<String> parsedAmenities = [];
    final details = json['details'] as Map<String, dynamic>?;
    if (details != null && details['amenities'] != null) {
      final aVal = details['amenities'];
      if (aVal is List) {
        parsedAmenities = aVal.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      } else {
        final aStr = aVal.toString();
        if (aStr.isNotEmpty) {
          parsedAmenities = aStr.split(RegExp(r'[,;]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
      }
    }

    if (parsedAmenities.isEmpty) {
      parsedAmenities = isDarkroom
          ? ['Máy rọi Enlarger', 'Hóa chất chuẩn', 'Đèn an toàn']
          : ['Đèn Studio chuyên dụng', 'Điều hòa', 'Wifi tốc độ cao'];
    }

    // Available slots parsing
    final slotsList = (json['availableSlots'] as List<dynamic>?) ?? [];
    double calculatedHourlyRate = (json['hourlyRate'] as num?)?.toDouble() ?? 0.0;
    if (calculatedHourlyRate == 0 && slotsList.isNotEmpty) {
      final firstSlot = slotsList.first;
      if (firstSlot is Map<String, dynamic> && firstSlot['price'] != null) {
        calculatedHourlyRate = (firstSlot['price'] as num).toDouble();
      }
    }

    final String address = json['address'] ?? '';
    final String name = json['name'] ?? '';
    final String description = json['description'] ?? '';

    return BookingItem(
      id: json['resourceId'] ?? '',
      name: name.isNotEmpty ? name : (isDarkroom ? 'Phòng tối Film' : 'Studio Chụp Ảnh'),
      category: isDarkroom ? BookingCategory.darkroom : BookingCategory.studio,
      location: address.isNotEmpty ? address : 'Hồ Chí Minh, Việt Nam',
      pricePerHour: calculatedHourlyRate > 0 ? calculatedHourlyRate : (isDarkroom ? 180000 : 250000),
      rating: 4.9,
      imageUrl: mainImage,
      description: description.isNotEmpty
          ? description
          : (details != null && details['artisticStyle'] != null && details['artisticStyle'].toString().isNotEmpty
              ? 'Phong cách: ${details['artisticStyle']}. ${details['usagePolicies'] ?? ''}'
              : 'Không gian chuyên nghiệp dành cho nghệ sĩ nhiếp ảnh film.'),
      amenities: parsedAmenities,
      previewImages: previews,
      isFavorite: false,
      capacity: (json['capacity'] as num?)?.toInt() ?? 1,
      providerName: json['providerName'] ?? '',
      lengthM: (details?['lengthM'] as num?)?.toDouble() ?? 0,
      widthM: (details?['widthM'] as num?)?.toDouble() ?? 0,
      heightM: (details?['heightM'] as num?)?.toDouble() ?? 0,
      artisticStyle: details?['artisticStyle']?.toString() ?? '',
      supportedProcesses: details?['supportedProcesses']?.toString() ?? '',
      lightingConditions: details?['lightingConditions']?.toString() ?? '',
      ventilationDetails: details?['ventilationDetails']?.toString() ?? '',
      acousticDetails: details?['acousticDetails']?.toString() ?? '',
      operatingHours: ResourceDetailDTO.formatOperatingHours(
        details?['operatingHours'],
      ),
      usagePolicies: details?['usagePolicies']?.toString() ?? '',
      availableSlots: slotsList.whereType<Map<String, dynamic>>().toList(),
    );
  }

  /// Chuyển thiết bị của một Studio/Darkroom (GET /api/photographer/spaces/{id}/equipment) thành BookingItem
  factory BookingItem.fromEquipmentDto(
    PhotographerEquipmentResponseDTO dto, {
    required String spaceName,
  }) {
    final price = dto.priceForSelectedSlot ?? dto.rentalPrice ?? 0;
    final description = dto.description?.trim() ?? '';
    final variant = dto.variant?.trim() ?? '';

    return BookingItem(
      id: dto.equipmentId,
      name: dto.name.isNotEmpty ? dto.name : 'Thiết bị film',
      category: BookingCategory.equipment,
      location: spaceName.isNotEmpty ? 'Thuộc: $spaceName' : 'Thiết bị cho thuê',
      pricePerHour: price,
      rating: 4.9,
      imageUrl:
          'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=800&auto=format&fit=crop&q=80',
      description: description.isNotEmpty
          ? description
          : 'Thiết bị ${dto.category} cho thuê${variant.isNotEmpty ? ' - $variant' : ''}.',
      amenities: [
        if (dto.category.isNotEmpty) dto.category,
        if (variant.isNotEmpty) variant,
        'Số lượng: ${dto.quantityTotal}',
      ],
      previewImages: const [
        'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=400&auto=format&fit=crop&q=80',
      ],
    );
  }

  /// Danh sách item mẫu dự phòng (fallback khi chưa khởi động server Backend hoặc offline)
  static List<BookingItem> sampleItems = [
    BookingItem(
      id: '1',
      name: 'Vintage Film Studio Saigon',
      category: BookingCategory.studio,
      location: 'Quận 1, TP. Hồ Chí Minh',
      pricePerHour: 250000,
      rating: 4.9,
      imageUrl: 'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=800&auto=format&fit=crop&q=80',
      description: 'Phòng chụp phong cách Vintage cổ điển với nguồn ánh sáng tự nhiên tuyệt đẹp, trang bị sẵn phông nền màu film, đèn studio Profoto chuyên nghiệp và góc decor retro độc đáo.',
      amenities: ['Đèn Profoto', 'Wifi tốc độ cao', 'Điều hòa', 'Phòng thay đồ', 'Đồ uống miễn phí'],
      previewImages: [
        'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=400&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=400&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=400&auto=format&fit=crop&q=80',
      ],
      isFavorite: true,
    ),
    BookingItem(
      id: '2',
      name: 'Silver Halide Darkroom Studio',
      category: BookingCategory.darkroom,
      location: 'Quận 3, TP. Hồ Chí Minh',
      pricePerHour: 180000,
      rating: 4.8,
      imageUrl: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800&auto=format&fit=crop&q=80',
      description: 'Phòng tối tự rọi film đầy đủ hoá chất Kodak D-76, máy rọi Enlarger Leica/Kaiser, khay rửa, phòng sấy film chuyên dụng và đèn an toàn tiêu chuẩn.',
      amenities: ['Máy rọi Enlarger', 'Hóa chất Kodak', 'Máy sấy film', 'Đèn đỏ an toàn', 'Găng tay & Kẹp film'],
      previewImages: [
        'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=400&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=400&auto=format&fit=crop&q=80',
      ],
      isFavorite: false,
    ),
    BookingItem(
      id: '3',
      name: 'Bộ Máy Leica M6 + Lens 35mm f/2',
      category: BookingCategory.equipment,
      location: 'Quận Bình Thạnh, TP. HCM',
      pricePerHour: 120000,
      rating: 5.0,
      imageUrl: 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=800&auto=format&fit=crop&q=80',
      description: 'Cho thuê máy ảnh Film Rangefinder Leica M6 huyền thoại kèm ống kính Summicron 35mm f/2. Máy hoạt động hoàn hảo, đo sáng chuẩn xác.',
      amenities: ['Bao da bảo vệ', 'Dây đeo da', 'Pin đo sáng đầy', 'Kèm 1 cuộn Kodak Gold 200'],
      previewImages: [
        'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=400&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1510127034890-ba27508e9f1c?w=400&auto=format&fit=crop&q=80',
      ],
      isFavorite: true,
    ),
    BookingItem(
      id: '4',
      name: 'Analog Light & Shadow Darkroom',
      category: BookingCategory.darkroom,
      location: 'Quận Phú Nhuận, TP. HCM',
      pricePerHour: 200000,
      rating: 4.9,
      imageUrl: 'https://images.unsplash.com/photo-1510127034890-ba27508e9f1c?w=800&auto=format&fit=crop&q=80',
      description: 'Phòng tối tráng rọi phim khổ Medium Format (120) và 35mm. Có hướng dẫn viên hỗ trợ cho người mới bắt đầu.',
      amenities: ['Hóa chất ILFORD', 'Máy scan Noritsu', 'Trà & Cà phê miễn phí', 'Wifi cao cấp'],
      previewImages: [
        'https://images.unsplash.com/photo-1510127034890-ba27508e9f1c?w=400&auto=format&fit=crop&q=80',
      ],
      isFavorite: false,
    ),
  ];
}
