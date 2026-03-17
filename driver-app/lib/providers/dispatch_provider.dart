import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver_app/providers/auth_provider.dart';
import 'package:driver_app/data/api/dispatch_api.dart';
import 'package:driver_app/data/api/sos_api.dart';
import 'package:driver_app/data/models/sos_event.dart';

final dispatchApiProvider = Provider<DispatchApi>((ref) {
  return DispatchApi(ref.read(apiClientProvider));
});

final sosApiProvider = Provider<SosApi>((ref) {
  return SosApi(ref.read(apiClientProvider));
});

class DispatchState {
  final List<SosEvent> pendingRequests;
  final SosEvent? activeCase;
  final bool isLoading;
  final String? error;

  const DispatchState({
    this.pendingRequests = const [],
    this.activeCase,
    this.isLoading = false,
    this.error,
  });

  DispatchState copyWith({
    List<SosEvent>? pendingRequests,
    SosEvent? activeCase,
    bool? isLoading,
    String? error,
    bool clearActiveCase = false,
  }) {
    return DispatchState(
      pendingRequests: pendingRequests ?? this.pendingRequests,
      activeCase: clearActiveCase ? null : (activeCase ?? this.activeCase),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DispatchNotifier extends StateNotifier<DispatchState> {
  final DispatchApi _dispatchApi;
  final SosApi _sosApi;

  DispatchNotifier(this._dispatchApi, this._sosApi)
      : super(const DispatchState());

  Future<void> loadPendingRequests() async {
    try {
      final requests = await _dispatchApi.getPendingRequests();
      state = state.copyWith(pendingRequests: requests);
    } catch (_) {}
  }

  Future<void> loadActiveCase() async {
    try {
      final active = await _sosApi.getDriverActive();
      state = state.copyWith(activeCase: active, clearActiveCase: active == null);
    } catch (_) {}
  }

  Future<void> refreshActiveCase(int sosId) async {
    try {
      final sos = await _sosApi.getById(sosId);
      state = state.copyWith(activeCase: sos);
    } catch (_) {}
  }

  Future<bool> acceptRequest(int sosId) async {
    try {
      await _dispatchApi.acceptRequest(sosId);
      final sos = await _sosApi.getById(sosId);
      state = state.copyWith(activeCase: sos, pendingRequests: []);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectRequest(int sosId) async {
    try {
      await _dispatchApi.rejectRequest(sosId);
      state = state.copyWith(
        pendingRequests: state.pendingRequests
            .where((e) => e.id != sosId)
            .toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<SosEvent?> updateStatus(int sosId, String newStatus) async {
    try {
      final updated = await _sosApi.updateStatus(sosId, newStatus);
      state = state.copyWith(activeCase: updated);
      return updated;
    } catch (_) {
      return null;
    }
  }

  Future<bool> completeCase(int sosId) async {
    try {
      await _sosApi.complete(sosId);
      state = state.copyWith(clearActiveCase: true, pendingRequests: []);
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearActiveCase() {
    state = state.copyWith(clearActiveCase: true);
  }
}

final dispatchProvider =
    StateNotifierProvider<DispatchNotifier, DispatchState>((ref) {
  return DispatchNotifier(
    ref.read(dispatchApiProvider),
    ref.read(sosApiProvider),
  );
});
