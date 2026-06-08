import 'dart:developer';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:syncly/core/mixins/exception_handler_mixin.dart';
import 'package:syncly/core/network/dnetwork_service.dart';
import 'package:syncly/core/config/api_endpoints.dart';
import 'package:syncly/core/exceptions/http_exception.dart';
import 'package:syncly/core/model/response.dart' as response;
import 'package:syncly/core/services/shared_preference_service.dart';

class DioNetworkService extends DNetworkService with ExceptionHandlerMixin {
  late Dio _dio;
  static DioNetworkService? _instance;
  CancelToken? _cancelToken;

  DioNetworkService._() {
    _dio = Dio();
    _dio.options = dioBaseOptions;
    _setupInterceptors();
  }

  factory DioNetworkService() {
    _instance ??= DioNetworkService._();
    return _instance!;
  }

  void _setupInterceptors() {
    // Add authentication interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Check if this request requires authentication
          final requiresAuth = options.extra['requiresAuth'] ?? true;

          if (requiresAuth) {
            final token = await SharedPreferenceService.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 unauthorized - token expired
          if (error.response?.statusCode == 401) {
            await SharedPreferenceService.clearToken();
            log('Token expired and cleared due to 401 error');
          }
          handler.next(error);
        },
      ),
    );

    // Add your existing logging interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: true,
      request: true,
    ));
  }

  BaseOptions get dioBaseOptions => BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    baseUrl: baseUrl,
    headers: headers,
  );

  @override
  String get baseUrl => ApiEndpoints.apiBaseUrl;

  @override
  Map<String, Object> get headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  @override
  Map<String, dynamic> updateHeader(Map<String, dynamic> data) {
    final updatedHeaders = {...headers, ...data};
    _dio.options.headers = updatedHeaders;
    return updatedHeaders;
  }

  @override
  Future<Either<AppException, response.Response>> get(
      String endpoint, {
        Map<String, dynamic>? queryParameters,
        bool requiresAuth = true,
      }) async {
    final res = await handleException(
          () => _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      ),
      endpoint: endpoint,
    );
    return res;
  }

  @override
  Future<Either<AppException, response.Response>> post(
      String endpoint, {
        Map<String, dynamic>? data,
        bool requiresAuth = true,
      }) async {
    final res = await handleException(
          () => _dio.post(
        endpoint,
        data: data,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      ),
      endpoint: endpoint,
    );
    return res;
  }

  @override
  Future<Either<AppException, response.Response>> put(
      String endpoint, {
        Map<String, dynamic>? data,
        bool requiresAuth = true,
      }) async {
    final res = await handleException(
          () => _dio.put(
        endpoint,
        data: data,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      ),
      endpoint: endpoint,
    );
    return res;
  }

  @override
  Future<Either<AppException, response.Response>> multipartPost(
      String endpoint, {
        Object? data,
        bool requiresAuth = true,
      }) async {
    final res = await handleException(
          () => _dio.post(
        endpoint,
        data: data,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      ),
      endpoint: endpoint,
    );
    return res;
  }

  @override
  Future<Either<AppException, response.Response>> patch(
      String endpoint, {
        Map<String, dynamic>? data,
        bool requiresAuth = true,
      }) async {
    final res = await handleException(
          () => _dio.patch(
        endpoint,
        data: data,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      ),
      endpoint: endpoint,
    );
    return res;
  }

  @override
  Future<Either<AppException, response.Response>> delete(
      String endpoint, {
        bool requiresAuth = true,
      }) async {
    final res = await handleException(
          () => _dio.delete(
        endpoint,
        options: Options(extra: {'requiresAuth': requiresAuth}),
      ),
      endpoint: endpoint,
    );
    return res;
  }
}