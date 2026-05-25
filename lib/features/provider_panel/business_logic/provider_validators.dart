/// Validation helpers for provider panel business rules.

class ProviderValidators {
  ProviderValidators._();

  static bool validateBio(String? bio) {
    if (bio == null) return false;
    final len = bio.trim().length;
    return len >= 50 && len <= 500;
  }

  static bool validateSkill(String skill) {
    final len = skill.trim().length;
    return len >= 3 && len <= 50;
  }

  static bool isDuplicateSkill(List<String> skills, String newSkill) {
    final normalized = newSkill.trim().toLowerCase();
    return skills.any((s) => s.trim().toLowerCase() == normalized);
  }

  static bool canAddSkill(List<String> skills) => skills.length < 20;

  static bool validateCertificationFile(String path, int sizeBytes) {
    final ext = path.split('.').last.toLowerCase();
    const allowed = {'pdf', 'png', 'jpg', 'jpeg'};
    if (!allowed.contains(ext)) return false;
    return sizeBytes <= 10 * 1024 * 1024;
  }

  static bool validateCounterPrice(double price) => price > 0;

  static String formatPercentage(double value) =>
      '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}%';

  static String formatResponseTime(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 60) return '$minutes min';
    final hours = (minutes / 60).toStringAsFixed(1);
    return '$hours hr';
  }

  static ColorToken responseTimeColor(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 15) return ColorToken.green;
    if (minutes <= 60) return ColorToken.yellow;
    return ColorToken.red;
  }

  static List<T> sortByCreatedAtDesc<T>(
    List<T> items,
    DateTime Function(T item) createdAt,
  ) {
    final sorted = List<T>.from(items);
    sorted.sort((a, b) => createdAt(b).compareTo(createdAt(a)));
    return sorted;
  }

  static bool isUrgent(DateTime scheduled) {
    final diff = scheduled.difference(DateTime.now());
    return diff.inHours <= 24 && !diff.isNegative;
  }

  static double percentageChange(double current, double previous) {
    if (previous == 0) return 0;
    return ((current - previous) / previous) * 100;
  }
}

enum ColorToken { green, yellow, red }
