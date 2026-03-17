import 'package:driver_app/core/network/api_client.dart';
import 'package:driver_app/data/models/triage_record.dart';
import 'package:driver_app/data/models/medication.dart';

class TriageApi {
  final ApiClient _client;

  TriageApi(this._client);

  Future<TriageRecord> createRecord(TriageRecord record) async {
    final response = await _client.dio.post(
      '/triage/records',
      data: record.toJson(),
    );
    return TriageRecord.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<TriageRecord>> getRecords(int sosEventId) async {
    final response = await _client.dio.get(
      '/triage/records',
      queryParameters: {'sosEventId': sosEventId},
    );
    final data = response.data as List<dynamic>;
    return data
        .map((e) => TriageRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Medication> createMedication(Medication medication) async {
    final response = await _client.dio.post(
      '/triage/medications',
      data: medication.toJson(),
    );
    return Medication.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Medication>> getMedications(int sosEventId) async {
    final response = await _client.dio.get(
      '/triage/medications',
      queryParameters: {'sosEventId': sosEventId},
    );
    final data = response.data as List<dynamic>;
    return data
        .map((e) => Medication.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
