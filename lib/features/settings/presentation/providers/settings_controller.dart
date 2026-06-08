import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class SettingsState {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool notificationsPermissionAsked;
  final String languageCode;
  final bool showMyEmail;

  const SettingsState({
    required this.themeMode,
    required this.notificationsEnabled,
    required this.notificationsPermissionAsked,
    required this.languageCode,
    required this.showMyEmail,
  });

  const SettingsState.defaults()
      : themeMode = ThemeMode.system,
        notificationsEnabled = true,
        notificationsPermissionAsked = false,
        languageCode = 'en',
        showMyEmail = false;

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? notificationsPermissionAsked,
    String? languageCode,
    bool? showMyEmail,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationsPermissionAsked:
          notificationsPermissionAsked ?? this.notificationsPermissionAsked,
      languageCode: languageCode ?? this.languageCode,
      showMyEmail: showMyEmail ?? this.showMyEmail,
    );
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController()..load();
});

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController() : super(const SettingsState.defaults());

  static const _kThemeMode = 'settings.themeMode';
  static const _kNotifications = 'settings.notificationsEnabled';
  static const _kNotificationsPermissionAsked =
      'settings.notificationsPermissionAsked';
  static const _kLanguage = 'settings.languageCode';
  static const _kShowMyEmail = 'settings.showMyEmail';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_kThemeMode);
      final notifications = prefs.getBool(_kNotifications);
      final asked = prefs.getBool(_kNotificationsPermissionAsked);
      final language = prefs.getString(_kLanguage);
      final showMyEmail = prefs.getBool(_kShowMyEmail);

      state = state.copyWith(
        themeMode: _fromThemeIndex(themeIndex) ?? state.themeMode,
        notificationsEnabled: notifications ?? state.notificationsEnabled,
        notificationsPermissionAsked: asked ?? state.notificationsPermissionAsked,
        languageCode: language ?? state.languageCode,
        showMyEmail: showMyEmail ?? state.showMyEmail,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Settings load failed: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeMode, _toThemeIndex(mode));
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifications, enabled);
  }

  Future<void> markNotificationsPermissionAsked() async {
    if (state.notificationsPermissionAsked) return;
    state = state.copyWith(notificationsPermissionAsked: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsPermissionAsked, true);
  }

  Future<void> setLanguageCode(String code) async {
    state = state.copyWith(languageCode: code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, code);
  }

  Future<void> setShowMyEmail(bool show) async {
    state = state.copyWith(showMyEmail: show);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowMyEmail, show);
  }

  static int _toThemeIndex(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 0,
      ThemeMode.light => 1,
      ThemeMode.dark => 2,
    };
  }

  static ThemeMode? _fromThemeIndex(int? idx) {
    return switch (idx) {
      0 => ThemeMode.system,
      1 => ThemeMode.light,
      2 => ThemeMode.dark,
      _ => null,
    };
  }
}

