import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/pagination_bar.dart';
import '../models/booking_api_models.dart';
import '../models/booking_item.dart';
import '../services/booking_api_service.dart';

class ItemListScreen extends StatefulWidget {
  final BookingCategory? initialCategory;
  const ItemListScreen({super.key, this.initialCategory});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> with SingleTickerProviderStateMixin {
  static const int _pageSize = 5;

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final BookingApiService _apiService = BookingApiService();
  final ScrollController _studioScrollController = ScrollController();
  final ScrollController _darkroomScrollController = ScrollController();
  final ScrollController _equipmentScrollController = ScrollController();

  bool _isLoading = true;
  bool _hasAppliedRouteArg = false;
  String _searchQuery = '';
  List<BookingItem> _studios = [];
  List<BookingItem> _darkrooms = [];
  List<BookingItem> _equipments = [];

  int _studioPage = 1;
  int _darkroomPage = 1;
  int _equipmentPage = 1;

  // Filter Date
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;

  int _categoryToTabIndex(BookingCategory? category) {
    switch (category) {
      case BookingCategory.darkroom:
        return 1;
      case BookingCategory.equipment:
        return 2;
      case BookingCategory.studio:
      case null:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _categoryToTabIndex(widget.initialCategory),
    );
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasAppliedRouteArg) {
      _hasAppliedRouteArg = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is BookingCategory) {
        final targetIndex = _categoryToTabIndex(args);
        if (_tabController.index != targetIndex) {
          _tabController.index = targetIndex;
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _studioScrollController.dispose();
    _darkroomScrollController.dispose();
    _equipmentScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final fromDateStr = _selectedFromDate != null ? DateFormat('yyyy-MM-dd').format(_selectedFromDate!) : null;
      final toDateStr = _selectedToDate != null ? DateFormat('yyyy-MM-dd').format(_selectedToDate!) : null;

      final results = await Future.wait<List<ResourceItemResponseDTO>>([
        _apiService.getStudios(fromDate: fromDateStr, toDate: toDateStr),
        _apiService.getDarkrooms(fromDate: fromDateStr, toDate: toDateStr),
      ]);

      final rawStudios = results[0].map((e) => e.toBookingItem()).toList();
      final rawDarkrooms = results[1].map((e) => e.toBookingItem()).toList();
      final enrichedResults = await Future.wait([
        _apiService.enrichSpaceRatings(rawStudios),
        _apiService.enrichSpaceRatings(rawDarkrooms),
        _apiService.getAllEquipmentItems([...rawStudios, ...rawDarkrooms]),
      ]);

      final studioItems = enrichedResults[0];
      final darkroomItems = enrichedResults[1];
      final equipmentItems = enrichedResults[2];

      if (!mounted) return;

      setState(() {
        _studios = studioItems;
        _darkrooms = darkroomItems;
        _equipments = equipmentItems;
        _studioPage = 1;
        _darkroomPage = 1;
        _equipmentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<BookingItem> _filterItems(List<BookingItem> source) {
    if (_searchQuery.isEmpty) return source;
    return source.where((e) =>
        e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        e.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        e.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDateRange: _selectedFromDate != null && _selectedToDate != null
          ? DateTimeRange(start: _selectedFromDate!, end: _selectedToDate!)
          : null,
      builder: (pickerContext, child) {
        final isDark = context.isDark;
        return Theme(
          data: Theme.of(pickerContext).copyWith(
            scaffoldBackgroundColor: context.bgColor,
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.cardBg,
                    onSurface: AppColors.textPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedFromDate = picked.start;
        _selectedToDate = picked.end;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudios = _filterItems(_studios);
    final filteredDarkrooms = _filterItems(_darkrooms);
    final filteredEquipments = _filterItems(_equipments);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: context.textColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Studio, Phòng Tối & Thiết Bị',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: context.textColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.inputColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: context.textSecColor,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
              tabs: [
                Tab(
                  height: 38,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined, size: 15),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Studio (${_studios.length})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  height: 38,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wb_twilight_rounded, size: 15),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Phòng Tối (${_darkrooms.length})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  height: 38,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_camera_back_outlined, size: 15),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Thiết Bị (${_equipments.length})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: context.cardColor,
              border: Border(
                bottom: BorderSide(color: context.borderColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.inputColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(fontSize: 13, color: context.textColor),
                      onChanged: (val) => setState(() {
                        _searchQuery = val.trim();
                        _studioPage = 1;
                        _darkroomPage = 1;
                        _equipmentPage = 1;
                      }),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Tìm kiếm tên, địa chỉ...',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textHint),
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.textSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _studioPage = 1;
                                    _darkroomPage = 1;
                                    _equipmentPage = 1;
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: _pickDateRange,
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _selectedFromDate != null
                          ? (context.isDark
                              ? AppColors.primaryDark.withValues(alpha: 0.3)
                              : AppColors.primarySoft)
                          : context.inputColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedFromDate != null ? AppColors.primary : context.borderColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 18,
                          color: _selectedFromDate != null ? AppColors.primary : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _selectedFromDate != null
                              ? '${DateFormat('dd/MM').format(_selectedFromDate!)} - ${DateFormat('dd/MM').format(_selectedToDate!)}'
                              : 'Chọn ngày',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedFromDate != null ? AppColors.primary : context.textColor,
                          ),
                        ),
                        if (_selectedFromDate != null) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFromDate = null;
                                _selectedToDate = null;
                              });
                              _loadData();
                            },
                            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content TabViews
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _loadData,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildResourceList(
                          filteredStudios,
                          category: BookingCategory.studio,
                          currentPage: _studioPage,
                          scrollController: _studioScrollController,
                          onPageChanged: (page) {
                            setState(() => _studioPage = page);
                            if (_studioScrollController.hasClients) {
                              _studioScrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                        ),
                        _buildResourceList(
                          filteredDarkrooms,
                          category: BookingCategory.darkroom,
                          currentPage: _darkroomPage,
                          scrollController: _darkroomScrollController,
                          onPageChanged: (page) {
                            setState(() => _darkroomPage = page);
                            if (_darkroomScrollController.hasClients) {
                              _darkroomScrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                        ),
                        _buildResourceList(
                          filteredEquipments,
                          category: BookingCategory.equipment,
                          currentPage: _equipmentPage,
                          scrollController: _equipmentScrollController,
                          onPageChanged: (page) {
                            setState(() => _equipmentPage = page);
                            if (_equipmentScrollController.hasClients) {
                              _equipmentScrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceList(
    List<BookingItem> items, {
    required BookingCategory category,
    required int currentPage,
    required ScrollController scrollController,
    required ValueChanged<int> onPageChanged,
  }) {
    final String categoryLabel;
    final IconData emptyIcon;
    switch (category) {
      case BookingCategory.studio:
        categoryLabel = 'studio';
        emptyIcon = Icons.camera_alt_outlined;
        break;
      case BookingCategory.darkroom:
        categoryLabel = 'phòng tối';
        emptyIcon = Icons.wb_twilight_rounded;
        break;
      case BookingCategory.equipment:
        categoryLabel = 'thiết bị';
        emptyIcon = Icons.photo_camera_back_outlined;
        break;
    }

    if (items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: context.inputColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.borderColor),
                ),
                child: Icon(
                  emptyIcon,
                  size: 44,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Không tìm thấy $categoryLabel nào',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Thử tìm kiếm với từ khóa hoặc chọn khoảng ngày khác xem sao nhé!',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: context.textSecColor,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (_searchQuery.isNotEmpty || _selectedFromDate != null) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                      _selectedFromDate = null;
                      _selectedToDate = null;
                      _studioPage = 1;
                      _darkroomPage = 1;
                      _equipmentPage = 1;
                    });
                    _loadData();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Xóa bộ lọc'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    minimumSize: const Size(0, 42),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final totalPages = (items.length / _pageSize).ceil().clamp(1, 9999);
    final safePage = currentPage.clamp(1, totalPages);
    final pageItems = items
        .skip((safePage - 1) * _pageSize)
        .take(_pageSize)
        .toList();

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: pageItems.length + 1,
      itemBuilder: (context, index) {
        if (index == pageItems.length) {
          return PaginationBar(
            currentPage: safePage,
            totalPages: totalPages,
            totalItems: items.length,
            pageSize: _pageSize,
            itemLabel: categoryLabel,
            onPageChanged: onPageChanged,
          );
        }
        final item = pageItems[index];
        return _buildItemCard(item).animate().fadeIn(duration: 250.ms, delay: (index * 40).ms).slideY(begin: 0.04);
      },
    );
  }

  Widget _buildItemCard(BookingItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/detail', arguments: item);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: [
                SafeNetworkImage(
                  url: item.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                // Category badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.category == BookingCategory.darkroom
                              ? Icons.science_outlined
                              : Icons.photo_camera_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          item.category == BookingCategory.darkroom ? 'Phòng Tối' : 'Studio',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Rating badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.cardColor.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.borderColor.withValues(alpha: 0.6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 3),
                        Text(
                          item.ratingLabel,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: context.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Information Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 15, color: context.textSecColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: context.textSecColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (item.amenities.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: item.amenities.take(3).map((a) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.inputColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.borderColor.withValues(alpha: 0.6)),
                          ),
                          child: Text(
                            a,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: context.textSecColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Divider(height: 1, thickness: 1, color: context.dividerColor),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Giá thuê từ',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: context.textSecColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(item.pricePerHour)}/h',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Xem chi tiết',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                          ],
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
}
