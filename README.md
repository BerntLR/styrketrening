# Karos Strength Training

A simple strength training log by Team BullPeak, part of the Karo app family.
Published on the App Store as **BullPeak Styrketrening** (id6755542972).

## Features

- Exercises with three sets each (weight and reps)
- Shows the last session per exercise and days since
- Optional rest timer between sets
- Full history per exercise; swipe to edit or delete
- Export/import of all data as a JSON backup
- Tip jar (in-app purchases `tip_29_nok`, `tip_59_nok`, `tip_99_nok`)

All data is stored locally on the device (`shared_preferences`).
There is no account or backend.

## Structure

```
lib/
  main.dart                 App and theme
  intro/intro_gate.dart     Emblem + random comic intro
  l10n/app_strings.dart     All user-facing texts
  models/                   Exercise, ExerciseSet, ExerciseSession
  pages/                    Exercise list, detail, history, info
  services/                 Storage, backup, tip jar
  utils/formatting.dart     Date helpers
  widgets/watermark.dart    Background watermark
assets/                     Intro, watermark, icon and splash images
```

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

App icon and splash screen are generated from `assets/icon/icon.png` and
`assets/karo.png`:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Platforms: iOS and Android only.
