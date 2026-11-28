import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pagination_bar.dart';
import '../../booking/models/booking_api_models.dart';
import '../../booking/models/booking_item.dart';
import '../../booking/services/booking_api_service.dart';
import '../../notifications/models/notification_item.dart';
import '../widgets/home_banner_slider.dart';
import '../widgets/home_category_chips.dart';
import '../widgets/home_filter_sheet.dart';
import '../widgets/home_location_picker_sheet.dart';
import '../widgets/home_near_item_card.dart';
import '../widgets/home_popular_item_card.dart';
import '../widgets/home_top_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentLocation = 'Hồ Chí Minh, Việt Nam';
  int _selectedCategoryIndex = 0;
  int _currentBannerIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // API Data state
  static const int _popularPageSize = 5;
  final BookingApiService _bookingApiService = BookingApiService();
  List<BookingItem> _apiItems = [];
  bool _isLoadingItems = true;
  bool _hasLoadError = false;
  int _popularPage = 1;

  // Quick Banners Slider Data
  final List<Map<String, dynamic>> _quickBanners = [
    {
      'title': 'Trợ Lý AI Film 24/7',
      'subtitle': 'Hỏi đáp kỹ thuật chọn film, tráng rửa & phơi sáng',
      'icon': Icons.auto_awesome_rounded,
      'gradient': AppColors.aiGradient,
      'route': '/ai-assistant',
      'badge': 'HOT AI',
    },
    {
      'title': 'Gói Combo Bundle',
      'subtitle': 'Tiết kiệm tới 30% khi đặt trọn gói Studio & Máy',
      'icon': Icons.card_giftcard_rounded,
      'gradient': AppColors.primaryGradient,
      'route': '/service-packages',
      'badge': 'PROMO',
    },
    {
      'title': 'So Sánh Studio & Lab',
      'subtitle': 'Đối chiếu thông số phòng, thiết bị & mức giá',
      'icon': Icons.compare_arrows_rounded,
      'gradient':
          const LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)]),
      'route': '/studio-comparison',
      'badge': 'COMPARE',
    },
  ];

  // Filter Modal State
  static const double _minPriceFilter = 100000;
  static const double _maxPriceLimit = 5000000;
  double _maxPriceFilter = _maxPriceLimit;
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

  @override
  void initState() {
    super.initState();
    _fetchApiResources();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchApiResources() async {
    if (mounted) {
      setState(() {
        _isLoadingItems = true;
        _hasLoadError = false;
      });
    }
    try {
      final results = await Future.wait<List<ResourceItemResponseDTO>>([
        _bookingApiService.getStudios(),
        _bookingApiService.getDarkrooms(),
      ]);

      final rawStudios = results[0].map((e) => e.toBookingItem()).toList();
      final rawDarkrooms = results[1].map((e) => e.toBookingItem()).toList();
      final rawSpaces = [...rawStudios, ...rawDarkrooms];

      final enrichedResults = await Future.wait([
        _bookingApiService.enrichSpaceRatings(rawSpaces),
        _bookingApiService.getAllEquipmentItems(rawSpaces),
        _bookingApiService
            .getMyBookings(page: 1, pageSize: 50)
            .catchError((_) => null),
      ]);
      final rawRatedSpaces = enrichedResults[0] as List<BookingItem>;
      final equipment = enrichedResults[1] as List<BookingItem>;
      final bookingsPage =
          enrichedResults[2] as PagedResponseDTO<BookingResponseDTO>?;

      final bookingCounts = <String, int>{};
      for (final b in (bookingsPage?.items ?? const <BookingResponseDTO>[])) {
        final status = b.status.toUpperCase();
        if (status == 'CANCELLED' || status == 'EXPIRED') continue;
        final key = b.spaceId.trim().toLowerCase();
        if (key.isEmpty) continue;
        bookingCounts[key] = (bookingCounts[key] ?? 0) + 1;
      }

      final spaces = rawRatedSpaces.map((item) {
        final count = bookingCounts[item.id.trim().toLowerCase()] ?? 0;
        return count > item.bookingCount
            ? item.copyWith(bookingCount: count)
            : item;
      }).toList();
      final List<BookingItem> combined = [...spaces, ...equipment];

      if (mounted) {
        setState(() {
          _apiItems = combined;
          _isLoadingItems = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingItems = false;
          _hasLoadError = true;
        });
      }
    }
  }

  /// Danh sách "Phổ biến & Được yêu thích": ưu tiên sắp theo lượt đánh giá, lượt đặt và điểm đánh giá
  List<BookingItem> get _popularItems {
    final list = List<BookingItem>.from(_filteredItems);
    if (_sortBy == 'default') {
      list.sort((a, b) {
        final scoreCmp = b.popularityScore.compareTo(a.popularityScore);
        if (scoreCmp != 0) return scoreCmp;
        final revCmp = b.reviewCount.compareTo(a.reviewCount);
        if (revCmp != 0) return revCmp;
        final bookCmp = b.bookingCount.compareTo(a.bookingCount);
        if (bookCmp != 0) return bookCmp;
        return b.rating.compareTo(a.rating);
      });
    }
    return list;
  }

  List<BookingItem> get _filteredItems {
    List<BookingItem> list = List.from(_apiItems);

    if (_selectedCategoryIndex == 1) {
      list = list.where((e) => e.category == BookingCategory.studio).toList();
    } else if (_selectedCategoryIndex == 2) {
      list = list.where((e) => e.category == BookingCategory.darkroom).toList();
    } else if (_selectedCategoryIndex == 3) {
      list =
          list.where((e) => e.category == BookingCategory.equipment).toList();
    }

    if (_maxPriceFilter < _maxPriceLimit) {
      list = list.where((e) => e.pricePerHour <= _maxPriceFilter).toList();
    }
    if (_minRatingFilter > 0) {
      list = list.where((e) => e.rating >= _minRatingFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((e) =>
              e.name.toLowerCase().contains(q) ||
              e.location.toLowerCase().contains(q))
          .toList();
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
    showHomeFilterSheet(
      context: context,
      minPriceLimit: _minPriceFilter,
      maxPriceLimit: _maxPriceLimit,
      initialMaxPrice: _maxPriceFilter,
      initialMinRating: _minRatingFilter,
      initialSortBy: _sortBy,
      getResultCount: () => _filteredItems.length,
      onMaxPriceChanged: (val) => setState(() => _maxPriceFilter = val),
      onMinRatingChanged: (val) => setState(() => _minRatingFilter = val),
      onSortByChanged: (val) => setState(() => _sortBy = val),
      onReset: () {
        setState(() {
          _maxPriceFilter = _maxPriceLimit;
          _minRatingFilter = 0.0;
          _sortBy = 'default';
        });
      },
    );
  }

  void _showLocationPicker() {
    showHomeLocationPickerSheet(
      context: context,
      locations: _locations,
      currentLocation: _currentLocation,
      onLocationSelected: (loc) => setState(() => _currentLocation = loc),
    );
  }

  void _openItemList() {
    BookingCategory? initialCategory;
    if (_selectedCategoryIndex == 1) {
      initialCategory = BookingCategory.studio;
    } else if (_selectedCategoryIndex == 2) {
      initialCategory = BookingCategory.darkroom;
    } else if (_selectedCategoryIndex == 3) {
      initialCategory = BookingCategory.equipment;
    }
    Navigator.pushNamed(
      context,
      '/item-list',
      arguments: initialCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadNotifs =
        NotificationItem.notifications.where((n) => !n.isRead).length;
    final filteredItems = _filteredItems;
    final popularItems = _popularItems;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _fetchApiResources,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: HomeTopHeader(
                  currentLocation: _currentLocation,
                  unreadNotifs: unreadNotifs,
                  onLocationTap: _showLocationPicker,
                  onNotificationTap: () =>
                      Navigator.pushNamed(context, '/notifications'),
                ),
              ),
              SliverToBoxAdapter(
                child: HomeSearchBar(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  onFilterTap: _showFilterModal,
                ),
              ),
              SliverToBoxAdapter(
                child: HomeBannerSlider(
                  banners: _quickBanners,
                  currentIndex: _currentBannerIndex,
                  onPageChanged: (index) {
                    setState(() => _currentBannerIndex = index);
                  },
                  onBannerTap: (route) => Navigator.pushNamed(context, route),
                ),
              ),
              SliverToBoxAdapter(
                child: HomeCategoryChips(
                  categories: _categories,
                  selectedIndex: _selectedCategoryIndex,
                  onCategorySelected: (index) {
                    setState(() {
                      _selectedCategoryIndex = index;
                      _popularPage = 1;
                    });
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 14.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Gần vị trí của bạn (${filteredItems.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategoryIndex = 0;
                            _searchController.clear();
                            _searchQuery = '';
                            _maxPriceFilter = _maxPriceLimit;
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
              SliverToBoxAdapter(
                child: _isLoadingItems
                    ? const SizedBox(
                        height: 180,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : _hasLoadError
                        ? Container(
                            height: 120,
                            alignment: Alignment.center,
                            child: TextButton.icon(
                              onPressed: _fetchApiResources,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text(
                                'Không thể tải dữ liệu. Nhấn để thử lại',
                              ),
                            ),
                          )
                        : filteredItems.isEmpty
                            ? Container(
                                height: 100,
                                alignment: Alignment.center,
                                child: const Text(
                                  'Không tìm thấy kết quả phù hợp',
                                ),
                              )
                            : SizedBox(
                                height: 260,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 4,
                                  ),
                                  itemCount: filteredItems.length,
                                  itemBuilder: (context, index) {
                                    final item = filteredItems[index];
                                    return HomeNearItemCard(
                                      item: item,
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        '/detail',
                                        arguments: item,
                                      ),
                                      onFavoriteChanged: () => setState(() {}),
                                    );
                                  },
                                ),
                              ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 14.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Phổ biến & Được yêu thích',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: _openItemList,
                        child: const Text(
                          'Tất cả',
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
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                sliver: Builder(
                  builder: (context) {
                    if (popularItems.isEmpty) {
                      return const SliverToBoxAdapter(child: SizedBox());
                    }
                    final totalPages = (popularItems.length / _popularPageSize)
                        .ceil()
                        .clamp(1, 9999);
                    final safePage = _popularPage.clamp(1, totalPages);
                    final pageItems = popularItems
                        .skip((safePage - 1) * _popularPageSize)
                        .take(_popularPageSize)
                        .toList();

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == pageItems.length) {
                            return PaginationBar(
                              currentPage: safePage,
                              totalPages: totalPages,
                              totalItems: popularItems.length,
                              pageSize: _popularPageSize,
                              itemLabel: 'mục',
                              onPageChanged: (page) {
                                setState(() => _popularPage = page);
                              },
                            );
                          }
                          final item = pageItems[index];
                          return HomePopularItemCard(
                            item: item,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/detail',
                              arguments: item,
                            ),
                          );
                        },
                        childCount: pageItems.length + 1,
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
