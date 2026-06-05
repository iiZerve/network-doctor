# Network Doctor - Build & Release Guide

**v1.0.0** - Ready for initial Play Store submission.

## v1.0.0 UI Cleanups (done for this release)
- Removed "● 100% Local" from the top-right header.
- Removed the small "LIVE" badge from the LOSS (packet loss %) metric card in the top metrics row.
- Bumped versionCode=1, versionName="1.0.0" in build.gradle.

The root `index.html` is the source of truth. On build it is copied to `www/index.html` for the native app.

All previous crash fixes (runtime notification permission request, try/catch in foreground service, etc.) are included.

## Current Status
- Debug .apk is buildable and testable.
- Uses Capacitor 6 + Android.
- Web content served from `www/` (copy of `index.html` + future assets).
- Basic foreground service + notification for monitoring support.
- Icons generated and placed.

## 1. Testable Debug APK (already done in setup)
- Run: `npm run build:android:debug`
- Or manually: `npx cap sync android && cd android && .\gradlew.bat assembleDebug`
- APK location: `android\app\build\outputs\apk\debug\app-debug.apk`
- Also copied to `network-doctor-debug.apk` in project root.
- Install on device with `adb install network-doctor-debug.apk` or via Android Studio / file transfer.
- When running, the app will show a persistent "Network Doctor - Background monitoring active" notification (from the foreground service). This is required for reliable background operation on modern Android.

To open the project in Android Studio for debugging: `npm run open:android`

**If Android Studio shows the "Select Android SDK" dialog (empty path with red border):**
- Click the folder icon next to the input field.
- Browse to and select: `C:\Android\android-sdk`
- Click OK.

Android Studio may then download additional components or ask you to accept licenses inside its SDK Manager. After that, sync the project (File > Sync Project with Gradle Files).

**Environment variables needed for terminal builds and for Studio to find everything easily** (set these in a PowerShell session before running npm/gradle commands, or set them permanently in Windows System Environment Variables):
```powershell
$env:ANDROID_HOME = "C:\Android\android-sdk"
$env:JAVA_HOME  = "C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot"
```
(After permanent changes, run `refreshenv` in existing terminals or restart them.)

## 2. Proper Structure for Icons, Config, Background Handling

### Icons
- Source icon: `assets/network-doctor-icon-1024.png`
- Android mipmap icons auto-generated in `android/app/src/main/res/mipmap-*/ic_launcher*.png`
- To update icons later:
  1. Replace source PNG (1024x1024 recommended).
  2. Re-run icon generation script or use Android Asset Studio / ImageMagick.
  3. `npx cap sync` (icons are in native, not web assets).
  4. Rebuild.

### Config
- `capacitor.config.json` at root (and copied to android assets on sync).
- Updated with webDir, splash prefs, etc.
- Edit and `npx cap sync` to apply.

### Background Handling
- `MonitoringForegroundService.java` provides a sticky foreground service.
- Declared in `AndroidManifest.xml` with FOREGROUND_SERVICE, POST_NOTIFICATIONS, etc. permissions.
- Started automatically from `MainActivity.onCreate()`.
- The web JS (monitoring code with 3 tiers: active/passive/smart-boost) controls *when* to do expensive checks.
- Current JS monitoring uses setInterval (works great while app/webview is alive).
- For checks to continue when app is closed/backgrounded (Doze etc.), enhance the service to perform native polling or use AlarmManager/WorkManager that can wake the webview or send events via Capacitor plugin.
- See the large "ANDROID / CAPACITOR ARCHITECTURE RECOMMENDATIONS" comment in index.html for detailed guidance (uses @capacitor/background-runner or WorkManager).
- The notification is currently shown whenever the app is launched (to keep the monitoring process at high priority). It says "Active - open app for monitoring controls & real diagnostics". You can improve this later by wiring the JS "Background monitoring" checkbox to start/stop the native service via a small Capacitor plugin.
- The actual JS-based monitoring (real TCP checks for LOSS and history) runs while the app/WebView is active. The foreground service helps prevent aggressive killing when the user backgrounds the app. For checks to continue after the app is fully closed (rare for JS), see the architecture comments in index.html for WorkManager recommendations.

To extend:
- Create a small Capacitor plugin (or use community one) to control the service from the web layer based on the "Background monitoring" toggle.
- Update the JS to call native when toggling.

## 3. Path to Release .aab

### Prerequisites
- Android SDK + build tools: `C:\Android\android-sdk`
- JDK 17: `C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot`
- See the "If Android Studio shows the Select Android SDK dialog" section above for how to point everything to these paths (both in Studio settings and in your shell via $env:ANDROID_HOME / $env:JAVA_HOME).
- A release keystore (generate one-time with a STRONG unique password, e.g. a long random one):
  ```
  keytool -genkey -v -keystore network-doctor-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias networkdoctor
  ```
  (We created one with a temp password "changeit123!" for the current .aab - you MUST change it before real use or upload!)
  Store the jks file and passwords securely (never commit to git, backup offline). Update the storePassword and keyPassword in android/app/build.gradle before rebuilding the final .aab.

### Build Release AAB
1. Update `android/app/build.gradle` (the app one) with signing config (see standard Capacitor release docs or copy from your other projects' packages).
   Example (in android/app/build.gradle):
   ```groovy
   signingConfigs {
       release {
           storeFile file("network-doctor-release-key.jks")
           storePassword "YOUR_PASSWORD"
           keyAlias "networkdoctor"
           keyPassword "YOUR_PASSWORD"
       }
   }
   buildTypes {
       release {
           signingConfig signingConfigs.release
           minifyEnabled false  // or true + proguard
       }
   }
   ```

2. `npx cap sync android`

3. `cd android ; .\gradlew.bat bundleRelease`

4. The .aab will be at: `android\app\build\outputs\bundle\release\app-release.aab`

5. (Optional script in package.json: add "build:android:release": "..." )

### Play Store Submission Path
- Use the same process as your other apps (see hourly-rate-calculator/web-version/PLAY_CONSOLE_SUBMISSION_CHECKLIST.md , PLAY_STORE_PUBLISHING_GUIDE.md etc. for templates).
- Create app in Play Console with package `com.iiZerve.networkdoctor`
- Upload the .aab to internal test / production track.
- Fill listing: use content from current README + features (emphasize 100% local, real diagnostics, battery-friendly monitoring).
- Provide:
  - High-res icon (from assets)
  - Feature graphic
  - Screenshots (run the debug apk on emulator/device, take screenshots of main screens, charts, tools panel)
  - Privacy policy (create PRIVACY_POLICY.md - app does no PII collection, only anonymous network probes to public DNS/hosts for diagnostics)
- Content rating: Tools / Productivity, no ads, no user data collection really.
- After first upload, Google review (can take 1-7 days for new apps).

### Recommended Next Polish Before First Release
- Make more of the "live" data real where feasible (or clearly label the Performance charts as "Trend Visualization (illustrative)" vs real LOSS / tools).
- Add a Capacitor plugin or JS bridge to control the foreground service from the monitoring toggle.
- Bundle CDNs locally or use a simple build step (e.g. vite) for self-contained assets.
- Add PWA manifest + sw.js for installable on web too (copy pattern from other projects).
- Test thoroughly: long running monitoring, battery, different networks, dark/light (currently dark), offline behavior.
- Update the note in showPacketDetails if needed.
- Generate better multi-density + adaptive icons (the current ones are raster scaled).

Run `npm run build:android:debug` anytime after web changes + `npx cap sync android` to refresh the APK.

For full release pipeline, model after your Rateforge/ other published apps' docs.

## Play Store Graphic Assets (v1.0.0)

All assets generated to match the app icon theme (dark modern tech, blue/teal network elements, dark gradient, clean professional) and based on the actual app UI from the provided phone screenshots.

Location: `assets/play-store-assets/`

- **App Icon**: app-icon-512.png (512x512)
- **Feature Graphic**: feature-graphic-1024x500.png (resized to 1024x500)
- **Phone Screenshots** (use 2-8 as needed, portrait):
  - phone-screenshot-1-main.png (main metrics + charts view)
  - phone-screenshot-2-monitoring.png (real-time monitoring section)
  - phone-screenshot-3-tools.png (diagnostic tools + results)
  - phone-screenshot-4-loss.png (packet loss details)
- **7" Tablet Screenshots** (portrait, based directly on the three actual phone screenshots provided):
  - tablet7-screenshot-1-main.png (from phone main screen)
  - tablet7-screenshot-2-monitoring.png (from phone monitoring view)
  - tablet7-screenshot-3-tools.png (from phone tools view)
- **10" Tablet Screenshots** (landscape for better wide UI view, based directly on the three actual phone screenshots):
  - tablet10-screenshot-1-landscape.png (from phone main screen)
  - tablet10-screenshot-2-monitoring.png (from phone monitoring view)
  - tablet10-screenshot-3-tools.png (from phone tools view)

These are high-quality PNG mockups ready for upload. For final, you may want to capture real device screenshots from the debug APK on a tablet emulator for perfect pixel match, but these capture the exact current UI after your requested removals.

The previous AI mockups without the actual screenshots have been superseded by these based on your provided phone images.

## Play Store Graphic Assets (Generated for v1.0.0)

All assets are in `assets/play-store-assets/` as PNG files, following the exact theme of the app icon (dark modern tech background, blue and teal network elements, clean professional styling) and derived directly from the three actual phone screenshots you provided (transformed to tablet frames while preserving 100% of the UI content, text, values, charts, colors, and layout).

- **App Icon**: app-icon-512.png (512x512 px)
- **Feature Graphic**: feature-graphic-1024x500-exact.png (exact 1024x500 px)
- **Phone Screenshots** (portrait, ready for use or further high-res capture from device):
  - phone-screenshot-1-main.png (main screen with metrics and Performance Over Time)
  - phone-screenshot-2-monitoring.png (Real-time Monitoring section)
  - phone-screenshot-3-tools.png (Diagnostic Tools and results)
  - phone-screenshot-4-loss.png (additional loss/details view)
- **7" Tablet Screenshots** (portrait, based directly on your three provided phone screenshots):
  - tablet7-screenshot-1-main.png (from your first phone screenshot)
  - tablet7-screenshot-2-monitoring.png (from your second phone screenshot)
  - tablet7-screenshot-3-tools.png (from your third phone screenshot)
- **10" Tablet Screenshots** (landscape, based directly on your three provided phone screenshots for better wide layout view):
  - tablet10-screenshot-1-landscape.png (from your first phone screenshot)
  - tablet10-screenshot-2-monitoring.png (from your second phone screenshot)
  - tablet10-screenshot-3-tools.png (from your third phone screenshot)

These are high quality and match the current app UI after your requested UI cleanups (no 100% Local badge, no LIVE on the packet loss card).

For the absolute best final submission, after installing the debug APK on a tablet emulator or device, capture real screenshots and replace these mockups if you want pixel-perfect match to the live app. But these capture the exact current state.

The assets are ready to upload with the release AAB.
