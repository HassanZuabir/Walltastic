import 'package:walltastic/data/wallpaper_repository.dart';
import 'package:walltastic/models/wallpaper.dart';

final testWallpapers = [
  _photo(1, 'Mountain landscape'),
  _photo(2, 'Nature forest'),
  _photo(3, 'Ocean waves'),
];

Wallpaper _photo(int id, String title) => Wallpaper(
  id: id,
  title: title,
  photographer: 'Test photographer $id',
  pageUrl: 'https://example.com/photos/$id',
  imageUrl: 'https://example.com/images/$id.jpg',
  originalUrl: 'https://example.com/originals/$id.jpg',
  width: 3000,
  height: 4500,
);

class FakeWallpaperRepository extends WallpaperRepository {
  @override
  Future<WallpaperPage> fetch({String query = '', int page = 1}) async =>
      WallpaperPage(
        page > 1
            ? []
            : testWallpapers
                  .where(
                    (photo) => photo.title.toLowerCase().contains(
                      query.toLowerCase().trim(),
                    ),
                  )
                  .toList(),
        hasMore: false,
      );
}
