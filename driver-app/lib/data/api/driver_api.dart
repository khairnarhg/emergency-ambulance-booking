import 'package:driver_app/core/network/api_client.dart';
import 'package:driver_app/data/models/driver.dart';

class DriverApi {
  final ApiClient _client;

  DriverApi(this._client);

  Future<Driver> getMe() async {
    final response = await _client.dio.get('/drivers/me');
    return Driver.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Driver> updateStatus(String status) async {
    final response = await _client.dio.patch(
      '/drivers/me',
      data: {'status': status},
    );
    return Driver.fromJson(response.data as Map<String, dynamic>);
  }
}
