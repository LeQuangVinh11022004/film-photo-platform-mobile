import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/booking_api_models.dart';
import '../models/booking_item.dart';
import '../services/booking_api_service.dart';
import '../widgets/studio_comparison_picker_row.dart';
import '../widgets/studio_comparison_tab_bar.dart';
import '../widgets/studio_comparison_table.dart';

class StudioComparisonScreen extends StatefulWidget {
  const StudioComparisonScreen({super.key});

  @override
  State<StudioComparisonScreen> createState() => _StudioComparisonScreenState();
}

class _StudioComparisonScreenState extends State<StudioComparisonScreen> {
  final BookingApiService _bookingApiService = BookingApiService();

  /// 0 = So sánh 2 Studio, 1 = So sánh 2 Phòng Tối (Darkroom)
  int _selectedSpaceTab = 0;

  List<BookingItem> _studios = [];
  List<BookingItem> _darkrooms = [];

  BookingItem? _studio1;
  BookingItem? _studio2;
  BookingItem? _darkroom1;
  BookingItem? _darkroom2;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLiveSpaces();
  }

  Future<void> _loadLiveSpaces() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait<List<ResourceItemResponseDTO>>([
        _bookingApiService.getStudios(),
        _bookingApiService.getDarkrooms(),
      ]);
      if (!mounted) return;
      final rawStudios = results[0].map((e) => e.toBookingItem()).toList();
      final rawDarkrooms = results[1].map((e) => e.toBookingItem()).toList();
      final enriched = await Future.wait([
        _bookingApiService.enrichSpaceRatings(rawStudios),
        _bookingApiService.enrichSpaceRatings(rawDarkrooms),
      ]);
      if (!mounted) return;
      final studios = enriched[0];
      final darkrooms = enriched[1];

      setState(() {
        _studios = studios;
        _darkrooms = darkrooms;
        _studio1 = studios.isNotEmpty ? studios[0] : null;
        _studio2 = studios.length > 1 ? studios[1] : _studio1;
        _darkroom1 = darkrooms.isNotEmpty ? darkrooms[0] : null;
        _darkroom2 = darkrooms.length > 1 ? darkrooms[1] : _darkroom1;

        // Nếu Studio < 2 nhưng Darkroom >= 2 thì tự chuyển sang tab Phòng Tối
        if (studios.length < 2 && darkrooms.length >= 2) {
          _selectedSpaceTab = 1;
        }
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<BookingItem> get _currentList =>
      _selectedSpaceTab == 0 ? _studios : _darkrooms;

  BookingItem? get _currentItem1 =>
      _selectedSpaceTab == 0 ? _studio1 : _darkroom1;

  BookingItem? get _currentItem2 =>
      _selectedSpaceTab == 0 ? _studio2 : _darkroom2;

  String get _currentSpaceLabel =>
      _selectedSpaceTab == 0 ? 'Studio' : 'Phòng Tối';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('So Sánh Không Gian'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : Column(
                children: [
                  StudioComparisonTabBar(
                    selectedTab: _selectedSpaceTab,
                    studioCount: _studios.length,
                    darkroomCount: _darkrooms.length,
                    onTabChanged: (tab) =>
                        setState(() => _selectedSpaceTab = tab),
                  ),
                  Expanded(
                    child: _buildComparisonBody(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildComparisonBody() {
    final list = _currentList;
    final item1 = _currentItem1;
    final item2 = _currentItem2;

    if (list.length < 2 || item1 == null || item2 == null) {
      return StudioComparisonEmptyState(
        selectedSpaceTab: _selectedSpaceTab,
        spaceLabel: _currentSpaceLabel,
        availableCount: list.length,
        onReload: _loadLiveSpaces,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'So Sánh Trực Quan 2 $_currentSpaceLabel',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedSpaceTab == 0
                ? 'Đối chiếu mức giá, diện tích, ánh sáng & phong cách giữa 2 Studio'
                : 'Đối chiếu mức giá, quy trình tráng rọi, thông gió & tiện ích giữa 2 Phòng Tối',
            style: TextStyle(
              fontSize: 13,
              color: context.textSecColor,
            ),
          ),
          const SizedBox(height: 20),
          StudioComparisonPickerRow(
            item1: item1,
            item2: item2,
            options: list,
            onItem1Changed: (val) {
              setState(() {
                if (_selectedSpaceTab == 0) {
                  _studio1 = val;
                } else {
                  _darkroom1 = val;
                }
              });
            },
            onItem2Changed: (val) {
              setState(() {
                if (_selectedSpaceTab == 0) {
                  _studio2 = val;
                } else {
                  _darkroom2 = val;
                }
              });
            },
          ),
          const SizedBox(height: 24),
          StudioComparisonTable(
            selectedSpaceTab: _selectedSpaceTab,
            spaceLabel: _currentSpaceLabel,
            item1: item1,
            item2: item2,
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/detail', arguments: item1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Đặt $_currentSpaceLabel 1',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/detail', arguments: item2);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.isDark
                        ? AppColors.primaryLight
                        : AppColors.primary,
                    side: BorderSide(
                      color: context.isDark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Đặt $_currentSpaceLabel 2',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
