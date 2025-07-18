#!/bin/bash

# Default values
TYPE="build"
BUILD_AFTER=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            TYPE="$2"
            shift 2
            ;;
        -b|--build)
            BUILD_AFTER=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-t|--type TYPE] [-b|--build]"
            echo "  -t, --type    Version type to increment: build, patch, minor, major (default: build)"
            echo "  -b, --build   Build APK after incrementing version"
            echo "  -h, --help    Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

# Read the current version from pubspec.yaml
VERSION_LINE=$(grep "version:" pubspec.yaml)
VERSION_NAME=$(echo $VERSION_LINE | cut -d"+" -f1 | cut -d":" -f2 | tr -d " ")
BUILD_NUMBER=$(echo $VERSION_LINE | cut -d"+" -f2)

echo "Current version: $VERSION_NAME+$BUILD_NUMBER"

# Parse version name parts
IFS='.' read -r -a VERSION_PARTS <<< "$VERSION_NAME"
MAJOR=${VERSION_PARTS[0]}
MINOR=${VERSION_PARTS[1]}
PATCH=${VERSION_PARTS[2]}

NEW_VERSION_NAME=$VERSION_NAME
NEW_BUILD_NUMBER=$BUILD_NUMBER

case $TYPE in
    "build")
        # Only increment build number
        NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
        echo "Incrementing build number..."
        ;;
    "patch")
        # Increment patch version and reset build number
        PATCH=$((PATCH + 1))
        NEW_VERSION_NAME="$MAJOR.$MINOR.$PATCH"
        NEW_BUILD_NUMBER=1
        echo "Incrementing patch version..."
        ;;
    "minor")
        # Increment minor version, reset patch and build number
        MINOR=$((MINOR + 1))
        PATCH=0
        NEW_VERSION_NAME="$MAJOR.$MINOR.$PATCH"
        NEW_BUILD_NUMBER=1
        echo "Incrementing minor version..."
        ;;
    "major")
        # Increment major version, reset minor, patch and build number
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        NEW_VERSION_NAME="$MAJOR.$MINOR.$PATCH"
        NEW_BUILD_NUMBER=1
        echo "Incrementing major version..."
        ;;
    *)
        echo "Invalid type. Use: build, patch, minor, or major"
        exit 1
        ;;
esac

# Update pubspec.yaml with new version
sed -i "s/version: $VERSION_NAME+$BUILD_NUMBER/version: $NEW_VERSION_NAME+$NEW_BUILD_NUMBER/" pubspec.yaml

echo "Version updated from $VERSION_NAME+$BUILD_NUMBER to $NEW_VERSION_NAME+$NEW_BUILD_NUMBER"

if [ "$BUILD_AFTER" = true ]; then
    # Clean the project
    echo ""
    echo "Cleaning the project..."
    flutter clean

    # Get dependencies
    echo ""
    echo "Getting dependencies..."
    flutter pub get

    # Build Android App Bundle (AAB)
    echo ""
    echo "Building Android App Bundle (AAB)..."
    flutter build appbundle --release

    echo ""
    echo "Build completed! Your AAB file is located at: build/app/outputs/bundle/release/app-release.aab"
    echo "Version in APK: $NEW_VERSION_NAME (Build: $NEW_BUILD_NUMBER)"
fi

echo ""
echo "Usage examples:"
echo "  $0 -t build           # Just increment build number"
echo "  $0 -t patch -b        # Increment patch version and build"
echo "  $0 -t minor -b        # Increment minor version and build"
echo "  $0 -t major -b        # Increment major version and build" 