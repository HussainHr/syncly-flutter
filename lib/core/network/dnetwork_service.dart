import 'package:dartz/dartz.dart';
import 'package:syncly/core/exceptions/http_exception.dart';
import 'package:syncly/core/model/response.dart' as response;

abstract class DNetworkService {
  String get baseUrl;
  Map<String, Object> get headers;
  Map<String, dynamic> updateHeader(Map<String, dynamic> data);

  Future<Either<AppException, response.Response>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  });

  Future<Either<AppException, response.Response>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    bool requiresAuth = true,
  });

  Future<Either<AppException, response.Response>> put(
    String endpoint, {
    Map<String, dynamic>? data,
    bool requiresAuth = true,
  });

  Future<Either<AppException, response.Response>> patch(
    String endpoint, {
    Map<String, dynamic>? data,
    bool requiresAuth = true,
  });

  Future<Either<AppException, response.Response>> delete(
    String endpoint, {
    bool requiresAuth = true,
  });

  Future<Either<AppException, response.Response>> multipartPost(
    String endpoint, {
    Object? data,
    bool requiresAuth = true,
  });
}