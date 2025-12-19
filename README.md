# VerhuurAgenda Flutter App

Native iOS en Android app voor VerhuurAgenda vakantieverhuur beheer.

## Vereisten

- Flutter SDK 3.2.0 of hoger
- Dart 3.2.0 of hoger
- Android Studio of VS Code met Flutter extensie
- Xcode (voor iOS development)
- Firebase project (voor push notifications)

## Setup

### 1. Flutter installeren
```bash
# Volg de officiële instructies op:
# https://docs.flutter.dev/get-started/install
```

### 2. Project dependencies installeren
```bash
cd verhuuragenda_app
flutter pub get
```

### 3. Code generatie (voor Retrofit, Riverpod, etc.)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Firebase configureren

1. Maak een Firebase project aan op https://console.firebase.google.com
2. Voeg iOS en Android apps toe
3. Download de configuratiebestanden:
   - `google-services.json` -> `android/app/`
   - `GoogleService-Info.plist` -> `ios/Runner/`

### 5. App draaien

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Of specifiek device
flutter devices
flutter run -d <device-id>
```

## Project Structuur

```
lib/
├── main.dart           # Entry point
├── app.dart            # App widget met routing
├── config/
│   ├── api_config.dart # API endpoints
│   ├── router.dart     # Go Router configuratie
│   └── theme.dart      # App theming
├── core/
│   ├── api/
│   │   └── api_client.dart  # Dio HTTP client
│   └── storage/
│       └── secure_storage.dart  # Token opslag
├── models/             # Data models
│   ├── user.dart
│   ├── booking.dart
│   ├── guest.dart
│   └── accommodation.dart
├── providers/          # Riverpod state management
│   └── auth_provider.dart
├── screens/            # UI schermen
│   ├── auth/
│   ├── dashboard/
│   ├── calendar/
│   ├── bookings/
│   └── ...
└── widgets/            # Herbruikbare widgets
    └── common/
        └── bottom_nav.dart
```

## API Endpoints

De app communiceert met `https://verhuuragenda.nl/api`:

### Authenticatie
- `POST /login` - Inloggen
- `POST /logout` - Uitloggen
- `GET /user` - Huidige gebruiker

### Dashboard
- `GET /dashboard` - Stats en recente boekingen

### Boekingen
- `GET /bookings` - Lijst (met filters)
- `POST /bookings` - Aanmaken
- `GET /bookings/{id}` - Details
- `PUT /bookings/{id}` - Bewerken
- `DELETE /bookings/{id}` - Verwijderen
- `PATCH /bookings/{id}/status` - Status wijzigen

### Accommodaties
- `GET /accommodations` - Lijst
- `GET /accommodations/{id}` - Details

### Gasten
- `GET /guests` - Lijst
- `GET /guests/{id}` - Details

### Kalender
- `GET /calendar` - Kalenderdata

### Schoonmaak
- `GET /cleaning` - Schoonmaakschema
- `POST /cleaning/{booking}/complete` - Markeer als schoon

### Onderhoud
- `GET /maintenance` - Lijst taken
- `POST /maintenance` - Aanmaken
- `PATCH /maintenance/{id}/status` - Status wijzigen

### Statistieken
- `GET /statistics` - KPIs en grafieken

### Profiel
- `GET /profile` - Host profiel
- `PUT /profile` - Profiel bewerken

### Campagnes
- `GET /campaigns` - Lijst (readonly)
- `GET /campaigns/{id}` - Details

## Build voor productie

### Android
```bash
flutter build apk --release
# of voor app bundle:
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Push Notifications

De app gebruikt Firebase Cloud Messaging (FCM).

1. Device token registreren na login:
```dart
POST /notifications/register
{
  "token": "<fcm-token>",
  "device_type": "ios|android"
}
```

2. Voorkeuren instellen:
```dart
PUT /notifications/preferences
{
  "new_booking": true,
  "booking_reminder": true,
  "payment_received": true
}
```

## Features

- Dashboard met statistieken
- Kalender met boekingsoverzicht
- Boekingen beheren (CRUD)
- Accommodaties bekijken
- Gasten beheren
- Schoonmaak planning
- Onderhoud taken
- Campagne statistieken (readonly)
- Push notificaties
- Offline caching met Hive
- Biometrische login (Face ID / Fingerprint)

## Volgende stappen

1. Firebase project opzetten
2. iOS en Android signing configureren
3. Schermen verder uitwerken
4. Unit tests schrijven
5. TestFlight / Play Console setup
6. App Store beschrijvingen en screenshots

## Support

Vragen? Neem contact op via support@verhuuragenda.nl
