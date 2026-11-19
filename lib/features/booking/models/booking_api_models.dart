import 'booking_item.dart';

class BookingResponseDTO {
  final String bookingId;
  final String photographerId;
  final String providerId;
  final String spaceId;
  final String? packageId;
  final String bookingDate; // YYYY-MM-DD
  final String startTime; // HH:mm:ss
  final String endTime; // HH:mm:ss
  final double totalAmount;
  final String status;
  final String qrCode;
  final String photographerName;
  final String providerName;
  final String spaceName;
  final String? packageName;
  final DateTime createdAt;
  final List<BookingEquipmentResponseDTO> equipment;

  BookingResponseDTO({
    required this.bookingId,
    required this.photographerId,
    required this.providerId,
    required this.spaceId,
    this.packageId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.totalAmount,
    required this.status,
    required this.qrCode,
    required this.photographerName,
    required this.providerName,
    required this.spaceName,
    this.packageName,
    required this.createdAt,
    required this.equipment,
  });

  factory BookingResponseDTO.fromJson(Map<String, dynamic> json) {
    return BookingResponseDTO(
      bookingId: json['bookingId'] ?? '',
      photographerId: json['photographerId'] ?? '',
      providerId: json['providerId'] ?? '',
      spaceId: json['spaceId'] ?? '',
      packageId: json['packageId'],
      bookingDate: json['bookingDate'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? '',
      qrCode: json['qrCode'] ?? '',
      photographerName: json['photographerName'] ?? '',
      providerName: json['providerName'] ?? '',
      spaceName: json['spaceName'] ?? '',
      packageName: json['packageName'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      equipment: (json['equipment'] as List<dynamic>?)
              ?.map((e) => BookingEquipmentResponseDTO.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class BookingEquipmentResponseDTO {
  final String equipmentId;
  final String name;
  final int quantity;
  final double unitPrice;

  BookingEquipmentResponseDTO({
    required this.equipmentId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  factory BookingEquipmentResponseDTO.fromJson(Map<String, dynamic> json) {
    return BookingEquipmentResponseDTO(
      equipmentId: json['equipmentId'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BookingCreateRequestDTO {
  final String availabilityId;
  final String? packageId;
  final List<String> equipmentIds;

  BookingCreateRequestDTO({
    required this.availabilityId,
    this.packageId,
    this.equipmentIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'availabilityId': availabilityId,
        'packageId': packageId,
        'equipmentIds': equipmentIds,
      };
}

class ProviderSpaceAvailabilityResponseDTO {
  final String availabilityId;
  final String spaceId;
  final String date;
  final String startTime;
  final String endTime;
  final double price;

  ProviderSpaceAvailabilityResponseDTO({
    required this.availabilityId,
    required this.spaceId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.price,
  });

  factory ProviderSpaceAvailabilityResponseDTO.fromJson(Map<String, dynamic> json) {
    return ProviderSpaceAvailabilityResponseDTO(
      availabilityId: json['availabilityId'] ?? '',
      spaceId: json['spaceId'] ?? '',
      date: json['date'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PagedResponseDTO<T> {
  final int totalCount;
  final int page;
  final int pageSize;
  final List<T> items;

  PagedResponseDTO({
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.items,
  });

  factory PagedResponseDTO.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return PagedResponseDTO(
      totalCount: json['totalCount'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => fromJsonT(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ResourceDetailDTO {
  final double lengthM;
  final double widthM;
  final double heightM;
  final String artisticStyle;
  final String supportedProcesses;
  final String lightingConditions;
  final String ventilationDetails;
  final String acousticDetails;
  final String amenities;
  final String operatingHours;
  final String usagePolicies;

  ResourceDetailDTO({
    this.lengthM = 0,
    this.widthM = 0,
    this.heightM = 0,
    this.artisticStyle = '',
    this.supportedProcesses = '',
    this.lightingConditions = '',
    this.ventilationDetails = '',
    this.acousticDetails = '',
    this.amenities = '',
    this.operatingHours = '',
    this.usagePolicies = '',
  });

  factory ResourceDetailDTO.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ResourceDetailDTO();

    String parseToString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is List) return value.map((e) => e.toString()).join(', ');
      return value.toString();
    }

    return ResourceDetailDTO(
      lengthM: (json['lengthM'] as num?)?.toDouble() ?? 0.0,
      widthM: (json['widthM'] as num?)?.toDouble() ?? 0.0,
      heightM: (json['heightM'] as num?)?.toDouble() ?? 0.0,
      artisticStyle: parseToString(json['artisticStyle']),
      supportedProcesses: parseToString(json['supportedProcesses']),
      lightingConditions: parseToString(json['lightingConditions']),
      ventilationDetails: parseToString(json['ventilationDetails']),
      acousticDetails: parseToString(json['acousticDetails']),
      amenities: parseToString(json['amenities']),
      operatingHours: parseToString(json['operatingHours']),
      usagePolicies: parseToString(json['usagePolicies']),
    );
  }
}

class ResourceImageDTO {
  final String imageUrl;
  final String imageType;

  ResourceImageDTO({required this.imageUrl, required this.imageType});

  factory ResourceImageDTO.fromJson(Map<String, dynamic> json) {
    return ResourceImageDTO(
      imageUrl: json['imageUrl'] ?? '',
      imageType: json['imageType'] ?? '',
    );
  }
}

class ResourceAvailableSlotDTO {
  final String availabilityId;
  final DateTime? startAt;
  final DateTime? endAt;
  final double price;

  ResourceAvailableSlotDTO({
    required this.availabilityId,
    this.startAt,
    this.endAt,
    required this.price,
  });

  factory ResourceAvailableSlotDTO.fromJson(Map<String, dynamic> json) {
    return ResourceAvailableSlotDTO(
      availabilityId: json['availabilityId'] ?? '',
      startAt: json['startAt'] != null ? DateTime.tryParse(json['startAt']) : null,
      endAt: json['endAt'] != null ? DateTime.tryParse(json['endAt']) : null,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ResourceItemResponseDTO {
  final String resourceId;
  final String resourceType; // e.g. Studio, Darkroom
  final String name;
  final String description;
  final String address;
  final int capacity;
  final double hourlyRate;
  final String providerName;
  final ResourceDetailDTO? details;
  final List<ResourceImageDTO> images;
  final List<ResourceAvailableSlotDTO> availableSlots;

  ResourceItemResponseDTO({
    required this.resourceId,
    required this.resourceType,
    required this.name,
    required this.description,
    required this.address,
    required this.capacity,
    required this.hourlyRate,
    required this.providerName,
    this.details,
    this.images = const [],
    this.availableSlots = const [],
  });

  factory ResourceItemResponseDTO.fromJson(Map<String, dynamic> json) {
    return ResourceItemResponseDTO(
      resourceId: json['resourceId'] ?? '',
      resourceType: json['resourceType'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      providerName: json['providerName'] ?? '',
      details: json['details'] != null ? ResourceDetailDTO.fromJson(json['details']) : null,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => ResourceImageDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      availableSlots: (json['availableSlots'] as List<dynamic>?)
              ?.map((e) => ResourceAvailableSlotDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Chuyển đổi sang BookingItem model dùng cho toàn bộ UI / Detail screen
  BookingItem toBookingItem() {
    final isDarkroom = resourceType.toLowerCase().contains('darkroom');
    final defaultImg = isDarkroom
        ? 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800&auto=format&fit=crop&q=80'
        : 'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=800&auto=format&fit=crop&q=80';

    final mainImage = images.isNotEmpty ? images.first.imageUrl : defaultImg;
    final allPreviews = images.map((img) => img.imageUrl).toList();
    if (allPreviews.isEmpty) {
      allPreviews.add(defaultImg);
    }

    // Amenities parsing from details
    List<String> parsedAmenities = [];
    if (details != null && details!.amenities.isNotEmpty) {
      parsedAmenities = details!.amenities
          .split(RegExp(r'[,;]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (parsedAmenities.isEmpty) {
      parsedAmenities = isDarkroom
          ? ['Máy rọi Enlarger', 'Hóa chất chuẩn', 'Đèn an toàn']
          : ['Đèn Studio chuyên dụng', 'Điều hòa', 'Wifi tốc độ cao'];
    }

    // Giá thuê: nếu hourlyRate = 0, fallback lấy price từ availableSlots đầu tiên
    double resolvedPrice = hourlyRate;
    if (resolvedPrice <= 0 && availableSlots.isNotEmpty) {
      resolvedPrice = availableSlots.first.price;
    }
    if (resolvedPrice <= 0) {
      resolvedPrice = isDarkroom ? 180000 : 250000;
    }

    return BookingItem(
      id: resourceId,
      name: name.isNotEmpty ? name : (isDarkroom ? 'Phòng tối tiêu chuẩn' : 'Studio tiêu chuẩn'),
      category: isDarkroom ? BookingCategory.darkroom : BookingCategory.studio,
      location: address.isNotEmpty ? address : 'Hồ Chí Minh, Việt Nam',
      pricePerHour: resolvedPrice,
      rating: 4.9,
      imageUrl: mainImage,
      description: description.isNotEmpty
          ? description
          : (details?.artisticStyle.isNotEmpty == true
              ? 'Phong cách: ${details!.artisticStyle}. ${details!.usagePolicies}'
              : 'Không gian chuyên nghiệp dành cho nghệ sĩ nhiếp ảnh film.'),
      amenities: parsedAmenities,
      previewImages: allPreviews,
      isFavorite: false,
      capacity: capacity,
      providerName: providerName,
      lengthM: details?.lengthM ?? 0,
      widthM: details?.widthM ?? 0,
      heightM: details?.heightM ?? 0,
      artisticStyle: details?.artisticStyle ?? '',
      supportedProcesses: details?.supportedProcesses ?? '',
      lightingConditions: details?.lightingConditions ?? '',
      ventilationDetails: details?.ventilationDetails ?? '',
      acousticDetails: details?.acousticDetails ?? '',
      operatingHours: details?.operatingHours ?? '',
      usagePolicies: details?.usagePolicies ?? '',
      availableSlots: availableSlots.map((s) => {
        'availabilityId': s.availabilityId,
        'startAt': s.startAt?.toIso8601String(),
        'endAt': s.endAt?.toIso8601String(),
        'price': s.price,
      }).toList(),
    );
  }
}
