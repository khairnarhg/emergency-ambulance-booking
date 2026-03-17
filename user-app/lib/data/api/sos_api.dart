import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../models/sos_event.dart';
import '../models/tracking.dart';

final sosApiProvider = Provider<SosApi>((ref) {
  return SosApi(ref.read(apiClientProvider));
});

class SosApi {
  final ApiClient _client;

  SosApi(this._client);

  Future<SosEvent> createSos({
    required double latitude,
    required double longitude,
    String? address,
    String? symptoms,
    String? criticality,
  }) async {
    final response = await _client.dio.post(
      '/sos-events',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
        if (symptoms != null) 'symptoms': symptoms,
        if (criticality != null) 'criticality': criticality,
      },
    );
    final data = response.data;
    if (data is Map && data.containsKey('data')) {
      return SosEvent.fromJson(data['data'] as Map<String, dynamic>);
    }
    return SosEvent.fromJson(data as Map<String, dynamic>);
  }

  Future<SosEvent> updateSos({
    required int id,
    String? symptoms,
    String? criticality,
  }) async {
    final response = await _client.dio.patch(
      '/sos-events/$id',
      data: {
        if (symptoms != null) 'symptoms': symptoms,
        if (criticality != null) 'criticality': criticality,
      },
    );
    final data = response.data;
    if (data is Map && data.containsKey('data')) {
      return SosEvent.fromJson(data['data'] as Map<String, dynamic>);
    }
    return SosEvent.fromJson(data as Map<String, dynamic>);
  }

  Future<SosEvent> getSosEvent(int id) async {
    final response = await _client.dio.get('/sos-events/$id');
    final data = response.data;
    if (data is Map && data.containsKey('data')) {
      return SosEvent.fromJson(data['data'] as Map<String, dynamic>);
    }
    return SosEvent.fromJson(data as Map<String, dynamic>);
  }

  Future<List<SosEvent>> getMySosEvents() async {
    final response = await _client.dio.get('/sos-events/my');
    final data = response.data;
    List<dynamic> list;
    if (data is Map && data.containsKey('data')) {
      list = data['data'] as List<dynamic>;
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }
    return list
        .map((e) => SosEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SosEvent>> getMyActiveSos() async {
    final response = await _client.dio.get('/sos-events/my/active');
    final data = response.data;
    List<dynamic> list;
    if (data is Map && data.containsKey('data')) {
      list = data['data'] as List<dynamic>;
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }
    return list
        .map((e) => SosEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TrackingInfo> getTracking(int sosId) async {
    final response = await _client.dio.get('/sos-events/$sosId/tracking');
    final data = response.data;
    if (data is Map && data.containsKey('data')) {
      return TrackingInfo.fromJson(data['data'] as Map<String, dynamic>);
    }
    return TrackingInfo.fromJson(data as Map<String, dynamic>);
  }

  Future<void> cancelSos(int id) async {
    await _client.dio.delete('/sos-events/$id');
  }
}
