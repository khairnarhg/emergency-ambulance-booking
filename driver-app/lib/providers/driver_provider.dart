import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver_app/providers/auth_provider.dart';
import 'package:driver_app/data/api/driver_api.dart';
import 'package:driver_app/data/models/driver.dart';

final driverApiProvider = Provider<DriverApi>((ref) {
  return DriverApi(ref.read(apiClientProvider));
});

class DriverState {
  final Driver? driver;
  final bool isLoading;
  final String? error;

  const DriverState({this.driver, this.isLoading = false, this.error});

  DriverState copyWith({Driver? driver, bool? isLoading, String? error}) {
    return DriverState(
      driver: driver ?? this.driver,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DriverNotifier extends StateNotifier<DriverState> {
  final DriverApi _driverApi;

  DriverNotifier(this._driverApi) : super(const DriverState());

  Future<void> loadDriver() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final driver = await _driverApi.getMe();
      state = state.copyWith(driver: driver, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load driver profile',
      );
    }
  }

  Future<void> updateStatus(String status) async {
    try {
      final driver = await _driverApi.updateStatus(status);
      state = state.copyWith(driver: driver);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update status');
    }
  }
}

final driverProvider =
    StateNotifierProvider<DriverNotifier, DriverState>((ref) {
  return DriverNotifier(ref.read(driverApiProvider));
});
