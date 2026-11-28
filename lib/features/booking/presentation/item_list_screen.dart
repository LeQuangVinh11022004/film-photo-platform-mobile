import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pagination_bar.dart';
import '../models/booking_api_models.dart';
import '../models/booking_item.dart';
import '../services/booking_api_service.dart';
import '../widgets/item_list_card.dart';
import '../widgets/item_list_empty_state.dart';
import '../widgets/item_list_tab_bar.dart';

class ItemListScreen extends StatefulWidget {
  final BookingCategory? initialCategory;
  const ItemListScreen({super.key, this.initialCategory});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen>
    with SingleTickerProviderStateMixin {
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
      final fromDateStr = _selectedFromDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedFromDate!)
          : null;
      final toDateStr = _selectedToDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedToDate!)
          : null;

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
    final query = _searchQuery.toLowerCase();
    return source
        .where((e) =>
            e.name.toLowerCase().contains(query) ||
            e.location.toLowerCase().contains(query) ||
            e.description.toLowerCase().contains(query))
        .toList();
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

  void _clearFiltersAndReload() {
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
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: context.textColor,
          ),
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
        bottom: ItemListTabBar(
          tabController: _tabController,
          studioCount: _studios.length,
          darkroomCount: _darkrooms.length,
          equipmentCount: _equipments.length,
        ),
      ),
      body: Column(
        children: [
          ItemListFilterHeader(
            searchController: _searchController,
            searchQuery: _searchQuery,
            selectedFromDate: _selectedFromDate,
            selectedToDate: _selectedToDate,
            onSearchChanged: (val) => setState(() {
              _searchQuery = val.trim();
              _studioPage = 1;
              _darkroomPage = 1;
              _equipmentPage = 1;
            }),
            onClearSearch: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _studioPage = 1;
                _darkroomPage = 1;
                _equipmentPage = 1;
              });
            },
            onPickDateRange: _pickDateRange,
            onClearDateRange: () {
              setState(() {
                _selectedFromDate = null;
                _selectedToDate = null;
              });
              _loadData();
            },
          ),
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
      return ItemListEmptyState(
        categoryLabel: categoryLabel,
        emptyIcon: emptyIcon,
        hasActiveFilters:
            _searchQuery.isNotEmpty || _selectedFromDate != null,
        onClearFilters: _clearFiltersAndReload,
      );
    }

    final totalPages = (items.length / _pageSize).ceil().clamp(1, 9999);
    final safePage = currentPage.clamp(1, totalPages);
    final pageItems =
        items.skip((safePage - 1) * _pageSize).take(_pageSize).toList();
    final bottomInset = math.max(
      MediaQuery.paddingOf(context).bottom,
      MediaQuery.viewPaddingOf(context).bottom,
    );

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
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
        return ItemListCard(
          item: item,
          onTap: () {
            Navigator.pushNamed(context, '/detail', arguments: item);
          },
        )
            .animate()
            .fadeIn(duration: 250.ms, delay: (index * 40).ms)
            .slideY(begin: 0.04);
      },
    );
  }
}
