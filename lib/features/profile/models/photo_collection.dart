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

  /// Danh sách album ảnh thực do người dùng tải lên (không dùng dữ liệu mẫu)
  static final List<PhotoCollection> collections = [];
}
