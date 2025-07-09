#!/bin/bash

# Read the current version from pubspec.yaml
VERSION_LINE=$(grep "version:" pubspec.yaml)
VERSION_NAME=$(echo $VERSION_LINE | cut -d"+" -f1 | cut -d":" -f2 | tr -d " ")
BUILD_NUMBER=$(echo $VERSION_LINE | cut -d"+" -f2)

# Increment build number
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))

# Update pubspec.yaml with new version
sed -i "s/version: $VERSION_NAME+$BUILD_NUMBER/version: $VERSION_NAME+$NEW_BUILD_NUMBER/" pubspec.yaml

echo "Version updated from $VERSION_NAME+$BUILD_NUMBER to $VERSION_NAME+$NEW_BUILD_NUMBER" 