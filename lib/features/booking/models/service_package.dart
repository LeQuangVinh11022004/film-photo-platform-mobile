import 'booking_api_models.dart';

class ServicePackage {
  final String id;
  final String name;
  final String category;
  final double price;
  final String durationText;
  final String description;
  final List<String> includes;
  final String imageUrl;
  final bool isPopular;
  final String providerName;
  final int usesPerMonth;
  final int validityMonths;
  final List<PhotographerServicePackageItemResponseDTO> rawItems;

  ServicePackage({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.durationText,
    required this.description,
    required this.includes,
    required this.imageUrl,
    this.isPopular = false,
    this.providerName = '',
    this.usesPerMonth = 1,
    this.validityMonths = 1,
    this.rawItems = const [],
  });

  factory ServicePackage.fromDto(PhotographerServicePackageResponseDTO dto) {
    final hasDarkroom = dto.items.any(
      (i) => i.componentType.toUpperCase() == 'DARKROOM',
    );
    final defaultImage = hasDarkroom
        ? 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800&auto=format&fit=crop&q=80'
        : 'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=800&auto=format&fit=crop&q=80';

    final includesList = dto.items.map((item) {
      final durationStr = item.includedDurationMinutes != null
          ? ' (${item.includedDurationMinutes} phút)'
          : '';
      final qtyStr = item.quantity > 1 ? ' x${item.quantity}' : '';
      return 'Bước ${item.stepOrder}: [${item.componentType}] ${item.resourceName}$qtyStr$durationStr';
    }).toList();

    return ServicePackage(
      id: dto.packageId,
      name: dto.name,
      category: dto.providerName.isNotEmpty
          ? dto.providerName
          : (hasDarkroom ? 'Gói Phòng Tối & Thiết Bị' : 'Gói Studio & Thiết Bị'),
      price: dto.price,
      durationText: '${dto.usesPerMonth} lượt/tháng • ${dto.validityMonths} tháng',
      description: (dto.description != null && dto.description!.isNotEmpty)
          ? dto.description!
          : 'Gói dịch vụ combo chính hãng từ ${dto.providerName}.',
      includes: includesList.isNotEmpty
          ? includesList
          : ['Sử dụng dịch vụ theo cấu hình gói (${dto.usesPerMonth} lượt/tháng)'],
      imageUrl: defaultImage,
      isPopular: dto.usesPerMonth >= 2,
      providerName: dto.providerName,
      usesPerMonth: dto.usesPerMonth,
      validityMonths: dto.validityMonths,
      rawItems: dto.items,
    );
  }
}
