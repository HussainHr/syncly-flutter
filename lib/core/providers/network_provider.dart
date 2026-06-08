import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncly/core/network/dio_network_service.dart';

final networkServiceProvider = Provider<DioNetworkService>((ref) {
  return DioNetworkService();
});