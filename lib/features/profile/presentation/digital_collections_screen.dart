import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/device_image_picker.dart';
import '../models/photo_collection.dart';

class DigitalCollectionsScreen extends StatefulWidget {
  const DigitalCollectionsScreen({super.key});

  @override
  State<DigitalCollectionsScreen> createState() => _DigitalCollectionsScreenState();
}

class _DigitalCollectionsScreenState extends State<DigitalCollectionsScreen> {
  final List<PhotoCollection> _collections = PhotoCollection.sampleCollections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text('Album Ảnh Film Số Hóa'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 28),
            tooltip: 'Tải ảnh mới',
            onPressed: () async {
              final url = await DeviceImagePicker.pickImageFromDevice(
                context,
                title: 'Tải Ảnh Số Hóa Lên Album',
              );
              
              if (url != null && mounted) {
                setState(() {
                  _collections[0].photos.insert(
                    0,
                    FilmPhoto(
                      id: 'P-NEW-${DateTime.now().millisecondsSinceEpoch}',
                      title: 'Ảnh Film Mới Nạp',
                      imageUrl: url,
                      filmStock: 'Kodak Gold 200',
                      cameraUsed: 'Thiết bị cục bộ',
                      lensUsed: 'Unknown',
                      dateTaken: 'Vừa xong',
                    ),
                  );
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã thêm 1 ảnh mới vào Album đầu tiên!'), backgroundColor: Colors.green),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          itemCount: _collections.length,
          itemBuilder: (context, index) {
            final col = _collections[index];
            return Container(
              margin: EdgeInsets.only(bottom: 24),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.borderColor),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(col.albumName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: context.textColor)),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text('${col.photoCount} ảnh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(col.description, style: TextStyle(fontSize: 13, color: context.textSecColor, height: 1.4)),
                  SizedBox(height: 20),

                  // Photo grid previews (modern masonry feel)
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: col.photos.length,
                      itemBuilder: (context, pIndex) {
                        final photo = col.photos[pIndex];
                        return Container(
                          margin: EdgeInsets.only(right: 14),
                          width: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          child: Stack(
                            children: [
                              SafeNetworkImage(url: photo.imageUrl, width: 150, height: 180, borderRadius: BorderRadius.circular(20)),
                              Positioned(
                                bottom: 0, left: 0, right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent]),
                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(photo.filmStock, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.cardColor, fontSize: 11, fontWeight: FontWeight.w800)),
                                      SizedBox(height: 2),
                                      Text(photo.cameraUsed, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}


