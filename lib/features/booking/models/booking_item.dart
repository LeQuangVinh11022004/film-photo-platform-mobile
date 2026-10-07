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
