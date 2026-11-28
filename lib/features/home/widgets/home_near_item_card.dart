import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../../../core/services/favorite_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../booking/models/booking_item.dart';

class HomeNearItemCard extends StatelessWidget {
  final BookingItem item;
  final VoidCallback onTap;
  final VoidCallback onFavoriteChanged;

  const HomeNearItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onFavoriteChanged,
  });

  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 230,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: context.cardColor,
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
                Hero(
                  tag: 'image_${item.id}',
                  child: SafeNetworkImage(
                    url: item.imageUrl,
                    height: 135,
                    width: double.infinity,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: ValueListenableBuilder<List<BookingItem>>(
                    valueListenable: FavoriteService().favorites,
                    builder: (context, _, _) {
                      final isFav = FavoriteService().isFavorite(item.id);
                      return GestureDetector(
                        onTap: () {
                          final nowFav = FavoriteService().toggle(item);
                          onFavoriteChanged();
                          toastification.show(
                            context: context,
                            type: nowFav
                                ? ToastificationType.success
                                : ToastificationType.warning,
                            style: ToastificationStyle.flatColored,
                            title: Text(nowFav ? 'Đã lưu' : 'Đã bỏ lưu'),
                            description: Text(
                              nowFav
                                  ? '${item.name} đã thêm vào danh sách yêu thích.'
                                  : '${item.name} đã xóa khỏi danh sách yêu thích.',
                            ),
                            alignment: Alignment.bottomCenter,
                            autoCloseDuration: const Duration(seconds: 2),
                            showProgressBar: false,
                          );
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : context.textSecColor,
                            size: 18,
                          ),
                        ),
                      );
                    },
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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item.ratingLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
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
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatPrice(item.pricePerHour)}đ / giờ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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
