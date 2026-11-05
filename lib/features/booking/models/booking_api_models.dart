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
