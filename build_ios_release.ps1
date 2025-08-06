# iOS App Store Build Script
# Run this script to build your Flutter app for iOS App Store release

Write-Host "🚀 Starting iOS App Store Build Process..." -ForegroundColor Green

# Clean the project
Write-Host "🧹 Cleaning Flutter project..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host "📦 Getting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get

# Build iOS in release mode
Write-Host "🔨 Building iOS release..." -ForegroundColor Yellow
flutter build ios --release --no-codesign

Write-Host "✅ iOS build completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📱 Next steps:" -ForegroundColor Cyan
Write-Host "1. Open ios/Runner.xcworkspace in Xcode" -ForegroundColor White
Write-Host "2. Select 'Runner' target" -ForegroundColor White
Write-Host "3. Go to 'Signing & Capabilities'" -ForegroundColor White
Write-Host "4. Select your App Store distribution certificate" -ForegroundColor White
Write-Host "5. Select your App Store provisioning profile" -ForegroundColor White
Write-Host "6. Archive the app (Product > Archive)" -ForegroundColor White
Write-Host "7. Upload to App Store Connect" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Make sure you have:" -ForegroundColor Red
Write-Host "   - Apple Developer Account" -ForegroundColor White
Write-Host "   - App Store distribution certificate" -ForegroundColor White
Write-Host "   - App Store provisioning profile" -ForegroundColor White
Write-Host "   - GoogleService-Info.plist in ios/Runner/" -ForegroundColor White 