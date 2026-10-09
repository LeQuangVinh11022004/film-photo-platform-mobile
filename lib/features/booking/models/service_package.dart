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
  });

  static List<ServicePackage> samplePackages = [
    ServicePackage(
      id: 'PKG-01',
      name: 'Combo Chụp Film Chân Dung All-In-One',
      category: 'Gói Studio & Film',
      price: 850000,
      durationText: '4 giờ sử dụng',
      description: 'Gói combo trọn gói dành cho Nhiếp ảnh gia bao gồm phòng chụp Studio Vintage, mượn máy ảnh Leica/Hasselblad, 2 cuộn film Kodak Gold 200 và hỗ trợ tráng scan lấy liền.',
      includes: [
        '4 giờ phòng chụp Studio Vintage Quận 1',
        '2 cuộn Film Kodak Gold 200 chính hãng',
        'Thuê miễn phí 1 Body Leica M6 hoặc Canon AE-1',
        'Kỹ thuật viên hỗ trợ đánh đèn Profoto',
        'Voucher tráng & scan film cao cấp Noritsu',
      ],
      imageUrl: 'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=800&auto=format&fit=crop&q=80',
      isPopular: true,
    ),
    ServicePackage(
      id: 'PKG-02',
      name: 'Gói Tráng Rọi Film Phòng Tối Chuyên Nghiệp',
      category: 'Gói Phòng Tối & Hóa Chất',
      price: 520000,
      durationText: '3 giờ sử dụng',
      description: 'Dành cho các tín đồ yêu thích tự rọi film B&W/Color. Bao gồm phòng tối riêng biệt, máy rọi Enlarger Kaiser và bộ hóa chất Kodak D-76 / Rapid Fixer pha sẵn.',
      includes: [
        '3 giờ phòng tối khép kín tại Quận 3',
        'Sử dụng không giới hạn hóa chất Kodak D-76 & Rapid Fixer',
        'Sử dụng máy rọi Enlarger Kaiser B&W/Color',
        'Khay rửa, kẹp film, máy sấy phim tiêu chuẩn',
        'Tặng 5 tờ giấy ảnh rọi film Ilford Multigrade',
      ],
      imageUrl: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800&auto=format&fit=crop&q=80',
      isPopular: true,
    ),
    ServicePackage(
      id: 'PKG-03',
      name: 'Gói Trải Nghiệm Workshop Film Cho Người Mới',
      category: 'Workshop & Đào Tạo',
      price: 650000,
      durationText: 'Nửa ngày (09:00 - 13:00)',
      description: 'Khóa học thực hành 1:1 cùng Chuyên gia Film Lộc Master. Học lý thuyết đo sáng, thực hành chụp outdoor và tự tay tráng cuộn film đầu tiên trong đời.',
      includes: [
        '1 cuộn Film Kodak ColorPlus 200',
        'Mượn máy ảnh cơ film tự chọn',
        'Hướng dẫn thực hành 1:1 cùng Chuyên gia',
        'Tự tráng & scan file số gửi qua Email',
        'Cà phê & Bánh ngọt teabreak',
      ],
      imageUrl: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=800&auto=format&fit=crop&q=80',
      isPopular: false,
    ),
  ];
}
