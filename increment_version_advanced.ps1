param(
    [string]$Type = "build",  # Options: "build", "patch", "minor", "major"
    [switch]$Build = $false   # Build after incrementing
)

# Read the current version from pubspec.yaml
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
        # Only increment build number
        $newBuildNumber = $buildNumber + 1
        Write-Host "Incrementing build number..."
    }
    "patch" {
        # Increment patch version and reset build number
        $patch = $patch + 1
        $newVersionName = "$major.$minor.$patch"
        $newBuildNumber = 1
        Write-Host "Incrementing patch version..."
    }
    "minor" {
        # Increment minor version, reset patch and build number
        $minor = $minor + 1
        $patch = 0
        $newVersionName = "$major.$minor.$patch"
        $newBuildNumber = 1
        Write-Host "Incrementing minor version..."
    }
    "major" {
        # Increment major version, reset minor, patch and build number
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

# Update pubspec.yaml with new version
$newContent = $content -replace "version: $versionName\+$buildNumber", "version: $newVersionName+$newBuildNumber"
$newContent | Set-Content pubspec.yaml -Force

Write-Host "Version updated from $versionName+$buildNumber to $newVersionName+$newBuildNumber"

if ($Build) {
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
    Write-Host "Version in APK: $newVersionName (Build: $newBuildNumber)"
}

Write-Host "`nUsage examples:"
Write-Host "  .\increment_version_advanced.ps1 -Type build         # Just increment build number"
Write-Host "  .\increment_version_advanced.ps1 -Type patch -Build  # Increment patch version and build"
Write-Host "  .\increment_version_advanced.ps1 -Type minor -Build  # Increment minor version and build"
Write-Host "  .\increment_version_advanced.ps1 -Type major -Build  # Increment major version and build" 