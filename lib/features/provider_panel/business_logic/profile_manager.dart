import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/json_helpers.dart';
import '../data/models/models.dart';
import '../data/services/cache_manager.dart';
import '../data/services/provider_api_service.dart';
import '../data/services/provider_upload_service.dart';
import 'provider_validators.dart';

final profileManagerProvider =
    StateNotifierProvider<ProfileManager, AsyncValue<ProviderProfile>>((ref) {
  return ProfileManager(
    ref.watch(providerApiServiceProvider),
    ref.watch(cacheManagerProvider),
    ref.watch(providerUploadServiceProvider),
  );
});

class ProfileManager extends StateNotifier<AsyncValue<ProviderProfile>> {
  ProfileManager(this._api, this._cache, this._uploads)
      : super(const AsyncValue.loading());

  final ProviderApiService _api;
  final CacheManager _cache;
  final ProviderUploadService _uploads;
  static const _cacheKey = 'provider_profile';

  Future<void> fetchProfile({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _cache.get(_cacheKey);
      if (cached != null) {
        try {
          state = AsyncValue.data(
            ProviderProfile.fromJson(
              requireJsonMap(cached, field: 'provider_profile'),
            ),
          );
          return;
        } catch (_) {
          _cache.remove(_cacheKey);
        }
      }
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final profile = await _api.getProviderProfile();
      _cache.set(_cacheKey, profile.toJson());
      return profile;
    });
  }

  Future<void> updateBio(String bio) async {
    if (!ProviderValidators.validateBio(bio)) {
      throw Exception('Bio must be between 50 and 500 characters');
    }
    await _update({'business_description': bio.trim()});
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(bio: bio.trim()));
    }
  }

  Future<void> updateProfile(Map<String, dynamic> fields) async {
    await _update(fields);
  }

  Future<void> updateProfileDetails({
    String? name,
    String? phoneNumber,
    String? location,
    String? professionalCategory,
  }) async {
    final body = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) {
      body['name'] = name.trim();
    }
    if (phoneNumber != null) {
      body['phone_number'] = phoneNumber.trim();
    }
    if (location != null) {
      body['address'] = location.trim();
    }
    if (professionalCategory != null) {
      body['business_name'] = professionalCategory.trim();
    }
    if (body.isEmpty) return;
    await _update(body);
  }

  Future<void> addSkill(String skill) async {
    final current = state.value;
    if (current == null) return;
    if (!ProviderValidators.validateSkill(skill)) {
      throw Exception('Skill name must be between 3 and 50 characters');
    }
    if (!ProviderValidators.canAddSkill(current.skills)) {
      throw Exception('Maximum 20 skills allowed');
    }
    if (ProviderValidators.isDuplicateSkill(current.skills, skill)) {
      throw Exception('Skill already exists');
    }
    final skills = [...current.skills, skill.trim()];
    await _updateMetadata(skills: skills);
  }

  Future<void> removeSkill(String skill) async {
    final current = state.value;
    if (current == null) return;
    final skills = current.skills.where((s) => s != skill).toList();
    await _updateMetadata(skills: skills);
  }

  Future<void> updateCertifications(List<Certification> certifications) async {
    await _updateMetadata(certifications: certifications);
  }

  Future<void> updateProfilePhoto(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    await _uploads.uploadProfilePhoto(file, onProgress: onProgress);
    await fetchProfile(forceRefresh: true);
  }

  Future<Certification> uploadCertification(
    File file,
    String name, {
    void Function(double progress)? onProgress,
  }) async {
    final cert = await _uploads.uploadCertification(
      file,
      name,
      onProgress: onProgress,
    );
    await fetchProfile(forceRefresh: true);
    return cert;
  }

  double calculateProfileCompleteness(ProviderProfile profile) =>
      profile.completeness;

  bool validateBio(String? bio) => ProviderValidators.validateBio(bio);

  bool validateProfilePhoto(String? url) =>
      url != null && url.trim().isNotEmpty;

  Future<void> _update(Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final profile = await _api.updateProviderProfile(body);
      _cache.set(_cacheKey, profile.toJson());
      return profile;
    });
  }

  Future<void> _updateMetadata({
    List<String>? skills,
    List<Certification>? certifications,
  }) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(
      skills: skills ?? current.skills,
      certifications: certifications ?? current.certifications,
    );

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final profile = await _api.updateProviderProfile({
        'business_description': updated.bio,
        'business_name': updated.professionalCategory,
        'address': updated.location,
        'metadata': {
          'skills': updated.skills,
          'certifications':
              updated.certifications.map((c) => c.toJson()).toList(),
        },
      });
      _cache.set(_cacheKey, profile.toJson());
      return profile;
    });
  }
}
