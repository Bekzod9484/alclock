# iOS Alarm Sounds - Xcode Setup Instructions

## Important: Add Files to Xcode Project

After placing your `.wav` files in this folder, you **MUST** add them to the Xcode project:

### Steps:

1. Open `ios/Runner.xcworkspace` in Xcode (NOT .xcodeproj)

2. In Xcode, right-click on the `Runner` folder in the Project Navigator

3. Select **"Add Files to Runner..."**

4. Navigate to `ios/Runner/AlarmSounds/`

5. Select all `.wav` files:
   - alarm1.wav
   - alarm2.wav
   - alarm3.wav
   - alarm4.wav
   - alarm5.wav

6. **IMPORTANT**: Check these options:
   - ✅ "Copy items if needed" (if files are not already in the project)
   - ✅ "Create groups" (NOT "Create folder references")
   - ✅ Select "Runner" target

7. Click **"Add"**

8. Verify files are in **Build Phases**:
   - Select `Runner` target
   - Go to **"Build Phases"** tab
   - Expand **"Copy Bundle Resources"**
   - Ensure all `.wav` files are listed there
   - If not, click **"+"** and add them manually

### Verification:

After adding, the files should appear in:
- Project Navigator: `Runner/AlarmSounds/*.wav`
- Build Phases → Copy Bundle Resources: All `.wav` files listed

### File Format Requirements:

- **Format**: WAV or CAF
- **Naming**: Lowercase, no spaces (e.g., `alarm1.wav`)
- **Location**: `ios/Runner/AlarmSounds/`

### Troubleshooting:

If sounds don't play:
1. Check file names match exactly: `alarm1.wav`, `alarm2.wav`, etc.
2. Verify files are in "Copy Bundle Resources"
3. Clean build folder: Product → Clean Build Folder (Shift+Cmd+K)
4. Rebuild the app


