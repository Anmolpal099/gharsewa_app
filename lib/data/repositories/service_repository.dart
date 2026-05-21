import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_model.dart';
import '../../services/api/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../datasources/local/mock_data.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>(
  (ref) => ServiceRepository(ref.read(apiClientProvider)),
);

class ServiceRepository {
  ServiceRepository(this._api);
  final ApiClient _api;

  Future<List<ServiceModel>> getServices({String? category, String? query}) async {
    try {
      final res = await _api.get(ApiConstants.customerServices, params: {
        if (category != null) 'category': category,
        if (query != null) 'q': query,
      });
      final data = res.data['data'] as List;
      return data.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Return mock data when backend is unavailable
      return MockData.services;
    }
  }

  Future<ServiceModel> getServiceById(String id) async {
    try {
      final res = await _api.get('${ApiConstants.customerServices}/$id');
      return ServiceModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (_) {
      return MockData.services.firstWhere((s) => s.id == id,
          orElse: () => MockData.services.first);
    }
  }

  Future<ServiceModel> createService(Map<String, dynamic> data) async {
    final res = await _api.post(ApiConstants.providerServices, data: data);
    return ServiceModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<ServiceModel> updateService(String id, Map<String, dynamic> data) async {
    final res = await _api.put('${ApiConstants.providerServices}/$id', data: data);
    return ServiceModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
