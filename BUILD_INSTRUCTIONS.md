# AlClock - Build Instructions

## Talablar

- Flutter 3.24 yoki yuqori versiya
- Dart SDK
- Android Studio / Xcode (platformaga qarab)

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

1. **Release APK yaratish:**
```bash
flutter build apk --release
```

2. **APK fayl joylashuvi:**
```
build/app/outputs/flutter-apk/app-release.apk
```

3. **Split APK yaratish (har bir ABI uchun alohida):**
```bash
flutter build apk --split-per-abi
```

## iOS Build

1. **iOS build:**
```bash
flutter build ios --release
```

2. Xcode orqali archive va App Store'ga yuklash

## Development

1. **Development mode:**
```bash
flutter run
```

2. **Hot reload:** `r` tugmasini bosing
3. **Hot restart:** `R` tugmasini bosing

## Eslatmalar

- Birinchi marta build qilishdan oldin `build_runner` ishga tushirish kerak
- Android uchun `SCHEDULE_EXACT_ALARM` permission kerak
- iOS uchun notification permission so'raladi

