import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../../../core/services/favorite_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../models/booking_item.dart';

class ItemDetailSliverAppBar extends StatelessWidget {
  final BookingItem item;
  final List<String> allImages;
  final int currentImageIndex;
  final ValueChanged<int> onImageIndexChanged;
  final ValueChanged<bool> onFavoriteToggled;

  const ItemDetailSliverAppBar({
    super.key,
    required this.item,
    required this.allImages,
    required this.currentImageIndex,
    required this.onImageIndexChanged,
    required this.onFavoriteToggled,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 370,
      pinned: true,
      stretch: true,
      backgroundColor: context.bgColor,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: context.cardColor.withValues(alpha: 0.85),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: context.textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: context.cardColor.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: ValueListenableBuilder<List<BookingItem>>(
                valueListenable: FavoriteService().favorites,
                builder: (context, _, _) {
                  final isFav = FavoriteService().isFavorite(item.id);
                  return Icon(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFav ? Colors.red : context.textColor,
                  );
                },
              ),
              onPressed: () {
                final nowFav = FavoriteService().toggle(item);
                onFavoriteToggled(nowFav);
                toastification.show(
                  context: context,
                  type: nowFav
                      ? ToastificationType.success
                      : ToastificationType.warning,
                  style: ToastificationStyle.flatColored,
                  title: Text(nowFav ? 'Đã lưu' : 'Đã bỏ lưu'),
                  description: Text(
                    nowFav
                        ? 'Đã thêm vào danh sách yêu thích.'
                        : 'Đã xóa khỏi danh sách yêu thích.',
                  ),
                  alignment: Alignment.bottomCenter,
                  autoCloseDuration: const Duration(seconds: 2),
                  showProgressBar: false,
                );
              },
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: double.infinity,
                viewportFraction: 1.0,
                enableInfiniteScroll: true,
                onPageChanged: (index, reason) => onImageIndexChanged(index),
              ),
              items: allImages.map((img) {
                return Hero(
                  tag: img == item.imageUrl
                      ? 'image_${item.id}'
                      : 'img_${img.hashCode}',
                  child: SafeNetworkImage(
                    url: img,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                );
              }).toList(),
            ),
            // Bottom gradient for indicator legibility
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 96,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Pagination dots positioned clear of the overlapping sheet curve
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: allImages.asMap().entries.map((entry) {
                  final bool isActive = currentImageIndex == entry.key;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: isActive ? 24.0 : 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isActive
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.65),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
