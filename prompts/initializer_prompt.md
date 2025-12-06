# Initializer Agent Prompt

You are initializing a new Flutter project: **WireGuard Client with Split Tunneling**.

## Your Goals

1. **Set up the Flutter project** with proper structure and dependencies
2. **Create initial architecture** following best practices
3. **Set up theming and state management**
4. **Make initial git commit** with the foundation

## Project Context

Read `app_spec.txt` for the full project specification.
Read `feature_list.json` to understand all features that need to be implemented.

## Step-by-Step Tasks

### 1. Initialize Flutter Project
```bash
flutter create --org com.wgsplit --project-name wg_client .
```

### 2. Update pubspec.yaml with dependencies
Essential packages:
- `flutter_riverpod` - State management
- `go_router` - Navigation
- `hive` + `hive_flutter` - Local storage
- `freezed` + `freezed_annotation` - Immutable models
- `json_annotation` + `json_serializable` - JSON serialization
- `file_picker` - File selection
- `permission_handler` - Permissions
- `flutter_local_notifications` - Notifications
- `window_manager` - Desktop window control
- `tray_manager` - System tray (desktop)
- `google_fonts` - Typography

### 3. Create folder structure
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── app_colors.dart
│   ├── router/
│   │   └── app_router.dart
│   └── constants/
│       └── app_constants.dart
├── models/
│   ├── tunnel.dart
│   ├── peer.dart
│   ├── connection_status.dart
│   └── split_tunnel_config.dart
├── services/
│   ├── tunnel_service.dart
│   ├── connection_service.dart
│   ├── storage_service.dart
│   └── split_tunnel_service.dart
├── providers/
│   ├── tunnel_provider.dart
│   ├── connection_provider.dart
│   └── settings_provider.dart
├── screens/
│   ├── home/
│   ├── tunnel_details/
│   ├── add_tunnel/
│   ├── import_tunnel/
│   ├── split_tunneling/
│   └── settings/
├── widgets/
│   ├── tunnel_card.dart
│   ├── status_indicator.dart
│   └── common/
└── utils/
    ├── config_parser.dart
    └── validators.dart
```

### 4. Set up basic theming
- Create Material 3 theme with:
  - Primary color: Indigo (#6366F1)
  - Connected color: Green (#22C55E)
  - Disconnected color: Red (#EF4444)
- Support dark and light modes
- Use Inter or Roboto font

### 5. Create placeholder screens
- Create empty screen widgets for each main screen
- Set up routing between them
- Verify navigation works

### 6. Initialize git repository
```bash
git init
git add .
git commit -m "Initial project setup with Flutter structure"
```

### 7. Update progress file
Update `claude-progress.txt` with:
- What was done
- Current state
- Any issues encountered
- Next steps for the coding agent

## Important Rules

1. **DO NOT** try to implement all features at once
2. **DO** create a solid foundation that coding agents can build upon
3. **DO** ensure the project builds without errors before committing
4. **DO** document any decisions in the progress file
5. **DO NOT** mark any features as passing in feature_list.json - let coding agents do that

## Verification

Before finishing, verify:
- [ ] `flutter pub get` succeeds
- [ ] `flutter build windows` succeeds (or target platform)
- [ ] App launches and shows home screen placeholder
- [ ] Navigation to all placeholder screens works
- [ ] Git repository is initialized with initial commit

## Output

When you're done, update `claude-progress.txt` with a detailed summary for the next agent.
