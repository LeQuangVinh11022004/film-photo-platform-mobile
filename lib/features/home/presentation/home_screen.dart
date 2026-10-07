import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../booking/models/booking_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentLocation = 'Hồ Chí Minh, Việt Nam';
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter Modal State
  double _maxPriceFilter = 500000;
  double _minRatingFilter = 0.0;
  String _sortBy = 'default'; // 'default', 'price_asc', 'price_desc', 'rating_desc'

  final List<String> _locations = [
    'Hồ Chí Minh, Việt Nam',
    'Hà Nội, Việt Nam',
    'Đà Nẵng, Việt Nam',
    'Cần Thơ, Việt Nam',
  ];

  final List<String> _categories = [
    'Tất cả',
    '📸 Studio',
    '🎞️ Phòng tối',
    '🎥 Thiết bị',
  ];

  final List<Map<String, String>> _notifications = [
    {
      'title': 'Lịch đặt đã được xác nhận!',
      'body': 'Vintage Film Studio Saigon đã xác nhận lịch đặt của bạn vào ngày mai 09:00.',
      'time': '5 phút trước',
    },
    {
      'title': 'Bài viết mới từ Chuyên gia',
      'body': 'Master Lộc Film vừa chia sẻ bài viết "Kỹ thuật tráng film Kodak Tri-X 400".',
      'time': '1 giờ trước',
    },
    {
      'title': 'Ưu đãi Phòng Tối 20%',
      'body': 'Nhập mã ANALOG20 để nhận ưu đãi 20% khi đặt Silver Halide Darkroom.',
      'time': '3 giờ trước',
    },
  ];

  List<BookingItem> get _filteredItems {
    List<BookingItem> list = List.from(BookingItem.sampleItems);

    // Filter by Category
    if (_selectedCategoryIndex == 1) {
      list = list.where((e) => e.category == BookingCategory.studio).toList();
    } else if (_selectedCategoryIndex == 2) {
      list = list.where((e) => e.category == BookingCategory.darkroom).toList();
    } else if (_selectedCategoryIndex == 3) {
      list = list.where((e) => e.category == BookingCategory.equipment).toList();
    }

    // Filter by Max Price & Min Rating
    list = list.where((e) => e.pricePerHour <= _maxPriceFilter && e.rating >= _minRatingFilter).toList();

    // Filter by Search Query
    if (_searchQuery.isNotEmpty) {
      list = list.where((e) =>
          e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.location.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Sorting
    if (_sortBy == 'price_asc') {
      list.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
    } else if (_sortBy == 'price_desc') {
      list.sort((a, b) => b.pricePerHour.compareTo(a.pricePerHour));
    } else if (_sortBy == 'rating_desc') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return list;
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bộ Lọc Tìm Kiếm Nâng Cao',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _maxPriceFilter = 500000;
                          _minRatingFilter = 0.0;
                          _sortBy = 'default';
                        });
                        setState(() {});
                      },
                      child: const Text('Đặt lại', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Price Filter
                Text(
                  'Giá tối đa: ${_maxPriceFilter.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ / giờ',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Slider(
                  value: _maxPriceFilter,
                  min: 100000,
                  max: 500000,
                  divisions: 8,
                  activeColor: AppColors.primary,
                  label: '${_maxPriceFilter.toInt()}đ',
                  onChanged: (val) {
                    setModalState(() {
                      _maxPriceFilter = val;
                    });
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),

                // Rating Filter
                const Text('Đánh giá tối thiểu:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildRatingChip('Tất cả', 0.0, setModalState),
                    const SizedBox(width: 8),
                    _buildRatingChip('4.5+ ⭐', 4.5, setModalState),
                    const SizedBox(width: 8),
                    _buildRatingChip('4.8+ ⭐', 4.8, setModalState),
                  ],
                ),
                const SizedBox(height: 16),

                // Sort By Filter
                const Text('Sắp xếp theo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSortChip('Mặc định', 'default', setModalState),
                    _buildSortChip('Giá thấp đến cao', 'price_asc', setModalState),
                    _buildSortChip('Giá cao đến thấp', 'price_desc', setModalState),
                    _buildSortChip('Đánh giá cao nhất', 'rating_desc', setModalState),
                  ],
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Áp Dụng (${_filteredItems.length} Kết quả)',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingChip(String label, double rating, StateSetter setModalState) {
    final isSelected = _minRatingFilter == rating;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.inputFill,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setModalState(() {
            _minRatingFilter = rating;
          });
          setState(() {});
        }
      },
    );
  }

  Widget _buildSortChip(String label, String value, StateSetter setModalState) {
    final isSelected = _sortBy == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.inputFill,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setModalState(() {
            _sortBy = value;
          });
          setState(() {});
        }
      },
    );
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chọn Tỉnh / Thành Phố',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ..._locations.map((loc) => ListTile(
                  leading: Icon(
                    Icons.location_on_rounded,
                    color: _currentLocation == loc ? AppColors.primary : AppColors.textSecondary,
                  ),
                  title: Text(
                    loc,
                    style: TextStyle(
                      fontWeight: _currentLocation == loc ? FontWeight.bold : FontWeight.normal,
                      color: _currentLocation == loc ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  trailing: _currentLocation == loc
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _currentLocation = loc;
                    });
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Thông Báo Mới',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Đánh dấu đã đọc',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _notifications.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _notifications[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title']!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['body']!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['time']!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Location Bar & Notifications Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _showLocationPicker,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vị trí hiện tại',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _currentLocation,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textPrimary,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Notification Bell Button
                    GestureDetector(
                      onTap: _showNotifications,
                      child: Stack(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.inputFill,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: AppColors.textPrimary,
                              size: 24,
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 12,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar Input & Filter Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim();
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Tìm kiếm Studio, Phòng tối, Thiết bị...',
                            hintStyle: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _showFilterModal,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Category Chips Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedCategoryIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryIndex = index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.inputFill,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Text(
                              _categories[index],
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Section 1: Near Location Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Gần vị trí của bạn (${_filteredItems.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryIndex = 0;
                          _searchController.clear();
                          _searchQuery = '';
                          _maxPriceFilter = 500000;
                          _minRatingFilter = 0.0;
                          _sortBy = 'default';
                        });
                      },
                      child: const Text(
                        'Xóa bộ lọc',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Section 1 Horizontal Cards List
            SliverToBoxAdapter(
              child: _filteredItems.isEmpty
                  ? Container(
                      height: 120,
                      alignment: Alignment.center,
                      child: const Text('Không tìm thấy kết quả phù hợp'),
                    )
                  : SizedBox(
                      height: 260,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return _buildNearCard(context, item);
                        },
                      ),
                    ),
            ),

            // Section 2: Popular Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Phổ biến & Được yêu thích',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Tất cả',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Section 2 Vertical List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              sliver: _filteredItems.isEmpty
                  ? const SliverToBoxAdapter(child: SizedBox())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _filteredItems[index];
                          return _buildPopularCard(context, item);
                        },
                        childCount: _filteredItems.length,
                      ),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildNearCard(BuildContext context, BookingItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/detail', arguments: item);
      },
      child: Container(
        width: 230,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SafeNetworkImage(
                  url: item.imageUrl,
                  height: 135,
                  width: double.infinity,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        item.isFavorite = !item.isFavorite;
                      });
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: item.isFavorite ? Colors.red : AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 2),
                          Text(
                            item.rating.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${item.pricePerHour.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const Text(
                        ' / giờ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularCard(BuildContext context, BookingItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/detail', arguments: item);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            SafeNetworkImage(
              url: item.imageUrl,
              width: 80,
              height: 80,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 2),
                          Text(
                            item.rating.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.pricePerHour.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ / giờ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
