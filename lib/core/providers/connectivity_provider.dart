import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _isOnline(List<ConnectivityResult> results) {
  return results.any((r) => r != ConnectivityResult.none);
}

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  final initial = await connectivity.checkConnectivity();
  yield _isOnline(initial);

  await for (final results in connectivity.onConnectivityChanged) {
    yield _isOnline(results);
  }
});
