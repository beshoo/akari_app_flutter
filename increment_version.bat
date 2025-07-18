@echo off
setlocal enabledelayedexpansion

echo.
echo ======================================
echo    Akari App Version Increment Tool
echo ======================================
echo.
echo Current pubspec.yaml version:
findstr "version:" pubspec.yaml
echo.

set /p platform="Choose platform: [A] Android (AAB), [I] iOS, [B] Both platforms: "

if /i "%platform%"=="A" (
    set "platform_name=Android"
    set "script_file=increment_version_advanced.ps1"
) else if /i "%platform%"=="I" (
    set "platform_name=iOS"
    set "script_file=increment_version_ios.ps1"
) else if /i "%platform%"=="B" (
    set "platform_name=Both Platforms"
    set "script_file=both"
) else (
    echo Invalid platform choice. Exiting.
    pause
    exit /b 1
)

echo.
echo Building for: !platform_name!
echo.

set /p choice="Choose increment type: [1] Build number only, [2] Patch version, [3] Minor version, [4] Major version: "

if "%choice%"=="1" (
    set "version_type=build"
) else if "%choice%"=="2" (
    set "version_type=patch"
) else if "%choice%"=="3" (
    set "version_type=minor"
) else if "%choice%"=="4" (
    set "version_type=major"
) else (
    echo Invalid choice. Exiting.
    pause
    exit /b 1
)

echo.
echo ======================================
echo Starting build process...
echo ======================================

if "!script_file!"=="both" (
    echo Building Android AAB...
    powershell -ExecutionPolicy Bypass -File increment_version_advanced.ps1 -Type !version_type! -Build
    echo.
    echo Building iOS...
    powershell -ExecutionPolicy Bypass -File increment_version_ios.ps1 -Type build -Build
) else (
    powershell -ExecutionPolicy Bypass -File !script_file! -Type !version_type! -Build
)

echo.
echo ========================================
echo Build completed successfully!
echo Platform: !platform_name!
echo Version Type: !version_type!
echo ========================================
pause 