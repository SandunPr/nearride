# NearRide Flutter app

Mobile client for discovering nearby independent vehicle and driver listings. It intentionally has no map, booking, fare calculation, tracking, or payment flow.

## Run

1. Install Flutter 3.24+ and an Android/iOS toolchain.
2. Run `flutter pub get`.
3. Start the API, then run `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1` for Android Emulator. Use your computer's LAN IP on a physical phone.
4. Configure Android/iOS location, camera/photo-library and URL scheme permissions before release.

The current client includes secure token refresh, graceful GPS fallback, nearby discovery, listing details, external phone/WhatsApp contact, marketplace safety notices, and the connected provider listing wizard. Remaining secondary screens can be added behind the existing GoRouter and feature folders without changing the API boundary.
