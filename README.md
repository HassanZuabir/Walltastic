# Walltastic

A dark, violet-accented Flutter wallpaper gallery with GetX state management
and Pexels photography.

## Run

```sh
flutter pub get
```

### Debug builds

Set your [Pexels API](https://www.pexels.com/api/) key in
`lib/config/local_config.dart`:

```dart
abstract final class LocalConfig {
  static const String pexelsApiKey = 'YOUR_KEY';
}
```

This local file is ignored by Git. On a fresh checkout or CI, create it from
`lib/config/local_config.dart.example` before building, even if you only use
build-time defines:

```sh
cp lib/config/local_config.dart.example lib/config/local_config.dart
```

The effective key is available throughout the app as `AppConfig.pexelsApiKey`.
The local key is used only in debug mode, so you can run from the IDE or install
the same debug APK on multiple devices without extra arguments:

```sh
flutter run
flutter build apk --debug
```

An explicit build-time define overrides the local debug key:

```sh
flutter run --dart-define=PEXELS_API_KEY=YOUR_KEY
```

All wallpapers, including the featured image, come from live Pexels responses.
There is no bundled sample gallery or offline demo fallback. If the API key is
missing or the service fails, the app shows an unavailable state with retry.
Category tiles are navigation controls, not hardcoded photo collections.
Bookmarks from the retired demo gallery are excluded from saved favorites.

Profile and release builds ignore the local debug key; supply
`--dart-define=PEXELS_API_KEY=YOUR_KEY` for those builds. Do not commit real keys
or share debug APKs containing your key publicly.
Build-time defines keep keys out of source control, but **do not make them
secret in a distributed application**. For production, route Pexels requests
through your own authenticated backend with rate limiting instead of embedding
a private key in the client. Review Pexels' current API terms and obtain any
required approval for your wallpaper use case before publishing.

## Features

- Responsive discovery gallery, live featured wallpaper, and category browsing.
- Live curated feed and portrait search, with paginated loading.
- GetX reactive loading, empty, API error, and retry states.
- In-app original-image viewing with pinch-to-zoom, pan, and image retries.
- Original-quality downloads directly to Photos / Gallery, with progress,
  permission handling, and retryable errors.
- Photographer attribution and optional Pexels links.
- Device-local favorites that persist between launches.
- Settings with persistent System, Light, and Dark appearance modes.
- Optional Wi-Fi-only downloads: blocks mobile-data downloads and stops an
  active download when Wi-Fi is lost. Retry after reconnecting. Image previews
  and browsing are not restricted by this setting.

Open Settings using the gear at the top right. Existing defaults are preserved:
dark appearance and downloads on any connection. Storage settings also explain
where images are saved; About includes photo and open-source licenses.

Favorites are bookmarks; downloaded images are saved separately in the device's
photo library. Viewing and downloading do not open a browser. Photographer and
license links still open Pexels. Setting the device wallpaper is not implemented.

Gallery saving supports the project's Android and iOS targets. iOS requests
permission to add photos (older iOS versions require photo-library access);
Android 10 and below may request storage access. Newer Android versions save
through MediaStore without broad photo-library read permissions.
After adding the native gallery plugin, stop and rebuild the app rather than
only hot-reloading it.

The project retains its existing iOS 13 deployment target. Xcode 27 requires
iOS 15 or later; use a compatible Xcode version, or intentionally raise the
Runner and CocoaPods deployment targets before building with Xcode 27.

## Organization

```text
lib/
  app.dart          GetMaterialApp setup
  main.dart         Configuration and dependency registration
  controllers/      GetX gallery/search/favorites state
  data/             Pexels client, category definitions, local favorites storage
  models/           Typed wallpaper model
  screens/          Discovery, categories, saved gallery, detail
  theme/            Shared color palette and Material theme
  widgets/          Reusable image, card, and action components
```

## Development

```sh
flutter analyze
flutter test
```

Service tests use mocked HTTP responses; no API key is needed.
All test wallpaper fixtures live under `test/` and are not part of the app.
