import 'dart:convert';

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
  final double depositAmount;
  final String? depositDueAt;
  final String depositStatus;
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
    this.depositAmount = 0.0,
    this.depositDueAt,
    this.depositStatus = '',
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
      bookingId: json['bookingId']?.toString() ?? '',
      photographerId: json['photographerId']?.toString() ?? '',
      providerId: json['providerId']?.toString() ?? '',
      spaceId: json['spaceId']?.toString() ?? '',
      packageId: json['packageId']?.toString(),
      bookingDate: json['bookingDate']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0.0,
      depositDueAt: json['depositDueAt']?.toString(),
      depositStatus: json['depositStatus']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      qrCode: json['qrCode']?.toString() ?? '',
      photographerName: json['photographerName']?.toString() ?? '',
      providerName: json['providerName']?.toString() ?? '',
      spaceName: json['spaceName']?.toString() ?? '',
      packageName: json['packageName']?.toString(),
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      equipment: (json['equipment'] as List<dynamic>?)
          ?.map((e) =>
          BookingEquipmentResponseDTO.fromJson(e as Map<String, dynamic>))
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
      equipmentId: json['equipmentId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BookingCancellationResponseDTO {
  final String bookingId;
  final String status;
  final double refundAmount;
  final String refundStatus;
  final bool packageUseRestored;

  const BookingCancellationResponseDTO({
    required this.bookingId,
    required this.status,
    required this.refundAmount,
    required this.refundStatus,
    required this.packageUseRestored,
  });

  factory BookingCancellationResponseDTO.fromJson(Map<String, dynamic> json) {
    return BookingCancellationResponseDTO(
      bookingId: json['bookingId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      refundAmount: (json['refundAmount'] as num?)?.toDouble() ?? 0,
      refundStatus: json['refundStatus']?.toString() ?? '',
      packageUseRestored: json['packageUseRestored'] == true,
    );
  }
}

class PackageBookingSegmentRequestDTO {
  final int stepOrder;
  final String availabilityId;
  final List<String> equipmentIds;

  const PackageBookingSegmentRequestDTO({
    required this.stepOrder,
    required this.availabilityId,
    this.equipmentIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'stepOrder': stepOrder,
    'availabilityId': availabilityId,
    'equipmentIds': equipmentIds,
  };
}

class BookingCreateRequestDTO {
  final String? availabilityId;
  final String? subscriptionId;
  final List<String> equipmentIds;
  final List<PackageBookingSegmentRequestDTO> segments;

  BookingCreateRequestDTO({
    this.availabilityId,
    this.subscriptionId,
    this.equipmentIds = const [],
    this.segments = const [],
  });

  factory BookingCreateRequestDTO.fromSubscription({
    required String subscriptionId,
    required List<PackageBookingSegmentRequestDTO> segments,
  }) {
    return BookingCreateRequestDTO(
      subscriptionId: subscriptionId,
      segments: segments,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'equipmentIds': equipmentIds,
    };
    if (availabilityId != null && availabilityId!.isNotEmpty) {
      map['availabilityId'] = availabilityId;
    }
    if (subscriptionId != null && subscriptionId!.isNotEmpty) {
      map['subscriptionId'] = subscriptionId;
    }
    if (segments.isNotEmpty) {
      map['segments'] = segments.map((s) => s.toJson()).toList();
    }
    return map;
  }
}

class PhotographerEquipmentAvailabilityResponseDTO {
  final String availabilityId;
  final String equipmentId;
  final DateTime? startAt;
  final DateTime? endAt;
  final double price;

  PhotographerEquipmentAvailabilityResponseDTO({
    required this.availabilityId,
    required this.equipmentId,
    this.startAt,
    this.endAt,
    required this.price,
  });

  factory PhotographerEquipmentAvailabilityResponseDTO.fromJson(
      Map<String, dynamic> json) {
    return PhotographerEquipmentAvailabilityResponseDTO(
      availabilityId: json['availabilityId']?.toString() ?? '',
      equipmentId: json['equipmentId']?.toString() ?? '',
      startAt: json['startAt'] != null
          ? DateTime.tryParse(json['startAt'].toString())
          : null,
      endAt: json['endAt'] != null
          ? DateTime.tryParse(json['endAt'].toString())
          : null,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PhotographerEquipmentResponseDTO {
  final String equipmentId;
  final String spaceId;
  final String spaceType;
  final String? equipmentAvailabilityId;
  final String equipmentType;
  final String name;
  final String category;
  final String? variant;
  final String? description;
  final String? specificationsJson;
  final int quantityTotal;
  final double? rentalPrice;
  final double? priceForSelectedSlot;

  PhotographerEquipmentResponseDTO({
    required this.equipmentId,
    required this.spaceId,
    required this.spaceType,
    this.equipmentAvailabilityId,
    required this.equipmentType,
    required this.name,
    required this.category,
    this.variant,
    this.description,
    this.specificationsJson,
    required this.quantityTotal,
    this.rentalPrice,
    this.priceForSelectedSlot,
  });

  factory PhotographerEquipmentResponseDTO.fromJson(
      Map<String, dynamic> json) {
    return PhotographerEquipmentResponseDTO(
      equipmentId: json['equipmentId']?.toString() ?? '',
      spaceId: json['spaceId']?.toString() ?? '',
      spaceType: json['spaceType']?.toString() ?? '',
      equipmentAvailabilityId: json['equipmentAvailabilityId']?.toString(),
      equipmentType: json['equipmentType']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      variant: json['variant']?.toString(),
      description: json['description']?.toString(),
      specificationsJson: json['specificationsJson']?.toString(),
      quantityTotal: (json['quantityTotal'] as num?)?.toInt() ?? 1,
      rentalPrice: (json['rentalPrice'] as num?)?.toDouble(),
      priceForSelectedSlot:
          (json['priceForSelectedSlot'] as num?)?.toDouble(),
    );
  }
}

class PhotographerServicePackageItemResponseDTO {
  final String packageItemId;
  final String componentType; // STUDIO, DARKROOM, EQUIPMENT, CHEMICAL, SERVICE
  final String resourceId;
  final String resourceName;
  final int stepOrder;
  final int quantity;
  final int? includedDurationMinutes;
  final double? includedChemicalQuantity;
  final String? notes;

  PhotographerServicePackageItemResponseDTO({
    required this.packageItemId,
    required this.componentType,
    required this.resourceId,
    required this.resourceName,
    required this.stepOrder,
    required this.quantity,
    this.includedDurationMinutes,
    this.includedChemicalQuantity,
    this.notes,
  });

  factory PhotographerServicePackageItemResponseDTO.fromJson(
      Map<String, dynamic> json) {
    return PhotographerServicePackageItemResponseDTO(
      packageItemId: json['packageItemId']?.toString() ?? '',
      componentType: json['componentType']?.toString() ?? '',
      resourceId: json['resourceId']?.toString() ?? '',
      resourceName: json['resourceName']?.toString() ?? '',
      stepOrder: (json['stepOrder'] as num?)?.toInt() ?? 1,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      includedDurationMinutes:
          (json['includedDurationMinutes'] as num?)?.toInt(),
      includedChemicalQuantity:
          (json['includedChemicalQuantity'] as num?)?.toDouble(),
      notes: json['notes']?.toString(),
    );
  }
}

class PhotographerServicePackageResponseDTO {
  final String packageId;
  final String providerId;
  final String providerName;
  final String name;
  final String? description;
  final double price;
  final int usesPerMonth;
  final int validityMonths;
  final List<PhotographerServicePackageItemResponseDTO> items;

  PhotographerServicePackageResponseDTO({
    required this.packageId,
    required this.providerId,
    required this.providerName,
    required this.name,
    this.description,
    required this.price,
    required this.usesPerMonth,
    required this.validityMonths,
    this.items = const [],
  });

  factory PhotographerServicePackageResponseDTO.fromJson(
      Map<String, dynamic> json) {
    return PhotographerServicePackageResponseDTO(
      packageId: json['packageId']?.toString() ?? '',
      providerId: json['providerId']?.toString() ?? '',
      providerName: json['providerName']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      usesPerMonth: (json['usesPerMonth'] as num?)?.toInt() ?? 1,
      validityMonths: (json['validityMonths'] as num?)?.toInt() ?? 1,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => PhotographerServicePackageItemResponseDTO.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PhotographerPackageSubscriptionResponseDTO {
  final String subscriptionId;
  final String packageId;
  final String purchaseOrderId;
  final String packageName;
  final String providerName;
  final DateTime startsAt;
  final DateTime endsAt;
  final int usesPerMonth;
  final int usedThisPeriod;
  final int reservedThisPeriod;
  final int remainingUsesThisPeriod;
  final DateTime usagePeriodStart;
  final DateTime usagePeriodEnd;
  final String status;
  final List<PhotographerServicePackageItemResponseDTO> items;

  PhotographerPackageSubscriptionResponseDTO({
    required this.subscriptionId,
    required this.packageId,
    required this.purchaseOrderId,
    required this.packageName,
    required this.providerName,
    required this.startsAt,
    required this.endsAt,
    required this.usesPerMonth,
    required this.usedThisPeriod,
    required this.reservedThisPeriod,
    required this.remainingUsesThisPeriod,
    required this.usagePeriodStart,
    required this.usagePeriodEnd,
    required this.status,
    this.items = const [],
  });

  factory PhotographerPackageSubscriptionResponseDTO.fromJson(
      Map<String, dynamic> json) {
    return PhotographerPackageSubscriptionResponseDTO(
      subscriptionId: json['subscriptionId']?.toString() ?? '',
      packageId: json['packageId']?.toString() ?? '',
      purchaseOrderId: json['purchaseOrderId']?.toString() ?? '',
      packageName: json['packageName']?.toString() ?? '',
      providerName: json['providerName']?.toString() ?? '',
      startsAt: json['startsAt'] != null
          ? (DateTime.tryParse(json['startsAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      endsAt: json['endsAt'] != null
          ? (DateTime.tryParse(json['endsAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      usesPerMonth: (json['usesPerMonth'] as num?)?.toInt() ?? 0,
      usedThisPeriod: (json['usedThisPeriod'] as num?)?.toInt() ?? 0,
      reservedThisPeriod: (json['reservedThisPeriod'] as num?)?.toInt() ?? 0,
      remainingUsesThisPeriod:
          (json['remainingUsesThisPeriod'] as num?)?.toInt() ?? 0,
      usagePeriodStart: json['usagePeriodStart'] != null
          ? (DateTime.tryParse(json['usagePeriodStart'].toString()) ??
              DateTime.now())
          : DateTime.now(),
      usagePeriodEnd: json['usagePeriodEnd'] != null
          ? (DateTime.tryParse(json['usagePeriodEnd'].toString()) ??
              DateTime.now())
          : DateTime.now(),
      status: json['status']?.toString() ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => PhotographerServicePackageItemResponseDTO.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PackagePurchasePaymentResponseDTO {
  final String orderId;
  final String transactionId;
  final String packageId;
  final double amount;
  final String paymentMethod;
  final String status;
  final String paymentUrl;

  PackagePurchasePaymentResponseDTO({
    required this.orderId,
    required this.transactionId,
    required this.packageId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.paymentUrl,
  });

  factory PackagePurchasePaymentResponseDTO.fromJson(
      Map<String, dynamic> json) {
    return PackagePurchasePaymentResponseDTO(
      orderId: json['orderId']?.toString() ?? '',
      transactionId: json['transactionId']?.toString() ?? '',
      packageId: json['packageId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod']?.toString() ?? 'VNPAY',
      status: json['status']?.toString() ?? 'PENDING',
      paymentUrl: json['paymentUrl']?.toString() ?? '',
    );
  }
}

class ProviderSpaceAvailabilityResponseDTO {
  final String availabilityId;
  final String spaceId;
  final String date;
  final String startTime;
  final String endTime;
  final double? price;

  ProviderSpaceAvailabilityResponseDTO({
    required this.availabilityId,
    required this.spaceId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.price,
  });

  factory ProviderSpaceAvailabilityResponseDTO.fromJson(
      Map<String, dynamic> json) {
    final resolvedDate =
        json['availableDate'] ?? json['date'] ?? '';
    return ProviderSpaceAvailabilityResponseDTO(
      availabilityId: json['availabilityId']?.toString() ?? '',
      spaceId: json['spaceId']?.toString() ?? '',
      date: resolvedDate.toString(),
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble(),
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

  factory PagedResponseDTO.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJsonT,
      ) {
    final rawTotal = json['totalItems'] ?? json['totalCount'];
    return PagedResponseDTO(
      totalCount: (rawTotal as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
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
  final List<String> amenitiesList;
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
    this.amenitiesList = const [],
    this.operatingHours = '',
    this.usagePolicies = '',
  });

  static String _formatKeyLabel(String rawKey) {
    final cleaned = rawKey
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .trim();
    if (cleaned.isEmpty) return '';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  static String _stripBracesAndQuotes(String raw) {
    return raw
        .replaceAll(RegExp(r'^[\[\{\("\x27\s]+|[\]\}\)"\x27\s]+$'), '')
        .replaceAll(RegExp(r'[\[\]\{\}"]'), '')
        .trim();
  }

  static dynamic _tryDecodeJsonString(dynamic value) {
    if (value is! String) return value;
    final trimmed = value.trim();
    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      try {
        return jsonDecode(trimmed);
      } catch (_) {
        return value;
      }
    }
    return value;
  }

  /// Trích xuất danh sách tiện ích sạch (không bao giờ còn `{ }`, `[ ]`, `"`).
  static List<String> parseStringList(dynamic raw) {
    if (raw == null) return [];
    final decoded = _tryDecodeJsonString(raw);
    final result = <String>[];

    void addClean(String text) {
      final cleaned = _stripBracesAndQuotes(text);
      if (cleaned.isNotEmpty && !result.contains(cleaned)) {
        result.add(cleaned);
      }
    }

    if (decoded is List) {
      for (final item in decoded) {
        if (item == null) continue;
        if (item is String || item is num || item is bool) {
          addClean(item.toString());
        } else {
          for (final sub in parseStringList(item)) {
            addClean(sub);
          }
        }
      }
      return result;
    }

    if (decoded is Map) {
      const genericContainerKeys = {
        'items',
        'list',
        'amenities',
        'features',
        'equipment',
        'values',
        'name',
        'label',
        'title',
        'value',
      };
      for (final entry in decoded.entries) {
        final keyStr = entry.key.toString().trim();
        final lowerKey = keyStr.toLowerCase();
        final val = entry.value;
        if (val == null || val == false) continue;

        if (val == true) {
          addClean(_formatKeyLabel(keyStr));
        } else if (val is List) {
          final subItems = parseStringList(val);
          if (subItems.isEmpty) continue;
          if (genericContainerKeys.contains(lowerKey)) {
            for (final s in subItems) {
              addClean(s);
            }
          } else {
            addClean('${_formatKeyLabel(keyStr)}: ${subItems.join(', ')}');
          }
        } else if (val is Map) {
          final subItems = parseStringList(val);
          for (final s in subItems) {
            addClean(s);
          }
        } else {
          final valStr = _stripBracesAndQuotes(val.toString());
          if (valStr.isEmpty) continue;
          if (genericContainerKeys.contains(lowerKey)) {
            addClean(valStr);
          } else {
            addClean('${_formatKeyLabel(keyStr)}: $valStr');
          }
        }
      }
      return result;
    }

    final str = decoded.toString().trim();
    if (str.isEmpty) return [];
    for (final part in str.split(RegExp(r'[,;\n]'))) {
      addClean(part);
    }
    return result;
  }

  static String parseToCleanString(dynamic value) {
    if (value == null) return '';
    final decoded = _tryDecodeJsonString(value);
    if (decoded is String) {
      return _stripBracesAndQuotes(decoded);
    }
    final items = parseStringList(decoded);
    return items.join(', ');
  }

  static String formatOperatingHours(Object? value) {
    final decoded = _tryDecodeJsonString(value);
    if (decoded is Map) {
      final open = decoded['open'];
      final close = decoded['close'];
      if (open is String &&
          open.trim().isNotEmpty &&
          close is String &&
          close.trim().isNotEmpty) {
        return '${open.trim()} - ${close.trim()}';
      }
    }
    return value?.toString() ?? '';
  }

  factory ResourceDetailDTO.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ResourceDetailDTO();

    final parsedAmenities = parseStringList(json['amenities']);

    return ResourceDetailDTO(
      lengthM: (json['lengthM'] as num?)?.toDouble() ?? 0.0,
      widthM: (json['widthM'] as num?)?.toDouble() ?? 0.0,
      heightM: (json['heightM'] as num?)?.toDouble() ?? 0.0,
      artisticStyle: parseToCleanString(json['artisticStyle']),
      supportedProcesses: parseToCleanString(json['supportedProcesses']),
      lightingConditions: parseToCleanString(json['lightingConditions']),
      ventilationDetails: parseToCleanString(json['ventilationDetails']),
      acousticDetails: parseToCleanString(json['acousticDetails']),
      amenities: parsedAmenities.join(', '),
      amenitiesList: parsedAmenities,
      operatingHours: formatOperatingHours(json['operatingHours']),
      usagePolicies: parseToCleanString(json['usagePolicies']),
    );
  }
}

class ResourceImageDTO {
  final String imageUrl;
  final String imageType;

  ResourceImageDTO({required this.imageUrl, required this.imageType});

  factory ResourceImageDTO.fromJson(Map<String, dynamic> json) {
    return ResourceImageDTO(
      imageUrl: json['imageUrl']?.toString() ?? '',
      imageType: json['imageType']?.toString() ?? '',
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
      availabilityId: json['availabilityId']?.toString() ?? '',
      startAt:
      json['startAt'] != null ? DateTime.tryParse(json['startAt'].toString()) : null,
      endAt: json['endAt'] != null ? DateTime.tryParse(json['endAt'].toString()) : null,
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
      resourceId: json['resourceId']?.toString() ?? '',
      resourceType: json['resourceType']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      providerName: json['providerName']?.toString() ?? '',
      details: json['details'] != null
          ? ResourceDetailDTO.fromJson(json['details'] as Map<String, dynamic>)
          : null,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => ResourceImageDTO.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      availableSlots: (json['availableSlots'] as List<dynamic>?)
          ?.map((e) =>
          ResourceAvailableSlotDTO.fromJson(e as Map<String, dynamic>))
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

    // Amenities parsing from details (đã làm sạch hoàn toàn dấu {}, [], ")
    List<String> parsedAmenities = [];
    if (details != null) {
      if (details!.amenitiesList.isNotEmpty) {
        parsedAmenities = List<String>.from(details!.amenitiesList);
      } else if (details!.amenities.isNotEmpty) {
        parsedAmenities = ResourceDetailDTO.parseStringList(details!.amenities);
      }
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
      name: name.isNotEmpty
          ? name
          : (isDarkroom ? 'Phòng tối tiêu chuẩn' : 'Studio tiêu chuẩn'),
      category: isDarkroom ? BookingCategory.darkroom : BookingCategory.studio,
      location: address.isNotEmpty ? address : 'Hồ Chí Minh, Việt Nam',
      pricePerHour: resolvedPrice,
      rating: 0,
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
      availableSlots: availableSlots
          .map((s) => {
        'availabilityId': s.availabilityId,
        'startAt': s.startAt?.toIso8601String(),
        'endAt': s.endAt?.toIso8601String(),
        'price': s.price,
      })
          .toList(),
    );
  }
}

class DepositPaymentResponseDTO {
  final String transactionId;
  final String bookingId;
  final num amount;
  final String? depositDueAt;
  final String currency;
  final String paymentMethod;
  final String status;
  final String? paymentUrl;

  DepositPaymentResponseDTO({
    required this.transactionId,
    required this.bookingId,
    required this.amount,
    this.depositDueAt,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    this.paymentUrl,
  });

  factory DepositPaymentResponseDTO.fromJson(Map<String, dynamic> json) {
    return DepositPaymentResponseDTO(
      transactionId: json['transactionId']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      amount: json['amount'] as num? ?? 0,
      depositDueAt: json['depositDueAt']?.toString(),
      currency: json['currency']?.toString() ?? 'VND',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paymentUrl: json['paymentUrl']?.toString(),
    );
  }
}

class DarkroomChemicalResponseDTO {
  final String chemicalId;
  final String darkroomId;
  final String name;
  final String chemicalType;
  final String brand;
  final double stockQuantity;
  final String stockUnit;
  final double unitSellingPrice;
  final String? expiresOn;

  const DarkroomChemicalResponseDTO({
    required this.chemicalId,
    required this.darkroomId,
    required this.name,
    required this.chemicalType,
    required this.brand,
    required this.stockQuantity,
    required this.stockUnit,
    required this.unitSellingPrice,
    this.expiresOn,
  });

  factory DarkroomChemicalResponseDTO.fromJson(Map<String, dynamic> json) {
    return DarkroomChemicalResponseDTO(
      chemicalId: json['chemicalId']?.toString() ?? '',
      darkroomId: json['darkroomId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      chemicalType: json['chemicalType']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      stockQuantity: (json['stockQuantity'] as num?)?.toDouble() ?? 0,
      stockUnit: json['stockUnit']?.toString() ?? '',
      unitSellingPrice: (json['unitSellingPrice'] as num?)?.toDouble() ?? 0,
      expiresOn: json['expiresOn']?.toString(),
    );
  }
}