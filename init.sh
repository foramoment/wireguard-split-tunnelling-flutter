#!/bin/bash
# WireGuard Client - Development Environment Setup Script
# Run this script to set up the development environment

set -e

echo "🚀 Setting up WireGuard Client development environment..."

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    echo "   https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"

# Get dependencies
echo "📦 Installing dependencies..."
flutter pub get

# Generate code (if build_runner is available)
if grep -q "build_runner" pubspec.yaml 2>/dev/null; then
    echo "🔨 Running code generation..."
    dart run build_runner build --delete-conflicting-outputs
fi

# Verify build
echo "🏗️ Verifying build..."
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    flutter build windows || echo "⚠️ Windows build failed (may need Visual Studio)"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    flutter build macos || echo "⚠️ macOS build failed (may need Xcode)"
else
    flutter build linux || echo "⚠️ Linux build failed"
fi

echo ""
echo "✨ Setup complete!"
echo ""
echo "To run the app:"
echo "  flutter run -d windows  # Windows"
echo "  flutter run -d macos    # macOS"
echo "  flutter run -d android  # Android"
echo "  flutter run -d ios      # iOS"
echo ""
echo "To run tests:"
echo "  flutter test"
echo ""
