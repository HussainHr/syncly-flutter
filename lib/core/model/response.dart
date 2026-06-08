import 'package:dartz/dartz.dart';
import 'package:syncly/core/exceptions/http_exception.dart';

class Response {
  String? message;
  final dynamic data;
  int code;

  Response({required this.code, this.message, this.data = const {}});

}
extension ResponseExtension on Response {
  Right<AppException, Response> get toRight => Right(this);
}
