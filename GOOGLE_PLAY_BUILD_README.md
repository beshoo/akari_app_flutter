# 🚀 App Store Build & Deployment Guide

This guide explains how to build and deploy the Akari Flutter app to **Google Play Store (Android)** and **App Store (iOS)**.

## 📋 Prerequisites

### Required Tools
- **Flutter SDK** (latest stable version)
- **Android Studio** with Android SDK (for Android builds)
- **Xcode** (latest version, macOS only - for iOS builds)
- **Java Development Kit (JDK)** 11 or higher
- **PowerShell** (for Windows build scripts)
- **macOS** (required for iOS builds)

### Store Setup
#### Google Play Console (Android)
1. **Google Play Developer Account** ($25 one-time fee)
2. **App created** in Google Play Console
3. **Upload key generated** and configured

#### App Store Connect (iOS)
1. **Apple Developer Account** ($99/year)
2. **App created** in App Store Connect
3. **iOS certificates and provisioning profiles** configured

---

## 🔐 Step 1: Generate Upload Key (First Time Only)

### Create Upload Key
```cmd
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Important:** 
- Store the keystore file in a secure location
- Remember the passwords (you'll need them for every build)
- **Never commit the keystore to version control**

### Configure Key Properties
Create `android/key.properties`:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=upload
storeFile=../upload-keystore.jks
```

### Update android/app/build.gradle.kts
Add this configuration (should already be done):
```kotlin
android {
    ...
    signingConfigs {
        release {
            keyAlias = keystoreProperties['keyAlias']
            keyPassword = keystoreProperties['keyPassword']
            storeFile = file(keystoreProperties['storeFile'])
            storePassword = keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.release
        }
    }
}
```

---

## 📦 Step 2: Version Management

### Understanding Flutter Versioning
```yaml
# pubspec.yaml
version: 1.2.3+45
#        ^^^^^ ^^
#        |     build number (internal, must increase for each upload)
#        version name (what users see: major.minor.patch)
```

### Version Increment Scripts

#### Option A: Interactive Batch File (Easiest)
```cmd
# Double-click or run:
increment_version.bat
```
**Menu Options:**
1. **Build number only** - For quick builds/testing
2. **Patch version** - Bug fixes (1.0.0 → 1.0.1)
3. **Minor version** - New features (1.0.0 → 1.1.0)
4. **Major version** - Breaking changes (1.0.0 → 2.0.0)

#### Option B: PowerShell Commands (Advanced)
```powershell
# Patch release (recommended for most updates)
.\increment_version_advanced.ps1 -Type patch -Build

# Minor release (new features)
.\increment_version_advanced.ps1 -Type minor -Build

# Major release (breaking changes)
.\increment_version_advanced.ps1 -Type major -Build

# Just increment build number (for testing)
.\increment_version_advanced.ps1 -Type build -Build
```

---

## 🏗️ Step 3: Build for Production

### Automated Build (Recommended)
Use the version increment scripts which automatically:
1. ✅ Update version in `pubspec.yaml`
2. ✅ Clean the project
3. ✅ Get dependencies
4. ✅ Build signed AAB file

### Manual Build Process
If you prefer manual steps:

```cmd
# 1. Clean project
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Build Android App Bundle (AAB)
flutter build appbundle --release

# 4. Verify build
echo "AAB file location: build/app/outputs/bundle/release/app-release.aab"
```

---

## 📱 Step 4: Pre-Upload Verification

### Check AAB File
```cmd
# Verify the AAB file exists
dir build\app\outputs\bundle\release\app-release.aab

# Check file size (should be reasonable, typically 10-50MB)
```

### Test Installation (Optional)
```cmd
# Install AAB locally for testing (requires bundletool)
java -jar bundletool.jar build-apks --bundle=build/app/outputs/bundle/release/app-release.aab --output=test.apks --mode=universal
java -jar bundletool.jar install-apks --apks=test.apks
```

---

## 🚀 Step 5: Upload to Google Play Store

### Google Play Console Steps

1. **Login** to [Google Play Console](https://play.google.com/console/)

2. **Select Your App**

3. **Navigate to Release Management**
   - Go to "Release" → "Production" (or "Internal testing" for first upload)

4. **Create New Release**
   - Click "Create new release"

5. **Upload AAB File**
   - Click "Browse files"
   - Select: `build/app/outputs/bundle/release/app-release.aab`
   - Wait for upload and processing

6. **Review Release Details**
   - ✅ Version name should match your pubspec.yaml
   - ✅ Version code should be incremented
   - ✅ File size should be reasonable

7. **Add Release Notes**
   ```
   Version 1.2.3:
   - Bug fixes and improvements
   - New features added
   - Performance optimizations
   ```

8. **Review and Rollout**
   - Click "Review release"
   - Choose rollout percentage (100% for full release)
   - Click "Start rollout to production"

---

# 🍎 iOS DEPLOYMENT GUIDE

## 🔧 Step 6: iOS Setup & Configuration

### Firebase Configuration for iOS

#### 1. Add iOS App to Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click "Add app" → iOS
4. **Bundle ID**: Use same as `android/app/build.gradle.kts` applicationId
   - Example: `com.example.akari_app`
5. **App nickname**: Akari App (iOS)
6. Download `GoogleService-Info.plist`

#### 2. Add GoogleService-Info.plist to iOS Project
```bash
# Copy the file to iOS project
cp GoogleService-Info.plist ios/Runner/
```

**Important**: 
- Place `GoogleService-Info.plist` in `ios/Runner/` directory
- Add it to Xcode project (drag & drop in Xcode)
- Ensure it's added to the Runner target

#### 3. Update iOS Firebase Configuration
The Firebase configuration should already be set up in your Flutter code. Verify these files exist:
- `lib/services/firebase_messaging_service.dart` ✅
- Firebase initialization in `lib/main.dart` ✅

### iOS Certificates & Provisioning Profiles

#### 1. Create App ID (First Time Only)
1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to "Certificates, Identifiers & Profiles"
3. Click "Identifiers" → "+"
4. Select "App IDs" → "App"
5. **Bundle ID**: Same as your Flutter app (e.g., `com.example.akari_app`)
6. **Capabilities**: Enable Push Notifications, Background Modes

#### 2. Create Distribution Certificate
```bash
# Generate Certificate Signing Request (CSR)
# Use Keychain Access → Certificate Assistant → Request from Certificate Authority
```

1. In Keychain Access: Create CSR
2. Upload CSR to Apple Developer Portal
3. Download and install the certificate

#### 3. Create Distribution Provisioning Profile
1. Apple Developer Portal → "Profiles" → "+"
2. Select "App Store" → Continue
3. Select your App ID
4. Select your Distribution Certificate
5. Download and install the profile

---

## 📱 Step 7: iOS Version Management & Building

### iOS Version Scripts

#### Create iOS Build Script
Create `increment_version_ios.ps1`:

```powershell
param(
    [string]$Type = "build",  # Options: "build", "patch", "minor", "major"
    [switch]$Build = $false   # Build after incrementing
)

# Read current version from pubspec.yaml
$content = Get-Content pubspec.yaml
$versionLine = $content | Where-Object { $_ -match "^version:" }
$versionParts = $versionLine -split "\+"
$versionName = ($versionParts[0] -split ":")[1].Trim()
$buildNumber = [int]$versionParts[1]

Write-Host "Current version: $versionName+$buildNumber"

# Parse version name parts
$versionNameParts = $versionName -split "\."
$major = [int]$versionNameParts[0]
$minor = [int]$versionNameParts[1]
$patch = [int]$versionNameParts[2]

$newVersionName = $versionName
$newBuildNumber = $buildNumber

switch ($Type) {
    "build" {
        $newBuildNumber = $buildNumber + 1
        Write-Host "Incrementing build number..."
    }
    "patch" {
        $patch = $patch + 1
        $newVersionName = "$major.$minor.$patch"
        $newBuildNumber = 1
        Write-Host "Incrementing patch version..."
    }
    "minor" {
        $minor = $minor + 1
        $patch = 0
        $newVersionName = "$major.$minor.$patch"
        $newBuildNumber = 1
        Write-Host "Incrementing minor version..."
    }
    "major" {
        $major = $major + 1
        $minor = 0
        $patch = 0
        $newVersionName = "$major.$minor.$patch"
        $newBuildNumber = 1
        Write-Host "Incrementing major version..."
    }
}

# Update pubspec.yaml
$newContent = $content -replace "version: $versionName\+$buildNumber", "version: $newVersionName+$newBuildNumber"
$newContent | Set-Content pubspec.yaml -Force

Write-Host "Version updated from $versionName+$buildNumber to $newVersionName+$newBuildNumber"

if ($Build) {
    Write-Host "`nBuilding iOS app..."
    
    # Clean project
    flutter clean
    
    # Get dependencies
    flutter pub get
    
    # Build iOS app
    flutter build ios --release
    
    Write-Host "`nTo complete the build:"
    Write-Host "1. Open ios/Runner.xcworkspace in Xcode"
    Write-Host "2. Select 'Any iOS Device (arm64)' as target"
    Write-Host "3. Product → Archive"
    Write-Host "4. Upload to App Store Connect"
}
```

### iOS Build Process

#### Option A: Automated Script
```powershell
# Increment version and prepare for iOS build
.\increment_version_ios.ps1 -Type patch -Build
```

#### Option B: Manual Steps
```bash
# 1. Update version in pubspec.yaml (use scripts)
.\increment_version_advanced.ps1 -Type patch

# 2. Clean and get dependencies
flutter clean
flutter pub get

# 3. Build iOS (creates .app bundle)
flutter build ios --release

# 4. Continue in Xcode for archive and upload
```

---

## 🏗️ Step 8: Xcode Archive & Upload

### Open in Xcode
```bash
# Open iOS project in Xcode
open ios/Runner.xcworkspace
```

### Xcode Archive Process
1. **Select Target**: "Any iOS Device (arm64)"
2. **Product Menu**: Product → Archive
3. **Wait for Build**: Archive process completes
4. **Organizer Window**: Opens automatically
5. **Distribute App**: Click "Distribute App"
6. **App Store Connect**: Select this option
7. **Upload**: Click "Upload"
8. **Validation**: Wait for validation to complete
9. **Success**: App uploaded to App Store Connect

### Alternative: Command Line Upload
```bash
# Build archive from command line (advanced)
xcodebuild -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -destination generic/platform=iOS \
    -archivePath build/ios/archive/Runner.xcarchive \
    archive

# Upload to App Store Connect
xcrun altool --upload-app \
    --type ios \
    --file build/ios/archive/Runner.xcarchive \
    --username "your-apple-id@email.com" \
    --password "app-specific-password"
```

---

## 📲 Step 9: App Store Connect Management

### Upload Verification
1. **Login** to [App Store Connect](https://appstoreconnect.apple.com/)
2. **Select App**: Choose your app
3. **TestFlight Tab**: Verify build appears
4. **Build Processing**: Wait for processing (10-30 minutes)
5. **Build Available**: Ready for internal testing or review

### Prepare for App Store Review
1. **App Store Tab**: Go to App Store section
2. **Version Information**:
   - What's New: Release notes
   - Keywords: App Store optimization
   - Description: App description
3. **Build Selection**: Choose uploaded build
4. **App Review Information**:
   - Contact info
   - Demo account (if needed)
   - Notes to reviewer
5. **Submit for Review**: Click submit

### iOS Release Process
1. **Internal Testing** (TestFlight): Share with team
2. **External Testing** (TestFlight): Beta testing with users
3. **App Store Review**: Submit for public release
4. **Release**: Approve for App Store publication

---

## 🔥 iOS Firebase Additional Setup

### Push Notifications (APNs)
1. **Apple Developer Portal**:
   - Create APNs Key or Certificate
   - Download .p8 key file

2. **Firebase Console**:
   - Go to Project Settings → Cloud Messaging
   - Upload APNs key or certificate
   - Configure iOS app settings

3. **Code Verification**:
   - Ensure `FirebaseMessaging.instance.requestPermission()` is called
   - Test notifications on physical device

### iOS Background Modes
Update `ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>background-fetch</string>
    <string>background-processing</string>
    <string>remote-notification</string>
</array>
```

---

## ⚠️ Common Issues & Solutions

### Build Errors

**Issue: Build fails with signing errors**
```
Solution: Check android/key.properties file exists and passwords are correct
```

**Issue: "Duplicate files" error**
```
Solution: Add to android/app/build.gradle.kts:
android {
    packagingOptions {
        pickFirst '**/libc++_shared.so'
        pickFirst '**/libjsc.so'
    }
}
```

**Issue: Version code not incrementing**
```
Solution: Always use the increment scripts, don't manually edit pubspec.yaml
```

### Android Upload Issues

**Issue: "You uploaded an APK that is not zip aligned"**
```
Solution: Use AAB file, not APK. AAB files are automatically optimized.
```

**Issue: "Version code X has already been used"**
```
Solution: Increment version using the scripts before building
```

**Issue: "Upload certificate doesn't match"**
```
Solution: Use the same upload-keystore.jks file for all builds
```

### iOS Build & Upload Issues

**Issue: "No profiles for 'com.example.akari_app' were found"**
```
Solution: Create and install Distribution Provisioning Profile in Apple Developer Portal
```

**Issue: "Code signing error: No code signing identities found"**
```
Solution: Install Distribution Certificate in Keychain Access
```

**Issue: "Archive failed: Build input file cannot be found"**
```
Solution: Run 'flutter build ios --release' before opening Xcode
```

**Issue: "Firebase/Messaging module not found"**
```
Solution: Ensure GoogleService-Info.plist is added to Xcode project and Runner target
```

**Issue: "App Store Connect upload fails with ITMS-90xxx error"**
```
Solution: Check Info.plist configurations and ensure all required icons are present
```

**Issue: "TestFlight build not appearing"**
```
Solution: Wait 10-30 minutes for processing, check email for processing notifications
```

---

## 🎯 Quick Release Checklist

### Before Each Release:
- [ ] Test app functionality thoroughly on both platforms
- [ ] Update version using increment script
- [ ] Review release notes
- [ ] Ensure all sensitive data is removed
- [ ] Check app permissions are appropriate
- [ ] Verify Firebase configuration for both platforms

### Android Build Process:
- [ ] Run `increment_version.bat` or PowerShell script
- [ ] Choose appropriate version increment type
- [ ] Wait for build completion
- [ ] Verify AAB file is generated in `build/app/outputs/bundle/release/`

### iOS Build Process:
- [ ] Run `increment_version_ios.ps1` or use existing scripts
- [ ] Execute `flutter build ios --release`
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Archive with "Any iOS Device (arm64)" target
- [ ] Upload to App Store Connect

### Android Upload Process:
- [ ] Login to Google Play Console
- [ ] Upload AAB file
- [ ] Add release notes
- [ ] Review app details
- [ ] Start rollout

### iOS Upload Process:
- [ ] Login to App Store Connect
- [ ] Verify build appears in TestFlight
- [ ] Wait for processing completion
- [ ] Submit for App Store review
- [ ] Approve for release

### Post-Release:
- [ ] Monitor crash reports (Firebase Crashlytics)
- [ ] Check user reviews on both stores
- [ ] Monitor app performance metrics
- [ ] Test push notifications on both platforms

---

## 📊 Version Strategy Recommendations

### Version Types:
- **Patch (1.0.0 → 1.0.1)**: Bug fixes, minor improvements
- **Minor (1.0.0 → 1.1.0)**: New features, significant updates
- **Major (1.0.0 → 2.0.0)**: Breaking changes, complete redesigns

### Build Numbers:
- Build numbers automatically increment with each version change
- For testing builds, use "build" type to only increment build number
- Never manually edit build numbers

---

## 🔗 Useful Links

### Android Resources
- [Google Play Console](https://play.google.com/console/)
- [Flutter Android Build Documentation](https://docs.flutter.dev/deployment/android)
- [Android App Bundle Guide](https://developer.android.com/guide/app-bundle)
- [Google Play Publishing Guidelines](https://support.google.com/googleplay/android-developer/answer/9859348)

### iOS Resources
- [App Store Connect](https://appstoreconnect.apple.com/)
- [Apple Developer Portal](https://developer.apple.com/account/)
- [Flutter iOS Build Documentation](https://docs.flutter.dev/deployment/ios)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Xcode Archive & Upload Guide](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)

### Firebase Resources
- [Firebase Console](https://console.firebase.google.com/)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [Firebase Android Setup](https://firebase.google.com/docs/android/setup)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)

---

## 🆘 Support

If you encounter issues:
1. Check this README first
2. Review Flutter documentation for your platform
3. Check store-specific help:
   - **Android**: Google Play Console help
   - **iOS**: App Store Connect help, Apple Developer Support
4. Search for specific error messages
5. Test on physical devices for both platforms

**Critical Reminders:**
- **Android**: Always backup your upload keystore file! Losing it means you cannot update your app on Google Play Store
- **iOS**: Keep your Apple Developer account active ($99/year) to maintain app updates
- **Firebase**: Ensure both iOS and Android apps are configured in the same Firebase project
- **Version Management**: Use the provided scripts to avoid version conflicts 