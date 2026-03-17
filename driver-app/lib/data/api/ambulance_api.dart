import 'package:driver_app/core/network/api_client.dart';

class AmbulanceApi {
  final ApiClient _client;

  AmbulanceApi(this._client);

  Future<void> updateLocation(
    int ambulanceId,
    double latitude,
    double longitude,
  ) async {
    await _client.dio.patch(
      '/ambulances/$ambulanceId/location',
      data: {'latitude': latitude, 'longitude': longitude},
    );
  }
}
