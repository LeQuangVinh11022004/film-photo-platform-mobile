import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../booking/models/booking_item.dart';
import '../../notifications/models/notification_item.dart';

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
  String _sortBy = 'default';

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

  List<BookingItem> get _filteredItems {
    List<BookingItem> list = List.from(BookingItem.sampleItems);

    if (_selectedCategoryIndex == 1) {
      list = list.where((e) => e.category == BookingCategory.studio).toList();
    } else if (_selectedCategoryIndex == 2) {
      list = list.where((e) => e.category == BookingCategory.darkroom).toList();
    } else if (_selectedCategoryIndex == 3) {
      list = list.where((e) => e.category == BookingCategory.equipment).toList();
    }

    list = list.where((e) => e.pricePerHour <= _maxPriceFilter && e.rating >= _minRatingFilter).toList();

    if (_searchQuery.isNotEmpty) {
      list = list.where((e) =>
          e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.location.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

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
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bộ Lọc Tìm Kiếm Nâng Cao',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textColor),
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
                      child: Text('Đặt lại', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                Text(
                  'Giá tối đa: ${_maxPriceFilter.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ / giờ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                SizedBox(height: 14),

                Text('Đánh giá tối thiểu:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 8),
                Row(
                  children: [
                    _buildRatingChip('Tất cả', 0.0, setModalState),
                    SizedBox(width: 8),
                    _buildRatingChip('4.5+ ⭐', 4.5, setModalState),
                    SizedBox(width: 8),
                    _buildRatingChip('4.8+ ⭐', 4.8, setModalState),
                  ],
                ),
                SizedBox(height: 16),

                Text('Sắp xếp theo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 8),
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
                SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Áp Dụng (${_filteredItems.length} Kết quả)',
                    style: TextStyle(color: context.cardColor, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                SizedBox(height: 12),
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
      backgroundColor: context.inputColor,
      labelStyle: TextStyle(
        color: isSelected ? context.cardColor : context.textColor,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setModalState(() => _minRatingFilter = rating);
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
      backgroundColor: context.inputColor,
      labelStyle: TextStyle(
        color: isSelected ? context.cardColor : context.textColor,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setModalState(() => _sortBy = value);
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
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            SizedBox(height: 16),
            Text('Chọn Tỉnh / Thành Phố', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textColor)),
            SizedBox(height: 16),
            ..._locations.map((loc) => ListTile(
                  leading: Icon(Icons.location_on_rounded, color: _currentLocation == loc ? AppColors.primary : context.textSecColor),
                  title: Text(loc, style: TextStyle(fontWeight: _currentLocation == loc ? FontWeight.bold : FontWeight.normal, color: _currentLocation == loc ? AppColors.primary : context.textColor)),
                  trailing: _currentLocation == loc ? Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                  onTap: () {
                    setState(() => _currentLocation = loc);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadNotifs = NotificationItem.sampleNotifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Location Bar & Notifications Button
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _showLocationPicker,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vị trí hiện tại', style: TextStyle(fontSize: 12, color: context.textSecColor, fontWeight: FontWeight.w500)),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                              SizedBox(width: 4),
                              Text(_currentLocation, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textColor)),
                              Icon(Icons.keyboard_arrow_down_rounded, color: context.textColor, size: 20),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Notification Bell Button
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/notifications'),
                      child: Stack(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: context.inputColor,
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
                            child: Icon(
                              Icons.notifications_none_rounded,
                              color: context.textColor,
                              size: 24,
                            ),
                          ),
                          if (unreadNotifs > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$unreadNotifs',
                                  style: TextStyle(color: context.cardColor, fontSize: 9, fontWeight: FontWeight.bold),
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
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.inputColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: context.textSecColor, size: 22),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
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
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.tune_rounded, color: context.cardColor, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Quick AI Tools & Features Shortcut Banners (FE-03, FE-08, FE-13, FE-14)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                child: Column(
                  children: [
                    // AI Features Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildFeatureTile(
                            title: 'Trợ Lý AI Film',
                            subtitle: 'Hỏi đáp kỹ thuật 24/7',
                            icon: Icons.auto_awesome,
                            gradient: AppColors.aiGradient,
                            onTap: () => Navigator.pushNamed(context, '/ai-assistant'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildFeatureTile(
                            title: 'AI Phục Chế 4K',
                            subtitle: 'Khôi phục ảnh film cũ',
                            icon: Icons.photo_filter_rounded,
                            gradient: AppColors.goldGradient,
                            onTap: () => Navigator.pushNamed(context, '/ai-restoration'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFeatureTile(
                            title: 'Gói Combo Bundle',
                            subtitle: 'Tiết kiệm tới 30%',
                            icon: Icons.card_giftcard_rounded,
                            gradient: AppColors.primaryGradient,
                            onTap: () => Navigator.pushNamed(context, '/service-packages'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildFeatureTile(
                            title: 'So Sánh Studio',
                            subtitle: 'Đối chiếu thông số',
                            icon: Icons.compare_arrows_rounded,
                            gradient: const LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)]),
                            onTap: () => Navigator.pushNamed(context, '/studio-comparison'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Category Chips Row
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedCategoryIndex == index;
                    return Padding(
                      padding: EdgeInsets.only(right: 10.0),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategoryIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : context.inputColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _categories[index],
                            style: TextStyle(
                              color: isSelected ? context.cardColor : context.textColor,
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

            // Section 1: Near Location Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Gần vị trí của bạn (${_filteredItems.length})',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textColor),
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
                      child: Text('Xóa bộ lọc', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
            ),

            // Section 1 Horizontal Cards List
            SliverToBoxAdapter(
              child: _filteredItems.isEmpty
                  ? Container(height: 100, alignment: Alignment.center, child: Text('Không tìm thấy kết quả phù hợp'))
                  : SizedBox(
                      height: 260,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Phổ biến & Được yêu thích', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textColor)),
                    Text('Tất cả', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ),
            ),

            // Section 2 Vertical List
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
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

  Widget _buildFeatureTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: context.cardColor, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: context.cardColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle, style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearCard(BuildContext context, BookingItem item) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/detail', arguments: item),
      child: Container(
        width: 230,
        margin: EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
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
                    onTap: () => setState(() => item.isFavorite = !item.isFavorite),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: context.cardColor, shape: BoxShape.circle),
                      child: Icon(
                        item.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: item.isFavorite ? Colors.red : context.textSecColor,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textColor)),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          SizedBox(width: 2),
                          Text(item.rating.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textColor)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(item.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: context.textSecColor)),
                  SizedBox(height: 8),
                  Text(
                    '${item.pricePerHour.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ / giờ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
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
      onTap: () => Navigator.pushNamed(context, '/detail', arguments: item),
      child: Container(
        margin: EdgeInsets.only(bottom: 14),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            SafeNetworkImage(url: item.imageUrl, width: 80, height: 80, borderRadius: BorderRadius.circular(12)),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textColor))),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          SizedBox(width: 2),
                          Text(item.rating.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textColor)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(item.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: context.textSecColor)),
                  SizedBox(height: 8),
                  Text(
                    '${item.pricePerHour.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ / giờ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
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


