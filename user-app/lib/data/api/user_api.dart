import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../models/user.dart';

final userApiProvider = Provider<UserApi>((ref) {
  return UserApi(ref.read(apiClientProvider));
});

class UserApi {
  final ApiClient _client;

  UserApi(this._client);

  Future<UserProfile> getProfile() async {
    final response = await _client.dio.get('/users/me');
    final data = response.data;
    if (data is Map && data.containsKey('data')) {
      return UserProfile.fromJson(data['data'] as Map<String, dynamic>);
    }
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    final response = await _client.dio.patch(
      '/users/me',
      data: {
        if (fullName != null) 'fullName': fullName,
        if (phone != null) 'phone': phone,
      },
    );
    final data = response.data;
    if (data is Map && data.containsKey('data')) {
      return UserProfile.fromJson(data['data'] as Map<String, dynamic>);
    }
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<MedicalProfile?> getMedicalProfile() async {
    try {
      final response = await _client.dio.get('/users/me/medical-profile');
      final data = response.data;
      if (data == null) return null;
      if (data is Map && data.containsKey('data')) {
        return MedicalProfile.fromJson(data['data'] as Map<String, dynamic>);
      }
      return MedicalProfile.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<MedicalProfile> updateMedicalProfile(MedicalProfile profile) async {
    final response = await _client.dio.patch(
      '/users/me/medical-profile',
      data: profile.toJson(),
    );
    final data = response.data;
    if (data is Map && data.containsKey('data')) {
      return MedicalProfile.fromJson(data['data'] as Map<String, dynamic>);
    }
    return MedicalProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<List<EmergencyContact>> getEmergencyContacts() async {
    final response = await _client.dio.get('/users/me/emergency-contacts');
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
        .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EmergencyContact> addEmergencyContact(EmergencyContact contact) async {
    final response = await _client.dio.post(
      '/users/me/emergency-contacts',
      data: contact.toJson(),
    );
    final data = response.data;
    if (data is Map && data.containsKey('data')) {
      return EmergencyContact.fromJson(data['data'] as Map<String, dynamic>);
    }
    return EmergencyContact.fromJson(data as Map<String, dynamic>);
  }

  Future<EmergencyContact> updateEmergencyContact(
    int id,
    EmergencyContact contact,
  ) async {
    final response = await _client.dio.patch(
      '/users/me/emergency-contacts/$id',
      data: contact.toJson(),
    );
    final data = response.data;
    if (data is Map && data.containsKey('data')) {
      return EmergencyContact.fromJson(data['data'] as Map<String, dynamic>);
    }
    return EmergencyContact.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteEmergencyContact(int id) async {
    await _client.dio.delete('/users/me/emergency-contacts/$id');
  }
}
