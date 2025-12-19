# Google Services Setup Instructions

## Step 1: Get google-services.json from Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one)
3. Click the gear icon ⚙️ next to "Project Overview"
4. Select "Project settings"
5. Scroll down to "Your apps" section
6. Click on the Android app (or click "Add app" → Android if you haven't added it yet)
7. Enter your package name: `com.attoexa.gravityapp`
8. Click "Register app"
9. Download the `google-services.json` file
10. Place it in: `android/app/google-services.json`

## Step 2: Enable Google Sign-In in Firebase

1. In Firebase Console, go to "Authentication" → "Sign-in method"
2. Click on "Google"
3. Enable it and save
4. Add your app's SHA-1 fingerprint:
   - Run: `cd android && ./gradlew signingReport`
   - Copy the SHA-1 from the debug keystore output
   - Add it in Firebase Console → Project Settings → Your apps → Android app → SHA certificate fingerprints

## Step 3: Rebuild the app

```bash
flutter clean
flutter pub get
flutter run
```

## Alternative: Test without Google Sign-In (Temporary)

If you want to test the app without Google Sign-In first, you can temporarily comment out the Google Services plugin in `android/app/build.gradle.kts`:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    // id("com.google.gms.google-services") // Temporarily disabled
    id("dev.flutter.flutter-gradle-plugin")
}
```

**Note:** Google Sign-In will not work with this disabled.

