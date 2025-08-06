# iOS App Store Release Checklist

## 🔥 **Critical: Firebase Setup**
- [ ] Download `GoogleService-Info.plist` from Firebase Console
- [ ] Place file in `ios/Runner/GoogleService-Info.plist`
- [ ] Add file to Xcode project (Runner target)
- [ ] Verify Firebase initialization in logs

## 📱 **Apple Developer Account Setup**
- [ ] Active Apple Developer Account ($99/year)
- [ ] App Store Connect access
- [ ] Distribution certificate created
- [ ] App Store provisioning profile created
- [ ] Bundle ID: `akari.versetech.net` registered

## 🏗️ **Xcode Configuration**
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Select "Runner" target
- [ ] Set Bundle Identifier: `akari.versetech.net`
- [ ] Set Display Name: "عقاري"
- [ ] Set Version: `1.0.0` (from pubspec.yaml)
- [ ] Set Build: `147` (from pubspec.yaml)

## 🔐 **Code Signing & Capabilities**
- [ ] Select "Automatically manage signing"
- [ ] Choose your Team
- [ ] Verify Bundle Identifier matches
- [ ] Add Push Notifications capability
- [ ] Add Background Modes capability
- [ ] Select "Remote notifications" and "Background processing"

## 📋 **App Store Connect Setup**
- [ ] Create new app in App Store Connect
- [ ] Bundle ID: `akari.versetech.net`
- [ ] App Name: "عقاري"
- [ ] Primary Language: Arabic
- [ ] Category: Real Estate
- [ ] Content Rights: No
- [ ] Age Rating: 4+

## 🖼️ **App Store Assets**
- [ ] App Icon (1024x1024 PNG)
- [ ] Screenshots for iPhone (6.7", 6.5", 5.5")
- [ ] Screenshots for iPad (12.9", 11")
- [ ] App Preview videos (optional)
- [ ] App description in Arabic
- [ ] Keywords for App Store optimization

## 📝 **App Store Metadata**
- [ ] App Name: "عقاري"
- [ ] Subtitle: "تطبيق العقارات"
- [ ] Description in Arabic
- [ ] Keywords (comma-separated)
- [ ] Support URL
- [ ] Marketing URL (optional)
- [ ] Privacy Policy URL

## 🔒 **Privacy & Legal**
- [ ] Privacy Policy created and hosted
- [ ] Terms of Service created and hosted
- [ ] App Privacy details in App Store Connect
- [ ] Data collection practices documented

## 🧪 **Testing**
- [ ] Test on physical iOS devices
- [ ] Test push notifications
- [ ] Test all app features
- [ ] Test with different iOS versions
- [ ] Test with different screen sizes

## 📦 **Build & Archive**
- [ ] Run `flutter build ios --release`
- [ ] Open Xcode workspace
- [ ] Select "Any iOS Device" as target
- [ ] Product > Archive
- [ ] Verify archive created successfully

## 🚀 **Upload & Submit**
- [ ] Upload archive to App Store Connect
- [ ] Fill all required metadata
- [ ] Add screenshots and descriptions
- [ ] Set up app privacy
- [ ] Submit for review

## ⚠️ **Common Issues to Check**
- [ ] No deprecated APIs used
- [ ] All permissions have proper descriptions
- [ ] App doesn't crash on launch
- [ ] No placeholder content
- [ ] All links work properly
- [ ] App follows Apple's Human Interface Guidelines

## 🔄 **After Submission**
- [ ] Monitor review status
- [ ] Respond to any review feedback
- [ ] Prepare for potential rejection reasons
- [ ] Have backup plan for quick fixes

## 📊 **Post-Release**
- [ ] Monitor crash reports
- [ ] Track user feedback
- [ ] Plan for updates
- [ ] Monitor App Store analytics

---

## 🚨 **Critical Missing Items**
1. **Firebase Configuration**: `GoogleService-Info.plist` is missing
2. **App Store Connect**: App not created yet
3. **Code Signing**: Certificates and profiles needed
4. **App Store Assets**: Screenshots and metadata needed

## 📞 **Next Steps**
1. Get Firebase configuration file
2. Set up Apple Developer account
3. Create app in App Store Connect
4. Build and test thoroughly
5. Submit for review 