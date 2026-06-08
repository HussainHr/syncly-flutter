import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncly/core/services/presence_service.dart';

final presenceServiceProvider = Provider<PresenceService>((ref) {
  final svc = PresenceService();
  ref.onDispose(() => svc.stop());
  return svc;
});

