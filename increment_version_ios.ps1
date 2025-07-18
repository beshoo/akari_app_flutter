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
    default {
        Write-Host "Invalid type. Use: build, patch, minor, or major"
        exit 1
    }
}

# Update pubspec.yaml
$newContent = $content -replace "version: $versionName\+$buildNumber", "version: $newVersionName+$newBuildNumber"
$newContent | Set-Content pubspec.yaml -Force

Write-Host "Version updated from $versionName+$buildNumber to $newVersionName+$newBuildNumber"

if ($Build) {
    Write-Host "`nBuilding iOS app..."
    
    # Clean project
    Write-Host "Cleaning project..."
    flutter clean
    
    # Get dependencies
    Write-Host "Getting dependencies..."
    flutter pub get
    
    # Build iOS app
    Write-Host "Building iOS release..."
    flutter build ios --release
    
    Write-Host "`n🎯 iOS Build Completed!"
    Write-Host "======================================"
    Write-Host "Next steps to upload to App Store:"
    Write-Host "1. Open ios/Runner.xcworkspace in Xcode"
    Write-Host "2. Select 'Any iOS Device (arm64)' as target"
    Write-Host "3. Product → Archive"
    Write-Host "4. Distribute App → App Store Connect"
    Write-Host "5. Upload to App Store Connect"
    Write-Host "======================================"
    Write-Host "Version in build: $newVersionName (Build: $newBuildNumber)"
} else {
    Write-Host "`nVersion updated successfully!"
    Write-Host "Run with -Build flag to build iOS app automatically"
}

Write-Host "`nUsage examples:"
Write-Host "  .\increment_version_ios.ps1 -Type build -Build      # Just increment build number and build"
Write-Host "  .\increment_version_ios.ps1 -Type patch -Build      # Increment patch version and build"
Write-Host "  .\increment_version_ios.ps1 -Type minor -Build      # Increment minor version and build"
Write-Host "  .\increment_version_ios.ps1 -Type major -Build      # Increment major version and build" 