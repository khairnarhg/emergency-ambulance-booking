import 'package:driver_app/core/network/api_client.dart';
import 'package:driver_app/data/models/sos_event.dart';

class DispatchApi {
  final ApiClient _client;

  DispatchApi(this._client);

  Future<List<SosEvent>> getPendingRequests() async {
    final response = await _client.dio.get('/dispatch/pending-requests');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => SosEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SosEvent> getRequestDetails(int sosId) async {
    final response = await _client.dio.get(
      '/dispatch/$sosId/request-details',
    );
    return SosEvent.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> acceptRequest(int sosId) async {
    await _client.dio.post('/dispatch/$sosId/accept');
  }

  Future<void> rejectRequest(int sosId) async {
    await _client.dio.post('/dispatch/$sosId/reject');
  }
}
