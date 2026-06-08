import 'dart:async';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceService {
  SharedPreferences? sharedPreferences;
  static SharedPreferenceService? _instance;

  static const _keyToken = 'token';
  static const _keyUserData = 'user_data';
  static const _keySalonData = 'salon_data';
  static const _keyDeliveryManData = 'delivery_man_data';
  static const _keyCart = 'cart';
  static const _keyFcmToken = 'fcm_token';
  static const _keyIsFirstRun = 'is_first_run';

  SharedPreferenceService._() {
    _init();
  }

  factory SharedPreferenceService() {
    _instance ??= SharedPreferenceService._();
    return _instance!;
  }

  final Completer<SharedPreferences> _completer =
      Completer<SharedPreferences>();

  void _init() {
    _completer.complete(SharedPreferences.getInstance());
  }

  Future<Object?> get(String key) async {
    sharedPreferences = await _completer.future;
    return sharedPreferences!.get(key);
  }

  Future<void> clear() async {
    sharedPreferences = await _completer.future;
    await sharedPreferences!.clear();
  }

  Future<bool> has(String key) async {
    sharedPreferences = await _completer.future;
    return sharedPreferences?.containsKey(key) ?? false;
  }

  Future<bool> remove(String key) async {
    sharedPreferences = await _completer.future;
    return await sharedPreferences!.remove(key);
  }

  Future<bool> set(String key, data) async {
    sharedPreferences = await _completer.future;
    return await sharedPreferences!.setString(key, data.toString());
  }

  // Save Token with null safety
  static Future<bool> saveToken(String? token) async {
    log('saveToken saving token: $token');
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (token != null) {
        await prefs.setString(_keyToken, token);
        return true;
      } else {
        await prefs.remove(_keyToken);
        return false;
      }
    } catch (e) {
      log('Error saving token: $e');
      return false;
    }
  }

  // Get Token with null safety
  static Future<String?> getToken() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyToken);
    } catch (e) {
      log('Error getting token: $e');
      return null;
    }
  }

  // Check if token exists
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Clear token (for logout)
  static Future<bool> clearToken() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      return true;
    } catch (e) {
      log('Error clearing token: $e');
      return false;
    }
  }
}
