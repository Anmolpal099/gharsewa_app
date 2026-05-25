/// Placeholder model for AI scheduling assistant (replace when backend/model is ready).
class SchedulingSuggestion {
  final Duration gapDuration;
  final DateTime gapStart;
  final String? customMessage;

  const SchedulingSuggestion({
    required this.gapDuration,
    required this.gapStart,
    this.customMessage,
  });

  String get displayMessage {
    if (customMessage != null && customMessage!.isNotEmpty) {
      return customMessage!;
    }
    final hours = gapDuration.inHours;
    final hLabel = hours == 1 ? '1h' : '${hours}h';
    final dayLabel = _isTomorrow(gapStart) ? 'tomorrow' : _formatDay(gapStart);
    final time = _formatTime(gapStart);
    return 'You have a $hLabel gap $dayLabel at $time.';
  }

  bool _isTomorrow(DateTime dt) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return dt.year == tomorrow.year &&
        dt.month == tomorrow.month &&
        dt.day == tomorrow.day;
  }

  String _formatDay(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour $period';
  }
}
