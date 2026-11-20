import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
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
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final BookingApiService _apiService = BookingApiService();

  bool _isLoading = true;
  String _searchQuery = '';
  List<BookingItem> _studios = [];
  List<BookingItem> _darkrooms = [];

  // Filter Date
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialCategory == BookingCategory.darkroom) {
      initialIndex = 1;
    }
    _tabController = TabController(length: 2, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      setState(() {});
    });

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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

      final studioDtos = results[0];
      final darkroomDtos = results[1];

      if (!mounted) return;

      setState(() {
        _studios = studioDtos.map((e) => e.toBookingItem()).toList();
        _darkrooms = darkroomDtos.map((e) => e.toBookingItem()).toList();
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Danh Sách Studio & Phòng Tối', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text('Studio (${_studios.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wb_twilight_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text('Phòng Tối (${_darkrooms.length})'),
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
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm tên, địa chỉ...',
                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
                            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: _pickDateRange,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: _selectedFromDate != null ? AppColors.primary.withValues(alpha: 0.1) : AppColors.inputFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedFromDate != null ? AppColors.primary : Colors.transparent,
                          ),
                        ),
                        child: Row(
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
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _selectedFromDate != null ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                            if (_selectedFromDate != null) ...[
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedFromDate = null;
                                    _selectedToDate = null;
                                  });
                                  _loadData();
                                },
                                child: const Icon(Icons.close, size: 14, color: AppColors.primary),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
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
                        _buildResourceList(filteredStudios, isDarkroom: false),
                        _buildResourceList(filteredDarkrooms, isDarkroom: true),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceList(List<BookingItem> items, {required bool isDarkroom}) {
    if (items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isDarkroom ? Icons.wb_twilight_rounded : Icons.camera_alt_outlined,
                size: 64,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy ${isDarkroom ? "phòng tối" : "studio"} nào',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thử tìm kiếm với từ khóa hoặc ngày khác xem sao nhé!',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItemCard(item).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideY(begin: 0.05);
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
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
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: SafeNetworkImage(
                    url: item.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.category == BookingCategory.darkroom ? Icons.science_outlined : Icons.photo_camera_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.category == BookingCategory.darkroom ? 'Phòng Tối' : 'Studio',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          item.rating.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(a, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Giá thuê từ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(
                            '${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(item.pricePerHour)}/h',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Text('Xem chi tiết', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
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
