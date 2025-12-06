import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode preference
enum AppThemeMode {
  system,
  light,
  dark,
}

/// Settings state
class SettingsState {
  final AppThemeMode themeMode;
  final bool notificationsEnabled;
  final bool autoStartEnabled;
  final bool startMinimized;
  final bool killSwitchEnabled;

  const SettingsState({
    this.themeMode = AppThemeMode.system,
    this.notificationsEnabled = true,
    this.autoStartEnabled = false,
    this.startMinimized = false,
    this.killSwitchEnabled = false,
  });

  SettingsState copyWith({
    AppThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? autoStartEnabled,
    bool? startMinimized,
    bool? killSwitchEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoStartEnabled: autoStartEnabled ?? this.autoStartEnabled,
      startMinimized: startMinimized ?? this.startMinimized,
      killSwitchEnabled: killSwitchEnabled ?? this.killSwitchEnabled,
    );
  }

  /// Convert theme mode to Flutter ThemeMode
  ThemeMode get flutterThemeMode {
    switch (themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

/// Provider for settings
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

/// State notifier for app settings
class SettingsNotifier extends StateNotifier<SettingsState> {
  static const String _themeModeKey = 'theme_mode';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _autoStartKey = 'auto_start';
  static const String _startMinimizedKey = 'start_minimized';
  static const String _killSwitchKey = 'kill_switch';

  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? 0;
    final themeMode = AppThemeMode.values[themeModeIndex.clamp(0, 2)];
    
    state = SettingsState(
      themeMode: themeMode,
      notificationsEnabled: prefs.getBool(_notificationsKey) ?? true,
      autoStartEnabled: prefs.getBool(_autoStartKey) ?? false,
      startMinimized: prefs.getBool(_startMinimizedKey) ?? false,
      killSwitchEnabled: prefs.getBool(_killSwitchKey) ?? false,
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }

  Future<void> setAutoStartEnabled(bool enabled) async {
    state = state.copyWith(autoStartEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoStartKey, enabled);
    // TODO: Actually register/unregister with system
  }

  Future<void> setStartMinimized(bool minimized) async {
    state = state.copyWith(startMinimized: minimized);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_startMinimizedKey, minimized);
  }

  Future<void> setKillSwitchEnabled(bool enabled) async {
    state = state.copyWith(killSwitchEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_killSwitchKey, enabled);
  }
}

/// Provider for theme mode
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.flutterThemeMode;
});
