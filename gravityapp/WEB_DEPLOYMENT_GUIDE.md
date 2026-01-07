# Running Gravity App in Chrome Browser

## Quick Start

To run the Flutter app in Chrome browser, use the following command:

```bash
flutter run -d chrome
```

Or for a specific Chrome profile:

```bash
flutter run -d chrome --web-port=8080
```

## Prerequisites

1. **Flutter SDK** - Ensure Flutter is installed and configured
2. **Chrome Browser** - Latest version recommended
3. **Web Support Enabled** - Flutter web support should be enabled

### Check Flutter Web Support

```bash
flutter doctor
```

Ensure you see:
```
[✓] Chrome - develop for the web
```

If not, enable web support:
```bash
flutter config --enable-web
```

## Running the App

### Development Mode

```bash
# Run in Chrome with hot reload
flutter run -d chrome

# Run with specific port
flutter run -d chrome --web-port=8080

# Run in release mode (faster, no hot reload)
flutter run -d chrome --release
```

### Build for Web

```bash
# Build for web (creates files in build/web/)
flutter build web

# Build with specific base href
flutter build web --base-href="/gravity/"
```

### Serve Built App Locally

After building, you can serve the app:

```bash
# Using Python (if installed)
cd build/web
python -m http.server 8000

# Using Node.js http-server (if installed)
npx http-server build/web -p 8000
```

Then open: `http://localhost:8000`

## Web Compatibility Notes

### ✅ Features That Work on Web

- ✅ Authentication (Email/Password, Google Sign-In)
- ✅ API calls and network requests
- ✅ UI components and navigation
- ✅ Local storage (GetStorage)
- ✅ Image upload (via file picker)
- ✅ Community features
- ✅ Messaging
- ✅ Settings and preferences
- ✅ Dashboard (without health sync)

### ⚠️ Features with Limited/No Web Support

1. **Health Data Sync** ❌
   - The `health` package only works on iOS/Android
   - Health sync features will be disabled on web
   - The app already handles this gracefully with `kIsWeb` checks

2. **Apple Sign-In** ❌
   - `sign_in_with_apple` package is iOS/macOS only
   - Apple Sign-In button will not work on web
   - Users can still use Email/Password or Google Sign-In

3. **Image Cropper** ⚠️
   - `image_cropper` has limited web support
   - May need alternative implementation for web

4. **Permission Handler** ⚠️
   - Some permissions are mobile-only
   - Web uses browser permissions instead

5. **Orientation Lock** ⚠️
   - SystemChrome orientation lock doesn't apply to web
   - Web browsers handle orientation differently

## Firebase Configuration for Web

If you're using Firebase, you need to configure it for web:

1. **Add Firebase Web Config:**
   - Go to Firebase Console
   - Select your project
   - Go to Project Settings > General
   - Under "Your apps", click the web icon (`</>`)
   - Register your web app
   - Copy the Firebase configuration

2. **Add to `web/index.html`:**
   ```html
   <head>
     <!-- Firebase SDK -->
     <script src="https://www.gstatic.com/firebasejs/10.0.0/firebase-app.js"></script>
     <script src="https://www.gstatic.com/firebasejs/10.0.0/firebase-auth.js"></script>
     <script>
       // Your Firebase config
       const firebaseConfig = {
         apiKey: "YOUR_API_KEY",
         authDomain: "YOUR_AUTH_DOMAIN",
         projectId: "YOUR_PROJECT_ID",
         // ... other config
       };
       firebase.initializeApp(firebaseConfig);
     </script>
   </head>
   ```

   **OR** use Flutter's Firebase initialization (recommended):
   - The app already initializes Firebase in `main.dart`
   - Ensure Firebase is properly configured in your project

## Troubleshooting

### Issue: "Platform.isIOS" or "Platform.isAndroid" errors

**Solution:** The code has been updated to use `kIsWeb` checks. If you see these errors:
- Ensure you're using the latest code with web compatibility fixes
- The `main.dart` file now properly handles web platform

### Issue: Firebase not working on web

**Solution:**
1. Check Firebase web configuration
2. Ensure Firebase is initialized before use
3. Check browser console for errors
4. Verify Firebase project settings allow web domain

### Issue: CORS errors

**Solution:**
- If your API has CORS restrictions, ensure your web domain is allowed
- For development, you may need to configure CORS on your backend
- Check browser console for specific CORS error messages

### Issue: Images not loading

**Solution:**
- Ensure assets are properly declared in `pubspec.yaml`
- Check that `assets/images/` path is correct
- Verify image paths in code match asset paths

### Issue: Health sync errors

**Solution:**
- This is expected on web - health sync is mobile-only
- The app should handle this gracefully
- Health-related features will be disabled on web

## Development Tips

1. **Hot Reload:** Works in Chrome during development
   - Press `r` in terminal to hot reload
   - Press `R` to hot restart

2. **Chrome DevTools:**
   - Right-click → Inspect to open DevTools
   - Use for debugging, network monitoring, etc.

3. **Responsive Testing:**
   - Use Chrome DevTools device emulation
   - Test different screen sizes
   - The app uses `flutter_screenutil` for responsive design

4. **Performance:**
   - Use `--release` flag for better performance
   - Check Chrome DevTools Performance tab
   - Monitor network requests

## Build for Production

```bash
# Build optimized web app
flutter build web --release

# Build with specific base href (if deploying to subdirectory)
flutter build web --base-href="/gravity/"

# Build with source maps (for debugging)
flutter build web --source-maps
```

The built files will be in `build/web/` directory.

## Deployment Options

1. **Firebase Hosting:**
   ```bash
   firebase init hosting
   firebase deploy
   ```

2. **GitHub Pages:**
   - Build web app
   - Push `build/web/` to `gh-pages` branch

3. **Netlify/Vercel:**
   - Connect your repository
   - Set build command: `flutter build web`
   - Set publish directory: `build/web`

4. **Traditional Web Server:**
   - Upload `build/web/` contents to your web server
   - Ensure server supports SPA routing (redirect all routes to `index.html`)

## Summary

The Gravity app is now configured to run in Chrome browser. Most features work on web, with health sync being the main mobile-only feature. The app gracefully handles platform differences and will work well for web deployment.

**Quick Command:**
```bash
flutter run -d chrome
```

