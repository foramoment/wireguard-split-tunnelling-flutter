# PowerShell version of init script for Windows
# Run: .\init.ps1

Write-Host "🚀 Setting up WireGuard Client development environment..." -ForegroundColor Cyan

# Check Flutter
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Write-Host "✅ Flutter found: $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Flutter is not installed. Please install Flutter first." -ForegroundColor Red
    Write-Host "   https://flutter.dev/docs/get-started/install"
    exit 1
}

# Get dependencies
Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
flutter pub get

# Check if build_runner is in pubspec
if (Test-Path "pubspec.yaml") {
    $content = Get-Content "pubspec.yaml" -Raw
    if ($content -match "build_runner") {
        Write-Host "🔨 Running code generation..." -ForegroundColor Yellow
        dart run build_runner build --delete-conflicting-outputs
    }
}

# Verify build
Write-Host "🏗️ Verifying Windows build..." -ForegroundColor Yellow
flutter build windows

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✨ Setup complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To run the app:" -ForegroundColor Cyan
    Write-Host "  flutter run -d windows"
    Write-Host ""
    Write-Host "To run tests:" -ForegroundColor Cyan
    Write-Host "  flutter test"
} else {
    Write-Host "⚠️ Build failed. You may need Visual Studio with C++ workload." -ForegroundColor Yellow
}
