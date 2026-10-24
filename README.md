# Norberto Pension House – Guest App (Flutter)

Connected to **PensionHouse.API** (ASP.NET Core + SQL Server).

## 1. Put the files in your Flutter project

Your zip only had `lib/`. Copy this folder's `lib/`, `pubspec.yaml`, `analysis_options.yaml`
and `assets/` into your Flutter project (or use this folder as the project), then:

```
flutter create .          # only if android/ and ios/ folders are missing
flutter pub get
```

Needs Flutter 3.27 or newer.

## 2. Point the app at the API laptop

The API runs on the **other laptop**, so the phone must use that laptop's IP address.

1. On the API laptop run `ipconfig` and note the IPv4 address (e.g. `192.168.1.20`).
2. Run the API with the **`http`** profile (port **5231**) – *not* `https`/IIS Express.
   (The HTTPS profile has a self-signed certificate and redirects, which a phone rejects.)
3. Allow port 5231 through Windows Firewall on the API laptop:
   `netsh advfirewall firewall add rule name="PensionHouse API" dir=in action=allow protocol=TCP localport=5231`
4. Phone and both laptops must be on the same Wi-Fi.
5. Set the address in `lib/core/config.dart` **or** run:

```
flutter run --dart-define=API_URL=http://192.168.1.20:5231/api
```

Quick test: open `http://192.168.1.20:5231/swagger` in the phone's browser.
(Android emulator on the same machine as the API: `http://10.0.2.2:5231/api`.)

## 3. Allow plain-HTTP (development)

**Android** – `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<application android:usesCleartextTraffic="true" ...>
```

**iOS** – `ios/Runner/Info.plist`

```xml
<key>NSAppTransportSecurity</key>
<dict><key>NSAllowsArbitraryLoads</key><true/></dict>
```

(Use HTTPS with a real domain when you go live, then remove these.)

## 4. API ↔ app map

| Screen / action            | API call                                              |
|----------------------------|-------------------------------------------------------|
| Register                   | `POST /api/auth/register` then `POST /api/auth/login` |
| Sign in                    | `POST /api/auth/login` (guest accounts only)          |
| Rooms list                 | `GET /api/rooms`                                      |
| Availability on room page  | `GET /api/rooms/available?checkIn=&hours=`            |
| Reserve (GCash)            | `POST /api/bookings` `{roomId, rateId, checkIn, referenceCode}` |
| My bookings                | `GET /api/bookings/mine`                              |
| Booking result             | `GET /api/bookings/{id}`                              |
| Cancel booking             | `PATCH /api/bookings/{id}/cancel`                     |
| Rate your stay             | `GET /api/reviews/pending` · `POST /api/reviews`      |
| Edit / list my reviews     | `PUT /api/reviews/{id}` · `GET /api/reviews/mine`     |
| Room ratings               | `GET /api/reviews/room/{roomId}`                      |
| GCash name/number, contact | `GET /api/settings`                                   |

The login token (JWT, ~2 h) is saved on the phone; when it expires the app returns to Sign in.

## 5. What changed vs. the old app (and why)

* **Checkout** – the API takes a GCash **reference number**, not a screenshot, so the receipt upload
  was replaced by a reference field. Price = the room rate (no cleaning/service fees, guests, mobile or
  special-request fields – the API doesn't have them).
* **Removed** – Forgot password and Edit profile (no API endpoint), mock server, demo login.
* **Merged** – "Past stays" is now a tab inside **Bookings** (Upcoming / Past).
* **Saved rooms** – the API has no favourites, so they are stored on the phone per guest.
* **Updates (bell)** – built from the guest's own bookings (the notifications API is staff/admin only).
* **New** – live availability check, room status, room ratings, rate-your-stay, GCash details from settings.
