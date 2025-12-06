# WireGuard Client with Split Tunneling

A modern, cross-platform WireGuard VPN client built with Flutter, featuring advanced split tunneling with folder-based exclusions.

## 🎯 Features

- **Simple tunnel management** - Import, create, edit, and manage WireGuard tunnels
- **One-click connect** - Quick connect/disconnect with status indicators
- **Advanced Split Tunneling**:
  - Exclude specific apps from VPN
  - Add entire folders to scan for executables
  - Per-tunnel split tunneling rules
  - Save and load profiles
- **Cross-platform** - Windows, macOS, Android, iOS, Linux
- **Modern UI** - Material 3 design with dark/light themes

## 📱 Platforms

| Platform | Status | Split Tunneling |
|----------|--------|-----------------|
| Windows  | 🚧 In Progress | WFP-based |
| macOS    | 📋 Planned | Network Extension |
| Android  | 📋 Planned | Native VpnService |
| iOS      | 📋 Planned | Network Extension |
| Linux    | 📋 Planned | cgroups + iptables |

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.16+)
- Platform-specific requirements:
  - **Windows**: Visual Studio with C++ workload
  - **macOS**: Xcode
  - **Android**: Android Studio, Android SDK
  - **iOS**: Xcode, CocoaPods

### Development Setup

```bash
# Clone the repository
git clone <repository-url>
cd wg-flutter

# Get dependencies
flutter pub get

# Generate code (if using freezed/json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Run on Windows
flutter run -d windows

# Run on macOS
flutter run -d macos

# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios
```

### Building

```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Android
flutter build apk
flutter build appbundle

# iOS
flutter build ios
```

## 🏗️ Project Structure

```
wg-flutter/
├── lib/
│   ├── main.dart              # App entry point
│   ├── app.dart               # App widget with providers
│   ├── core/                  # Core utilities
│   │   ├── theme/             # Theming
│   │   ├── router/            # Navigation
│   │   └── constants/         # Constants
│   ├── models/                # Data models
│   ├── services/              # Business logic
│   ├── providers/             # State management (Riverpod)
│   ├── screens/               # UI screens
│   ├── widgets/               # Reusable widgets
│   └── utils/                 # Helpers
├── android/                   # Android platform code
├── ios/                       # iOS platform code
├── macos/                     # macOS platform code
├── windows/                   # Windows platform code
├── linux/                     # Linux platform code
├── test/                      # Unit and widget tests
├── integration_test/          # Integration tests
└── prompts/                   # Agent prompts (for development)
```

## 🤖 Long-Running Agent Development

This project uses a long-running agent harness for development. See:

- `app_spec.txt` - Full project specification
- `feature_list.json` - All features with status
- `claude-progress.txt` - Development progress log
- `prompts/` - Agent prompts

### Running the agents

1. **Initializer Agent** - Run once to set up the project
   - Uses `prompts/initializer_prompt.md`
   
2. **Coding Agent** - Run repeatedly to implement features
   - Uses `prompts/coding_prompt.md`
   
3. **Testing Agent** - Run to verify implementations
   - Uses `prompts/testing_prompt.md`

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [WireGuard](https://www.wireguard.com/) - The VPN protocol
- [wireguard-go](https://github.com/WireGuard/wireguard-go) - Go implementation
- [Flutter](https://flutter.dev/) - UI framework
- [Anthropic](https://www.anthropic.com/) - Long-running agent harness inspiration
