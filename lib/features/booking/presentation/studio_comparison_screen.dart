import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../models/booking_api_models.dart';
import '../models/booking_item.dart';
import '../services/booking_api_service.dart';

class StudioComparisonScreen extends StatefulWidget {
  const StudioComparisonScreen({super.key});

  @override
  State<StudioComparisonScreen> createState() => _StudioComparisonScreenState();
}

class _StudioComparisonScreenState extends State<StudioComparisonScreen> {
  final BookingApiService _bookingApiService = BookingApiService();
  List<BookingItem> _all = [];
  BookingItem? _item1;
  BookingItem? _item2;
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
      final studios = results[0].map((e) => e.toBookingItem()).toList();
      final darkrooms = results[1].map((e) => e.toBookingItem()).toList();
      final equipment = await _bookingApiService.getAllEquipmentItems([...studios, ...darkrooms]);
      if (!mounted) return;
      final combined = [...studios, ...darkrooms, ...equipment];
      setState(() {
        _all = combined;
        _item1 = combined.isNotEmpty ? combined[0] : null;
        _item2 = combined.length > 1 ? combined[1] : _item1;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('So Sánh Không Gian & Thiết Bị')),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_all.length < 2 || _item1 == null || _item2 == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('So Sánh Không Gian & Thiết Bị')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.compare_arrows_rounded, size: 56, color: AppColors.textHint),
                const SizedBox(height: 14),
                const Text(
                  'Cần ít nhất 2 địa điểm hoặc thiết bị để so sánh',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _loadLiveSpaces,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tải lại dữ liệu'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final item1 = _item1!;
    final item2 = _item2!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('So Sánh Không Gian & Thiết Bị'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'So Sánh Trực Quan 2 Địa Điểm / Thiết Bị',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Đối chiếu sức chứa, thiết bị có sẵn, mức giá & thông số phòng',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // Item Pickers Row
              Row(
                children: [
                  Expanded(child: _buildItemPicker(1, item1)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: Text('VS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Expanded(child: _buildItemPicker(2, item2)),
                ],
              ),
              const SizedBox(height: 24),

              // Specs Comparison Table Card
              Container(
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
                  children: [
                    _buildCompHeader(),
                    _buildCompRow('Loại hình', item1.categoryName, item2.categoryName),
                    _buildCompRow('Đơn giá thuê', '${item1.pricePerHour.toInt()}đ / giờ', '${item2.pricePerHour.toInt()}đ / giờ'),
                    _buildCompRow('Đánh giá ⭐', item1.ratingLabel, item2.ratingLabel),
                    _buildCompRow('Vị trí', item1.location, item2.location),
                    _buildCompRow(
                      'Sức chứa chuẩn',
                      'Tối đa ${item1.capacity} người',
                      'Tối đa ${item2.capacity} người',
                    ),
                    _buildCompRow(
                      'Phong cách / Quy trình',
                      item1.artisticStyle.isNotEmpty
                          ? item1.artisticStyle
                          : (item1.supportedProcesses.isNotEmpty
                              ? item1.supportedProcesses
                              : 'Tiêu chuẩn Film'),
                      item2.artisticStyle.isNotEmpty
                          ? item2.artisticStyle
                          : (item2.supportedProcesses.isNotEmpty
                              ? item2.supportedProcesses
                              : 'Tiêu chuẩn Film'),
                    ),
                    _buildCompRow('Số tiện ích', '${item1.amenities.length} trang bị', '${item2.amenities.length} trang bị'),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Booking Buttons Row
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Đặt Không Gian 1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/detail', arguments: item2);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Đặt Không Gian 2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemPicker(int slot, BookingItem selected) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          SafeNetworkImage(
            url: selected.imageUrl,
            height: 90,
            width: double.infinity,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 8),
          Text(
            selected.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          DropdownButton<BookingItem>(
            value: selected,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
            items: _all.map((item) {
              return DropdownMenuItem<BookingItem>(
                value: item,
                child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  if (slot == 1) {
                    _item1 = val;
                  } else {
                    _item2 = val;
                  }
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 90, child: Text('Tiêu chí', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12))),
          Expanded(child: Text('Không gian 1', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12))),
          Expanded(child: Text('Không gian 2', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildCompRow(String label, String val1, String val2) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.inputFill)),
      ),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 12))),
          Expanded(child: Text(val1, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary))),
          Expanded(child: Text(val2, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}
