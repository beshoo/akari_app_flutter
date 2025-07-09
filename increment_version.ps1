# Read the current version from pubspec.yaml
$content = Get-Content pubspec.yaml
$versionLine = $content | Where-Object { $_ -match "^version:" }
$versionParts = $versionLine -split "\+"
$versionName = ($versionParts[0] -split ":")[1].Trim()
$buildNumber = [int]$versionParts[1]

# Increment build number
$newBuildNumber = $buildNumber + 1

# Update pubspec.yaml with new version
$newContent = $content -replace "version: $versionName\+$buildNumber", "version: $versionName+$newBuildNumber"
$newContent | Set-Content pubspec.yaml -Force

Write-Host "Version updated from $versionName+$buildNumber to $versionName+$newBuildNumber"

# Clean the project
Write-Host "`nCleaning the project..."
flutter clean

# Get dependencies
Write-Host "`nGetting dependencies..."
flutter pub get

# Build Android App Bundle (AAB)
Write-Host "`nBuilding Android App Bundle (AAB)..."
flutter build appbundle --release

Write-Host "`nBuild completed! Your AAB file is located at: build/app/outputs/bundle/release/app-release.aab"