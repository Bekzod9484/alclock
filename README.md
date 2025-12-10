# AlClock - Sleep Tracking + Smart Alarm

Flutter 3.24 ilovasi - Clean Architecture, Riverpod, va Hive bilan qurilgan.

## Xususiyatlar

- ✅ Aqlli uyqu aniqlash (ekran yopilishini kuzatish)
- ✅ Haqiqiy alarmlar (Android) / Bildirishnomalar (iOS)
- ✅ Haftalik statistika grafiklar bilan
- ✅ Sozlamalar va shaxsiylashtirish
- ✅ Neumorphic dizayn
- ✅ Glass card effektlari
- ✅ Gradient fon

## O'rnatish

1. **Dependencies o'rnatish:**
```bash
flutter pub get
```

2. **Hive adapters generatsiya qilish:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Android APK Build

```bash
flutter build apk --release
```

APK fayl: `build/app/outputs/flutter-apk/app-release.apk`

## iOS Build

```bash
flutter build ios --release
```

## Development

```bash
flutter run
```

## Loyiha Strukturasi

```
lib/
├── core/              # Asosiy funksiyalar
│   ├── constants/     # Ranglar, o'lchamlar, fontlar
│   ├── models/        # Hive modellar
│   ├── providers/     # Umumiy providerlar
│   ├── theme/         # Tema sozlamalari
│   ├── utils/         # Yordamchi funksiyalar
│   └── widgets/       # Umumiy widgetlar
├── features/          # Funksiyalar
│   ├── alarm/         # Alarm funksiyasi
│   ├── sleep/         # Uyqu kuzatish
│   └── settings/      # Sozlamalar
└── services/          # Servislar
    ├── alarm_service.dart
    ├── sleep_detection_service.dart
    └── notification_service.dart
```

## Eslatmalar

- Birinchi marta build qilishdan oldin `build_runner` ishga tushirish kerak
- Android uchun `SCHEDULE_EXACT_ALARM` permission kerak
- iOS uchun notification permission so'raladi

