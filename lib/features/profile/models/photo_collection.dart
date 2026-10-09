class FilmPhoto {
  final String id;
  final String title;
  final String imageUrl;
  final String filmStock; // e.g., 'Kodak Gold 200', 'ILFORD HP5 Plus'
  final String cameraUsed; // e.g., 'Leica M6', 'Hasselblad 500CM'
  final String lensUsed; // e.g., 'Summicron 35mm f/2'
  final String dateTaken;
  final int likes;

  FilmPhoto({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.filmStock,
    required this.cameraUsed,
    required this.lensUsed,
    required this.dateTaken,
    this.likes = 0,
  });
}

class PhotoCollection {
  final String id;
  final String albumName;
  final String coverImage;
  final String description;
  final int photoCount;
  final List<FilmPhoto> photos;

  PhotoCollection({
    required this.id,
    required this.albumName,
    required this.coverImage,
    required this.description,
    required this.photoCount,
    required this.photos,
  });

  static List<PhotoCollection> sampleCollections = [
    PhotoCollection(
      id: 'ALB-1',
      albumName: 'Saigon Street Life on 35mm',
      coverImage: 'https://images.unsplash.com/photo-1510127034890-ba27508e9f1c?w=600&auto=format&fit=crop&q=80',
      description: 'Bộ sưu tập khoảnh khắc đường phố Sài Gòn chụp bằng máy Leica M6 và phim Kodak Tri-X 400.',
      photoCount: 8,
      photos: [
        FilmPhoto(
          id: 'P-01',
          title: 'Góc Phố Quận 1 Chiều Mưa',
          imageUrl: 'https://images.unsplash.com/photo-1510127034890-ba27508e9f1c?w=600&auto=format&fit=crop&q=80',
          filmStock: 'Kodak Tri-X 400',
          cameraUsed: 'Leica M6',
          lensUsed: 'Summicron 35mm f/2',
          dateTaken: '15/09/2026',
          likes: 42,
        ),
        FilmPhoto(
          id: 'P-02',
          title: 'Xe Cà Phê Mới Sáng',
          imageUrl: 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=600&auto=format&fit=crop&q=80',
          filmStock: 'Kodak Gold 200',
          cameraUsed: 'Canon AE-1',
          lensUsed: '50mm f/1.4',
          dateTaken: '20/09/2026',
          likes: 38,
        ),
      ],
    ),
    PhotoCollection(
      id: 'ALB-2',
      albumName: 'Vintage Portrait Series @ Studio Saigon',
      coverImage: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=600&auto=format&fit=crop&q=80',
      description: 'Bộ ảnh chân dung chụp indoor với nguồn sáng tự nhiên kết hợp đèn Profoto.',
      photoCount: 12,
      photos: [
        FilmPhoto(
          id: 'P-03',
          title: 'Nắng Chiều Cửa Cổ',
          imageUrl: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=600&auto=format&fit=crop&q=80',
          filmStock: 'Kodak Portra 400',
          cameraUsed: 'Hasselblad 500CM',
          lensUsed: '80mm f/2.8',
          dateTaken: '02/10/2026',
          likes: 95,
        ),
      ],
    ),
  ];
}
