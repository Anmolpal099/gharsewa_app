/// AI Consultation State Management
/// 
/// This file exports all state management providers for the AI Visual Assistant feature.
/// 
/// Usage:
/// ```dart
/// import 'package:gharsewa/presentation/panels/customer/ai_consultation/state/ai_consultation_providers.dart';
/// 
/// // Access providers in widgets
/// final consultation = ref.watch(currentConsultationProvider);
/// final history = ref.watch(consultationHistoryProvider);
/// final markers = ref.watch(markersProvider);
/// ```
library ai_consultation_providers;

// State classes
export 'current_consultation_state.dart';

// Notifiers
export 'current_consultation_notifier.dart';
export 'consultation_history_provider.dart';
export 'markers_notifier.dart';
