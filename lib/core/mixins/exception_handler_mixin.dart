import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:syncly/core/network/dnetwork_service.dart';
import 'package:syncly/core/exceptions/http_exception.dart';
import 'package:syncly/core/model/response.dart' as response;

mixin ExceptionHandlerMixin on DNetworkService {
  // Helper method to sanitize endpoint (remove domain)
  String _sanitizeEndpoint(String endpoint) {
    if (endpoint.isEmpty) return 'unknown_endpoint';

    try {
      final uri = Uri.parse(endpoint);
      // Return only the path without domain
      final path = uri.path.isNotEmpty ? uri.path : '/';
      return path.split('/').where((segment) => segment.isNotEmpty).join('_');
    } catch (e) {
      return 'endpoint';
    }
  }

  Future<Either<AppException, response.Response>>
  handleException<T extends Object>(
    Future<Response<dynamic>> Function() handler, {
    String endpoint = '',
  }) async {
    try {
      final res = await handler();
      return Right(
        response.Response(
          code: res.statusCode ?? 200,
          data: res.data,
          message: res.statusMessage,
        ),
      );
    } catch (e) {
      String message = '';
      String identifier = '';
      int statusCode = 0;

      // Sanitize endpoint to remove domain
      final sanitizedEndpoint = _sanitizeEndpoint(endpoint);

      log(e.runtimeType.toString());

      switch (e) {
        case SocketException _:
          // e is already SocketException here, Dart recognizes it
          message =
              'Unable to connect to the server. Please check your internet connection.';
          statusCode = 0;
          identifier =
              'Socket Exception: Network unavailable at $sanitizedEndpoint';
          break;

        case DioException dioError:
          final res = dioError.response;
          if (res == null) {
            if (dioError.error is SocketException) {
              message =
                  'Unable to connect to the server. Please check your internet connection.';
              statusCode = 0;
              identifier = 'Network error at $sanitizedEndpoint';
            } else if (dioError.type == DioExceptionType.connectionTimeout ||
                dioError.type == DioExceptionType.sendTimeout ||
                dioError.type == DioExceptionType.receiveTimeout) {
              message = 'Request timed out. Please try again.';
              statusCode = 408;
              identifier = 'Timeout error at $sanitizedEndpoint';
            } else if (dioError.type == DioExceptionType.cancel) {
              message = 'Request was cancelled.';
              statusCode = -1;
              identifier = 'Request cancelled at $sanitizedEndpoint';
            } else {
              message = 'Something went wrong. Please try again.';
              statusCode = 2;
              identifier = 'Unknown network error at $sanitizedEndpoint';
            }
          } else {
            final status = res.statusCode ?? 500;
            switch (status) {
              case 400:
                message =
                    res.data['message'] ??
                    'Bad request. Please check your input.';
                identifier = 'Bad request at $sanitizedEndpoint';
                break;
              case 401:
                message = 'Authentication required. Please log in again.';
                identifier =
                    res.data['status'] ??
                    'Unauthorized access at $sanitizedEndpoint';
                break;
              case 403:
                message =
                    res.data['message'] ?? 'Access denied for that action';
                identifier = 'Forbidden access at $sanitizedEndpoint';
                break;
              case 404:
                message = res.data['message'] ?? 'Resource not found';
                identifier = 'Not found at $sanitizedEndpoint';
                break;
              case 422:
                message =
                    res.data['message'] ??
                    'Validation failed. Please check your input.';
                identifier = 'Validation error at $sanitizedEndpoint';
                break;
              case 423:
                message =
                    res.data['message'] ??
                    "Account blocked due to suspicious activity";
                identifier = 'Account blocked at $sanitizedEndpoint';
                break;
              case 429:
                message =
                    res.data['message'] ??
                    "Too many requests. Please slow down.";
                identifier = 'Rate limit exceeded at $sanitizedEndpoint';
                break;
              case 500:
                message =
                    res.data['message'] ??
                    "Server error. Please try again later.";
                identifier = 'Internal server error at $sanitizedEndpoint';
                break;
              case 503:
                message =
                    res.data['message'] ?? "Service temporarily unavailable";
                identifier = 'Service unavailable at $sanitizedEndpoint';
                break;
              default:
                message = res.data['message'] ?? 'Server error occurred';
                identifier = 'HTTP error $status at $sanitizedEndpoint';
            }
            statusCode = status;
          }
          break;

        default:
          message = 'Something went wrong. Please try again.';
          statusCode = 2;
          identifier = 'Unknown error at $sanitizedEndpoint';
      }

      return Left(
        AppException(
          message: message,
          statusCode: statusCode,
          identifier: identifier,
        ),
      );
    }
  }
}
