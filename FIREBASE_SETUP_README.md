# Firebase Setup Guide

## Issue Description
The app is currently experiencing Firebase initialization errors because the required Firebase configuration files are missing. The error message indicates:
```
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()
```

## Required Firebase Configuration Files

### For Android
1. **File**: `google-services.json`
2. **Location**: `android/app/google-services.json`
3. **Source**: Download from Firebase Console

### For iOS
1. **File**: `GoogleService-Info.plist`
2. **Location**: `ios/Runner/GoogleService-Info.plist`
3. **Source**: Download from Firebase Console

## How to Get These Files

### Step 1: Firebase Console Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Add your app to the project:
   - For Android: Use package name `akari.versetech.net`
   - For iOS: Use bundle identifier `akari.versetech.net`

### Step 2: Download Configuration Files
1. **For Android**:
   - In Firebase Console, go to Project Settings
   - Under "Your apps", find your Android app
   - Download `google-services.json`
   - Place it in `android/app/google-services.json`

2. **For iOS**:
   - In Firebase Console, go to Project Settings
   - Under "Your apps", find your iOS app
   - Download `GoogleService-Info.plist`
   - Place it in `ios/Runner/GoogleService-Info.plist`

### Step 3: Add to Xcode (iOS only)
1. Open your project in Xcode
2. Right-click on the Runner folder
3. Select "Add Files to Runner"
4. Choose the `GoogleService-Info.plist` file
5. Make sure it's added to the Runner target

## Current App Behavior
The app has been updated to handle missing Firebase configuration gracefully:
- Firebase initialization errors are caught and logged
- The app continues to function without Firebase features
- Push notifications and analytics will not work until configuration is added
- All other app features remain functional

## Verification
After adding the configuration files:
1. Clean and rebuild the project
2. Check the logs for Firebase initialization success messages
3. Test push notifications if needed

## Troubleshooting
- If you still see Firebase errors after adding the files, try:
  - `flutter clean`
  - `flutter pub get`
  - Rebuild the project
- Make sure the package name/bundle identifier matches exactly
- Verify the files are in the correct locations
- Check that the files are not corrupted during download

## Note
The Firebase configuration files contain sensitive project information and should not be committed to version control. They are already listed in `.gitignore` to prevent accidental commits. 