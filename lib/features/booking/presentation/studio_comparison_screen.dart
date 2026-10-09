import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../models/booking_item.dart';

class StudioComparisonScreen extends StatefulWidget {
  const StudioComparisonScreen({super.key});

  @override
  State<StudioComparisonScreen> createState() => _StudioComparisonScreenState();
}

class _StudioComparisonScreenState extends State<StudioComparisonScreen> {
  final List<BookingItem> _all = BookingItem.sampleItems;
  late BookingItem _item1;
  late BookingItem _item2;

  @override
  void initState() {
    super.initState();
    _item1 = _all[0]; // Vintage Film Studio Saigon
    _item2 = _all[1]; // Silver Halide Darkroom Studio
  }

  @override
  Widget build(BuildContext context) {
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
                  Expanded(child: _buildItemPicker(1, _item1)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: Text('VS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Expanded(child: _buildItemPicker(2, _item2)),
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
                    _buildCompRow('Loại hình', _item1.categoryName, _item2.categoryName),
                    _buildCompRow('Đơn giá thuê', '${_item1.pricePerHour.toInt()}đ / giờ', '${_item2.pricePerHour.toInt()}đ / giờ'),
                    _buildCompRow('Đánh giá ⭐', '${_item1.rating} ⭐', '${_item2.rating} ⭐'),
                    _buildCompRow('Vị trí', _item1.location, _item2.location),
                    _buildCompRow('Sức chứa chuẩn', '5 - 10 người', '1 - 4 người'),
                    _buildCompRow('Phong cách', 'Retro / Vintage', 'B&W Film Lab'),
                    _buildCompRow('Số thiết bị', '${_item1.amenities.length} trang bị', '${_item2.amenities.length} trang bị'),
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
                        Navigator.pushNamed(context, '/detail', arguments: _item1);
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
                        Navigator.pushNamed(context, '/detail', arguments: _item2);
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
