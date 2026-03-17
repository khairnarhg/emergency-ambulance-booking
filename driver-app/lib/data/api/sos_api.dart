import 'package:driver_app/core/network/api_client.dart';
import 'package:driver_app/data/models/sos_event.dart';
import 'package:driver_app/data/models/tracking.dart';

class SosApi {
  final ApiClient _client;

  SosApi(this._client);

  Future<SosEvent> getById(int id) async {
    final response = await _client.dio.get('/sos-events/$id');
    return SosEvent.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Tracking> getTracking(int id) async {
    final response = await _client.dio.get('/sos-events/$id/tracking');
    return Tracking.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SosEvent> updateStatus(int id, String status) async {
    final response = await _client.dio.patch(
      '/sos-events/$id/status',
      data: {'status': status},
    );
    return SosEvent.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> complete(int id) async {
    await _client.dio.post('/sos-events/$id/complete');
  }

  Future<List<SosEvent>> getDriverHistory() async {
    final response = await _client.dio.get('/sos-events/driver/history');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => SosEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SosEvent?> getDriverActive() async {
    try {
      final response = await _client.dio.get('/sos-events/driver/active');
      if (response.data == null || response.data == '') return null;
      return SosEvent.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
