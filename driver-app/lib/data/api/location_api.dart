import 'package:driver_app/core/network/api_client.dart';

class LocationApi {
  final ApiClient _client;

  LocationApi(this._client);

  Future<void> postLocation({
    required int ambulanceId,
    required int sosEventId,
    required double latitude,
    required double longitude,
  }) async {
    await _client.dio.post('/locations', data: {
      'ambulanceId': ambulanceId,
      'sosEventId': sosEventId,
      'latitude': latitude,
      'longitude': longitude,
    });
  }
}
