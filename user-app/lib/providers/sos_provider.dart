import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_handler.dart';
import '../core/constants/app_constants.dart';
import '../core/network/websocket_service.dart';
import '../data/api/sos_api.dart';
import '../data/models/sos_event.dart';
import '../data/models/tracking.dart';

// Active SOS provider
final activeSosProvider =
    StateNotifierProvider<ActiveSosNotifier, AsyncValue<SosEvent?>>(
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
final sosEventProvider =
    FutureProvider.family<SosEvent, int>((ref, id) async {
  final api = ref.read(sosApiProvider);
  return api.getSosEvent(id);
});

// Tracking provider with WebSocket + fallback HTTP polling
class TrackingNotifier extends StateNotifier<AsyncValue<TrackingInfo?>> {
  final SosApi _sosApi;
  final WebSocketService _wsService;
  final int _sosId;
  Timer? _timer;
  StompUnsubscribe? _statusUnsub;
  StompUnsubscribe? _locationUnsub;

  static const int _wsFallbackPollSeconds = 30;

  TrackingNotifier(this._sosApi, this._wsService, this._sosId)
      : super(const AsyncValue.loading()) {
    _fetch();
    _subscribeWebSocket();
  }

  void _subscribeWebSocket() {
    _statusUnsub = _wsService.subscribe(
      '/topic/sos/$_sosId/status',
      _onStatusUpdate,
    );
    _locationUnsub = _wsService.subscribe(
      '/topic/sos/$_sosId/location',
      _onLocationUpdate,
    );
  }

  void _onStatusUpdate(Map<String, dynamic> data) {
    if (!mounted) return;
    final current = state.valueOrNull;
    if (current == null) {
      _fetch();
      return;
    }

    final newStatus = data['status'] as String? ?? current.status;
    state = AsyncValue.data(TrackingInfo(
      sosEventId: current.sosEventId,
      status: newStatus,
      ambulanceLatitude: current.ambulanceLatitude,
      ambulanceLongitude: current.ambulanceLongitude,
      driverName: data['driverName'] as String? ?? current.driverName,
      driverPhone: data['driverPhone'] as String? ?? current.driverPhone,
      ambulanceRegistrationNumber:
          data['ambulanceRegistrationNumber'] as String? ??
              current.ambulanceRegistrationNumber,
      hospitalName: data['hospitalName'] as String? ?? current.hospitalName,
      hospitalAddress:
          data['hospitalAddress'] as String? ?? current.hospitalAddress,
      estimatedMinutesArrival: current.estimatedMinutesArrival,
      locationHistory: current.locationHistory,
    ));

    if (newStatus == AppConstants.statusCompleted ||
        newStatus == AppConstants.statusCancelled) {
      stopPolling();
    }
  }

  void _onLocationUpdate(Map<String, dynamic> data) {
    if (!mounted) return;
    final current = state.valueOrNull;
    if (current == null) return;

    final lat = data['latitude'] != null
        ? double.tryParse(data['latitude'].toString())
        : null;
    final lng = data['longitude'] != null
        ? double.tryParse(data['longitude'].toString())
        : null;

    if (lat == null || lng == null) return;

    state = AsyncValue.data(TrackingInfo(
      sosEventId: current.sosEventId,
      status: current.status,
      ambulanceLatitude: lat,
      ambulanceLongitude: lng,
      driverName: current.driverName,
      driverPhone: current.driverPhone,
      ambulanceRegistrationNumber: current.ambulanceRegistrationNumber,
      hospitalName: current.hospitalName,
      hospitalAddress: current.hospitalAddress,
      estimatedMinutesArrival: current.estimatedMinutesArrival,
      locationHistory: [
        ...current.locationHistory,
        LocationPoint(
          latitude: lat,
          longitude: lng,
          recordedAt: data['timestamp'] as String?,
        ),
      ],
    ));
  }

  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(
        seconds: _wsService.isConnected
            ? _wsFallbackPollSeconds
            : AppConstants.trackingPollIntervalSeconds,
      ),
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
    _statusUnsub?.call(unsubscribeHeaders: {});
    _locationUnsub?.call(unsubscribeHeaders: {});
    super.dispose();
  }
}

final trackingProvider = StateNotifierProvider.family<TrackingNotifier,
    AsyncValue<TrackingInfo?>, int>((ref, sosId) {
  final notifier = TrackingNotifier(
    ref.read(sosApiProvider),
    ref.read(websocketServiceProvider),
    sosId,
  );
  notifier.startPolling();
  return notifier;
});
