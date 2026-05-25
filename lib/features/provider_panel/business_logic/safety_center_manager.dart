import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/safety_sop.dart';
import '../data/services/cache_manager.dart';
import '../data/services/provider_api_service.dart';

final safetyCenterManagerProvider =
    StateNotifierProvider<SafetyCenterManager, SafetyCenterState>((ref) {
  return SafetyCenterManager(
    ref.watch(providerApiServiceProvider),
    ref.watch(cacheManagerProvider),
  );
});

class SafetyCenterState {
  final List<SafetySOP> savedSops;
  final SafetySOP? generatedSop;
  final bool isGenerating;
  final bool isOffline;
  final bool showSlowMessage;
  final String? error;
  final String searchQuery;

  const SafetyCenterState({
    this.savedSops = const [],
    this.generatedSop,
    this.isGenerating = false,
    this.isOffline = false,
    this.showSlowMessage = false,
    this.error,
    this.searchQuery = '',
  });

  List<SafetySOP> get filteredSops {
    if (searchQuery.isEmpty) return savedSops;
    final q = searchQuery.toLowerCase();
    return savedSops
        .where(
          (s) =>
              s.jobType.toLowerCase().contains(q) ||
              s.content.toLowerCase().contains(q),
        )
        .toList();
  }

  SafetyCenterState copyWith({
    List<SafetySOP>? savedSops,
    SafetySOP? generatedSop,
    bool? isGenerating,
    bool? isOffline,
    bool? showSlowMessage,
    String? error,
    String? searchQuery,
    bool clearGenerated = false,
    bool clearError = false,
  }) {
    return SafetyCenterState(
      savedSops: savedSops ?? this.savedSops,
      generatedSop: clearGenerated ? null : (generatedSop ?? this.generatedSop),
      isGenerating: isGenerating ?? this.isGenerating,
      isOffline: isOffline ?? this.isOffline,
      showSlowMessage: showSlowMessage ?? this.showSlowMessage,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class SafetyCenterManager extends StateNotifier<SafetyCenterState> {
  SafetyCenterManager(this._api, this._cache)
      : super(const SafetyCenterState()) {
    fetchSavedSOPs();
    _monitorConnectivity();
  }

  final ProviderApiService _api;
  final CacheManager _cache;
  StreamSubscription<ConnectivityResult>? _connectivitySub;
  Timer? _slowTimer;

  void _monitorConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      final offline = result == ConnectivityResult.none;
      state = state.copyWith(isOffline: offline);
      if (!offline) syncSOPs();
    });
    Connectivity().checkConnectivity().then((result) {
      state = state.copyWith(isOffline: result == ConnectivityResult.none);
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _slowTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchSavedSOPs() async {
    final raw = _cache.getAllSafetySOPsOffline();
    final sops = raw.map(SafetySOP.fromJson).toList();
    state = state.copyWith(savedSops: sops);
  }

  Future<void> generateSOP(String jobType) async {
    if (jobType.trim().isEmpty) {
      state = state.copyWith(error: 'Enter a job type');
      return;
    }
    state = state.copyWith(
      isGenerating: true,
      clearError: true,
      clearGenerated: true,
      showSlowMessage: false,
    );
    _slowTimer?.cancel();
    _slowTimer = Timer(const Duration(seconds: 10), () {
      if (state.isGenerating) {
        state = state.copyWith(showSlowMessage: true);
      }
    });
    try {
      final sop = await _api.generateSafetySOP(jobType);
      _slowTimer?.cancel();
      state = state.copyWith(
        generatedSop: sop,
        isGenerating: false,
        showSlowMessage: false,
      );
    } catch (e) {
      _slowTimer?.cancel();
      state = state.copyWith(
        isGenerating: false,
        showSlowMessage: false,
        error: 'Failed to generate SOP. Tap retry.',
      );
    }
  }

  /// Re-load local SOP library (plan 3.18 sync).
  Future<void> syncSOPs() async {
    await fetchSavedSOPs();
  }

  Future<void> saveSOP(SafetySOP sop) async {
    const uuid = Uuid();
    final saved = sop.copyWith(
      id: sop.id.isEmpty ? uuid.v4() : sop.id,
      isSaved: true,
    );
    await _cache.saveSafetySOPOffline(saved.id, saved.toJson());
    await fetchSavedSOPs();
    state = state.copyWith(generatedSop: saved);
  }

  Future<void> deleteSOP(String id) async {
    await _cache.deleteSafetySOPOffline(id);
    await fetchSavedSOPs();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}
