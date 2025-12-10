# Alarm Sound Files

Place your alarm sound files here in `.m4a` format (iOS-friendly).

## Required Files

- `alarm1.m4a` - Sunrise Bell
- `alarm2.m4a` - Digital Alarm
- `alarm3.m4a` - Soft Piano
- `alarm4.m4a` - Bird Morning
- `alarm5.m4a` - Ocean Waves

## iOS Setup

For iOS notifications to play custom sounds, you must also:

1. Copy the same files (or `.wav` versions) to `ios/Runner/Resources/`
2. Add them to Xcode project:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select the files in `ios/Runner/Resources/`
   - In the right panel, check "Target Membership" for "Runner"
   - Go to Build Phases → Copy Bundle Resources
   - Ensure the sound files are listed there

## Android Setup

For Android, copy `.mp3` versions to:
- `android/app/src/main/res/raw/alarm1.mp3`
- `android/app/src/main/res/raw/alarm2.mp3`
- etc.

## File Format Notes

- iOS prefers `.m4a` or `.wav` for notification sounds
- Android uses `.mp3` files in `res/raw/`
- Flutter assets can use `.m4a` or `.mp3` for preview playback


