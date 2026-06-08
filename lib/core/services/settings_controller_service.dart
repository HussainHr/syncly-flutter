import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:syncly/core/services/settings_service.dart';
import 'package:syncly/core/model/app_config.dart';
import 'package:syncly/core/services/navigation_service.dart';
import 'package:syncly/core/services/shared_preference_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:syncly/core/models/user_model.dart';

class SettingsController with ChangeNotifier {
  SettingsController._(this._settingsService);

  static SettingsController? _instance;

  factory SettingsController() {
    SettingsService settingsService = SettingsService();
    _instance ??= SettingsController._(settingsService);
    return _instance!;
  }

  final SettingsService _settingsService;
  VoidCallback? _restartApp;
  ThemeMode? _themeMode;
  AppConfig? _config;
  UserData? _user;

  ThemeMode get themeMode => _themeMode!;

  Future<void> loadSettings() async {
    // _appConfigService = AppConfigCrudService();
    _themeMode = await _settingsService.themeMode();
    await getAppConfig();
    await getUser();
    notifyListeners();
    debugPrint("settings loaded!");
  }

  Future<AppConfig> getAppConfig() async {
    if (_config == null) {
      String? configString =
          (await SharedPreferenceService().get("app_config")) as String?;
      if (configString != null) {
        Map<String, dynamic> configMap = jsonDecode(configString);
        _config = AppConfig.fromMap(configMap);
      } else {
        _config = AppConfig(id: 1, locale: 'en_US', theme: 'light');
        String configJson = jsonEncode(_config!.toMap());
        await SharedPreferenceService().set('app_config', configJson);
        notifyListeners();
      }
    }
    return _config!;
  }

  // For initial work
  Future<void> setSomeRequiredData(
    String fatherName,
    String motherName,
    String address,
    String permAddress,
  ) async {
    await SharedPreferenceService().set('father_name', fatherName);
    await SharedPreferenceService().set('mother_name', motherName);
    await SharedPreferenceService().set('address', address);
    await SharedPreferenceService().set('perm_address', permAddress);
  }

  Future<void> updateAppConfig(AppConfig config) async {
    _config = config;
    String configJson = jsonEncode(_config!.toMap());
    await SharedPreferenceService().set('app_config', configJson);
  }

  Future<void> removeAppConfig() async {
    await SharedPreferenceService().remove('app_config');
  }

  Future<void> setUser(UserData user) async {
    _user = user;
    final configJson = jsonEncode(user.toJson());
    await SharedPreferenceService().set('user', configJson);
  }

  Future<void> removeUser() async {
    await SharedPreferenceService().remove("user");
  }

  Future<UserData?> getUser() async {
    String? userJson = (await SharedPreferenceService().get("user")) as String?;
    if (userJson != null) {
      Map<String, dynamic> userMap = jsonDecode(userJson);
      _user = UserData.fromJson(userMap);
    }
    return _user;
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;

    if (newThemeMode == _themeMode) return;

    _themeMode = newThemeMode;

    notifyListeners();

    await _settingsService.updateThemeMode(newThemeMode);
  }

  Future<bool> checkInternetConnection({int retryCount = 1}) async {
    List<ConnectivityResult> results = await Connectivity().checkConnectivity();
    ConnectivityResult? result = results.isNotEmpty ? results.first : null;

    if ((result != null) && result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi) {
      return true;
    } else if (retryCount < 3) {
      debugPrint("no internet. trying again: $retryCount");
      await Future.delayed(const Duration(seconds: 1));
      return checkInternetConnection(retryCount: retryCount + 1);
    } else {
      return false;
    }
  }

  void setRestartAppCallback(VoidCallback callback) {
    _restartApp = callback;
  }

  //this resets and restarts the app
  Future<void> resetApp() async {
    debugPrint("removing AppConfig");
    _config = null;
    _themeMode = null;

    // await SharedPreferenceService().clear();
    await removeUser();
    await removeAppConfig();
    debugPrint("all table deleted");
    await restartApp();
  }

  //this only restarts the app
  Future<void> restartApp() async {
    if (_restartApp != null) {
      _restartApp!(); // Call the restart callback
      NavigationService.resetNavigatorKey();
    } else {
      debugPrint("Error: _restartApp has not been initialized.");
    }
  }
}
