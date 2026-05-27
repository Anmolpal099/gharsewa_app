import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../data/models/ai_consultation_models.dart';
import '../../../../../../services/api/ai_consultation_api_service.dart';
import '../../../../../../services/api/api_exception.dart';

/// State for consultation history
class ConsultationHistoryState {
  final List<AIConsultationModel> consultations;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int? lastPage;
  final int total;
  final String? serviceTypeFilter;

  const ConsultationHistoryState({
    this.consultations = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.lastPage,
    this.total = 0,
    this.serviceTypeFilter,
  });

  ConsultationHistoryState copyWith({
    List<AIConsultationModel>? consultations,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    int? lastPage,
    int? total,
    String? serviceTypeFilter,
    bool clearError = false,
    bool clearFilter = false,
  }) {
    return ConsultationHistoryState(
      consultations: consultations ?? this.consultations,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      serviceTypeFilter: clearFilter ? null : (serviceTypeFilter ?? this.serviceTypeFilter),
    );
  }

  bool get hasMore => lastPage != null && currentPage < lastPage!;
  bool get isEmpty => consultations.isEmpty && !isLoading;
  bool get hasError => error != null;
  bool get hasFilter => serviceTypeFilter != null && serviceTypeFilter!.isNotEmpty;
}

/// Notifier for consultation history
class ConsultationHistoryNotifier extends StateNotifier<ConsultationHistoryState> {
  final AIConsultationApiService _apiService;

  ConsultationHistoryNotifier(this._apiService)
      : super(const ConsultationHistoryState());

  /// Load initial consultations
  Future<void> loadConsultations({String? serviceType}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      serviceTypeFilter: serviceType,
      currentPage: 1,
    );

    try {
      final response = await _apiService.getConsultationHistory(
        page: 1,
        perPage: 20,
        serviceType: serviceType,
      );

      state = state.copyWith(
        consultations: response.consultations,
        isLoading: false,
        currentPage: response.currentPage,
        lastPage: response.lastPage,
        total: response.total,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load consultations',
      );
    }
  }

  /// Load more consultations (pagination)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(
      isLoadingMore: true,
      clearError: true,
    );

    try {
      final response = await _apiService.getConsultationHistory(
        page: state.currentPage + 1,
        perPage: 20,
        serviceType: state.serviceTypeFilter,
      );

      state = state.copyWith(
        consultations: [...state.consultations, ...response.consultations],
        isLoadingMore: false,
        currentPage: response.currentPage,
        lastPage: response.lastPage,
        total: response.total,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Failed to load more consultations',
      );
    }
  }

  /// Refresh consultations (pull-to-refresh)
  Future<void> refresh() async {
    await loadConsultations(serviceType: state.serviceTypeFilter);
  }

  /// Filter by service type
  Future<void> filterByServiceType(String? serviceType) async {
    await loadConsultations(serviceType: serviceType);
  }

  /// Clear filter
  Future<void> clearFilter() async {
    await loadConsultations();
  }

  /// Remove a consultation from the list (after deletion)
  void removeConsultation(String consultationId) {
    final updatedConsultations = state.consultations
        .where((c) => c.id != consultationId)
        .toList();

    state = state.copyWith(
      consultations: updatedConsultations,
      total: state.total - 1,
    );
  }

  /// Add a new consultation to the beginning of the list
  void addConsultation(AIConsultationModel consultation) {
    state = state.copyWith(
      consultations: [consultation, ...state.consultations],
      total: state.total + 1,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for consultation history
final consultationHistoryProvider =
    StateNotifierProvider<ConsultationHistoryNotifier, ConsultationHistoryState>(
  (ref) {
    final apiService = ref.watch(aiConsultationApiServiceProvider);
    return ConsultationHistoryNotifier(apiService);
  },
);

/// Provider for a single consultation by ID
final consultationByIdProvider =
    FutureProvider.family<AIConsultationModel, String>((ref, id) async {
  final apiService = ref.watch(aiConsultationApiServiceProvider);
  return await apiService.getConsultationById(id);
});

/// Provider for deleting a consultation
final deleteConsultationProvider =
    FutureProvider.family<String, String>((ref, id) async {
  final apiService = ref.watch(aiConsultationApiServiceProvider);
  final message = await apiService.deleteConsultation(id);
  
  // Remove from history after successful deletion
  ref.read(consultationHistoryProvider.notifier).removeConsultation(id);
  
  return message;
});
