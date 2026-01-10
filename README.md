# meal_planner_app_local_version

Keto meal planner built with Flutter; configured for mobile/desktop and now with a web target.

## Run it
- Install Flutter (stable) and get packages: `flutter pub get`.
- Web dev server: `flutter run -d chrome` (or `edge`/`safari` depending on platform).
- Desktop: `flutter run -d macos` or `flutter run -d windows` if enabled locally.
- Mobile: `flutter run -d ios`/`android` when those platforms are set up.

## Build for the browser
- Release build: `flutter build web --release` (outputs to `build/web`).
- Serve the build locally: `python -m http.server 8080 -d build/web` or any static host (Firebase Hosting, Vercel, etc.).
- Persistence uses `shared_preferences` (LocalStorage in the browser), so data is per-browser and subject to storage limits.

## Routing
- URL-friendly navigation via `go_router`; main paths: `/`, `/create`, `/saved`, `/ingredients`, `/meal-types`, `/reject`.

## Next
- Tune page layouts for wide screens (max-width wrapping, column layouts).
- Add PWA polish (custom icons, offline caching/service worker) if desired.
