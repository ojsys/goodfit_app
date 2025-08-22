#!/bin/bash

echo "🏗️  Building GoodFit APK..."
echo "📱 Production API: http://194.195.86.92/api/v1"
echo ""

# Clean project
echo "🧹 Cleaning project..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build APK
echo "🔨 Building release APK..."
flutter build apk --release --verbose

# Check if APK was created
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_PATH" ]; then
    echo ""
    echo "✅ APK built successfully!"
    echo "📍 Location: $APK_PATH"
    echo "📏 Size: $(du -h "$APK_PATH" | cut -f1)"
    echo ""
    echo "🚀 You can now install this APK on your Android device!"
else
    echo ""
    echo "❌ APK build failed. Check the output above for errors."
    echo ""
    echo "Alternative build commands to try:"
    echo "1. flutter build apk --debug"
    echo "2. flutter build appbundle --release"
    echo "3. Open in Android Studio and build from IDE"
fi