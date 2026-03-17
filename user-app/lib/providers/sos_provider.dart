import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../data/api/sos_api.dart';
import '../data/models/sos_event.dart';
import '../data/models/tracking.dart';

// Active SOS provider
final activeSosProvider = StateNotifierProvider<ActiveSosNotifier, AsyncValue<SosEvent?>>(
  (ref) => ActiveSosNotifier(ref.read(sosApiProvider)),
);

class ActiveSosNotifier extends StateNotifier<AsyncValue<SosEvent?>> {
  final SosApi _sosApi;

  ActiveSosNotifier(this._sosApi) : super(const AsyncValue.loading()) {
    loadActiveSos();
  }

  Future<void> loadActiveSos() async {
    try {
      final list = await _sosApi.getMyActiveSos();
      state = AsyncValue.data(list.isNotEmpty ? list.first : null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void setActiveSos(SosEvent sos) {
    state = AsyncValue.data(sos);
  }

  void clearActiveSos() {
    state = const AsyncValue.data(null);
  }
}

// SOS history provider
final sosHistoryProvider = FutureProvider<List<SosEvent>>((ref) async {
  final api = ref.read(sosApiProvider);
  return api.getMySosEvents();
});

// Single SOS event provider
final sosEventProvider = FutureProvider.family<SosEvent, int>((ref, id) async {
  final api = ref.read(sosApiProvider);
  return api.getSosEvent(id);
});

// Tracking provider with auto-refresh
class TrackingNotifier extends StateNotifier<AsyncValue<TrackingInfo?>> {
  final SosApi _sosApi;
  final int _sosId;
  Timer? _timer;

  TrackingNotifier(this._sosApi, this._sosId)
      : super(const AsyncValue.loading()) {
    _fetch();
  }

  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: AppConstants.trackingPollIntervalSeconds),
      (_) => _fetch(),
    );
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _fetch() async {
    try {
      final tracking = await _sosApi.getTracking(_sosId);
      state = AsyncValue.data(tracking);
      // Stop polling when terminal status reached
      if (tracking.status == AppConstants.statusCompleted ||
          tracking.status == AppConstants.statusCancelled) {
        stopPolling();
      }
    } catch (e, st) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> refresh() => _fetch();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final trackingProvider = StateNotifierProvider.family<TrackingNotifier,
    AsyncValue<TrackingInfo?>, int>((ref, sosId) {
  final notifier = TrackingNotifier(ref.read(sosApiProvider), sosId);
  notifier.startPolling();
  return notifier;
});
