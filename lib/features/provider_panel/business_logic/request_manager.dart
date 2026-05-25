import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/models.dart';
import '../data/services/provider_api_service.dart';
import 'provider_validators.dart';

final requestManagerProvider =
    StateNotifierProvider<RequestManager, AsyncValue<List<BookingRequest>>>(
  (ref) {
    final manager = RequestManager(ref.watch(providerApiServiceProvider));
    ref.onDispose(manager.dispose);
    return manager;
  },
);

/// Stream of pending requests with 30s polling (plan 3.13).
final pendingRequestsStreamProvider =
    StreamProvider<List<BookingRequest>>((ref) {
  final manager = ref.watch(requestManagerProvider.notifier);
  return manager.watchPendingRequests();
});

class RequestManager extends StateNotifier<AsyncValue<List<BookingRequest>>> {
  RequestManager(this._api) : super(const AsyncValue.loading()) {
    _startAutoRefresh();
  }

  final ProviderApiService _api;
  Timer? _refreshTimer;

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (state is! AsyncLoading) {
        refresh();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Stream<List<BookingRequest>> watchPendingRequests() async* {
    yield await _loadPending();
    yield* Stream.periodic(const Duration(seconds: 30), (_) => _loadPending())
        .asyncMap((event) => event);
  }

  Future<List<BookingRequest>> _loadPending() async {
    final requests = await _api.getPendingRequests();
    final sorted = ProviderValidators.sortByCreatedAtDesc(
      requests,
      (r) => r.createdAt,
    );
    state = AsyncValue.data(sorted);
    return sorted;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadPending);
  }

  List<BookingRequest> filterUrgent(List<BookingRequest> requests) =>
      requests.where((r) => r.isUrgent).toList();

  Future<void> acceptRequest(String id) async {
    await _api.acceptRequest(id);
    await refresh();
  }

  Future<void> declineRequest(String id, String reason) async {
    await _api.declineRequest(id, reason);
    await refresh();
  }

  Future<void> sendCounterOffer(
    String id, {
    required double price,
    String? message,
  }) async {
    if (!ProviderValidators.validateCounterPrice(price)) {
      throw Exception('Price must be greater than zero');
    }
    await _api.sendCounterOffer(
      id,
      counterPrice: price,
      message: message,
    );
    await refresh();
  }
}
