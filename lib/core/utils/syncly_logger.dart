import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'dart:convert';

class SynclyLogger {
  // Basic debug log using debugPrint (recommended for Flutter)
  static void log(String message) {
    if (kDebugMode) {
      debugPrint('[LOG] $message');
    }
  }

  // Info level logging
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  // Warning level logging
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('[WARNING] $message');
    }
  }

  // Error level logging
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) {
        debugPrint('[ERROR] Exception: $error');
      }
      if (stackTrace != null) {
        debugPrint('[ERROR] StackTrace: $stackTrace');
      }
    }
  }

  // Debug level logging with timestamp
  static void debug(String message) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toString();
      debugPrint('[DEBUG] [$timestamp] $message');
    }
  }

  // Network/API logging
  static void network(String message) {
    if (kDebugMode) {
      debugPrint('[NETWORK] $message');
    }
  }

  // Custom tag logging
  static void tagged(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  // Professional logging using dart:developer log (for advanced use)
  static void devLog(String message, {String? name, Object? error}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: name ?? 'APP',
        error: error,
      );
    }
  }

  // Log JSON data with pretty formatting for models
  static void logJson(Object data, {String? tag}) {
    if (kDebugMode) {
      try {
        String jsonString;

        // Check if the object has a toJson method
        if (data is Map<String, dynamic>) {
          jsonString = const JsonEncoder.withIndent('  ').convert(data);
        } else if (data.runtimeType.toString().contains('Model') ||
            data.toString().contains('{') && data.toString().contains('}')) {
          // Try to call toJson if it exists
          final dynamic jsonData = (data as dynamic).toJson();
          jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
        } else {
          jsonString = data.toString();
        }

        final String logTag = tag ?? 'JSON';
        debugPrint('[$logTag] \n$jsonString');
      } catch (e) {
        debugPrint('[JSON_ERROR] Failed to format JSON: $e');
        debugPrint('[JSON_ERROR] Raw data: $data');
      }
    }
  }

  // Log Map data with pretty formatting
  static void logMap(Map<String, dynamic> data, {String? tag}) {
    if (kDebugMode) {
      try {
        final formattedJson = const JsonEncoder.withIndent('  ').convert(data);
        final String logTag = tag ?? 'MAP';
        debugPrint('[$logTag] \n$formattedJson');
      } catch (e) {
        debugPrint('[MAP_ERROR] Failed to format Map: $e');
        debugPrint('[MAP_ERROR] Raw data: $data');
      }
    }
  }

  // Log model objects (automatically detects toJson method)
  static void logModel(Object model, {String? tag}) {
    if (kDebugMode) {
      try {
        // Try to call toJson method
        final dynamic jsonData = (model as dynamic).toJson();
        final formattedJson = const JsonEncoder.withIndent('  ').convert(jsonData);
        final String logTag = tag ?? 'MODEL';
        debugPrint('[$logTag] ${model.runtimeType}\n$formattedJson');
      } catch (e) {
        debugPrint('[MODEL_ERROR] Failed to format model: $e');
        debugPrint('[MODEL_ERROR] Raw model: $model');
      }
    }
  }

  // Log API request/response with formatted JSON
  static void logApiRequest(String endpoint, Object? requestData, {String method = 'POST'}) {
    if (kDebugMode) {
      debugPrint('[API_REQUEST] $method $endpoint');
      if (requestData != null) {
        logJson(requestData, tag: 'REQUEST_BODY');
      }
    }
  }

  // Log API response with formatted JSON
  static void logApiResponse(String endpoint, Object? responseData, {int? statusCode}) {
    if (kDebugMode) {
      final status = statusCode != null ? ' ($statusCode)' : '';
      debugPrint('[API_RESPONSE] $endpoint$status');
      if (responseData != null) {
        logJson(responseData, tag: 'RESPONSE_BODY');
      }
    }
  }
}
