import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/features/provider_panel/business_logic/provider_validators.dart';

void main() {
  group('ProviderValidators.validateBio', () {
    test('returns true for 50-500 characters', () {
      expect(ProviderValidators.validateBio('a' * 50), isTrue);
      expect(ProviderValidators.validateBio('a' * 500), isTrue);
    });

    test('returns false outside bounds', () {
      expect(ProviderValidators.validateBio('a' * 49), isFalse);
      expect(ProviderValidators.validateBio('a' * 501), isFalse);
      expect(ProviderValidators.validateBio(null), isFalse);
    });
  });

  group('ProviderValidators.validateSkill', () {
    test('returns true for 3-50 characters', () {
      expect(ProviderValidators.validateSkill('abc'), isTrue);
      expect(ProviderValidators.validateSkill('a' * 50), isTrue);
    });

    test('returns false outside bounds', () {
      expect(ProviderValidators.validateSkill('ab'), isFalse);
      expect(ProviderValidators.validateSkill('a' * 51), isFalse);
    });
  });

  group('ProviderValidators.isDuplicateSkill', () {
    test('rejects case-insensitive duplicates', () {
      expect(
        ProviderValidators.isDuplicateSkill(['Plumbing'], 'plumbing'),
        isTrue,
      );
      expect(
        ProviderValidators.isDuplicateSkill(['Plumbing'], 'Electrical'),
        isFalse,
      );
    });
  });

  group('ProviderValidators.canAddSkill', () {
    test('allows when under 20 skills', () {
      expect(ProviderValidators.canAddSkill(List.filled(19, 'x')), isTrue);
      expect(ProviderValidators.canAddSkill(List.filled(20, 'x')), isFalse);
    });
  });

  group('ProviderValidators.validateCounterPrice', () {
    test('returns true only when price > 0', () {
      expect(ProviderValidators.validateCounterPrice(1), isTrue);
      expect(ProviderValidators.validateCounterPrice(0), isFalse);
      expect(ProviderValidators.validateCounterPrice(-1), isFalse);
    });
  });

  group('ProviderValidators.percentageChange', () {
    test('calculates change correctly', () {
      expect(ProviderValidators.percentageChange(150, 100), 50);
      expect(ProviderValidators.percentageChange(50, 100), -50);
      expect(ProviderValidators.percentageChange(100, 0), 0);
    });
  });

  group('ProviderValidators.formatPercentage', () {
    test('uses one decimal place', () {
      expect(ProviderValidators.formatPercentage(12.34), '+12.3%');
      expect(ProviderValidators.formatPercentage(-5.0), '-5.0%');
    });
  });

  group('ProviderValidators.sortByCreatedAtDesc', () {
    test('maintains descending createdAt order', () {
      final a = DateTime(2026, 1, 1);
      final b = DateTime(2026, 1, 3);
      final c = DateTime(2026, 1, 2);
      final sorted = ProviderValidators.sortByCreatedAtDesc(
        [a, b, c],
        (d) => d,
      );
      expect(sorted, [b, c, a]);
    });
  });

  group('ProviderValidators.validateCertificationFile', () {
    test('allows pdf/png/jpg under 10MB', () {
      expect(
        ProviderValidators.validateCertificationFile('cert.pdf', 1024),
        isTrue,
      );
      expect(
        ProviderValidators.validateCertificationFile('photo.JPG', 5 * 1024 * 1024),
        isTrue,
      );
      expect(
        ProviderValidators.validateCertificationFile('doc.exe', 1024),
        isFalse,
      );
      expect(
        ProviderValidators.validateCertificationFile('big.pdf', 11 * 1024 * 1024),
        isFalse,
      );
    });
  });

  group('ProviderValidators.formatResponseTime', () {
    test('formats minutes and hours', () {
      expect(
        ProviderValidators.formatResponseTime(const Duration(minutes: 30)),
        '30 min',
      );
      expect(
        ProviderValidators.formatResponseTime(const Duration(minutes: 90)),
        '1.5 hr',
      );
    });
  });

  group('ProviderValidators.responseTimeColor', () {
    test('maps duration to color tokens', () {
      expect(
        ProviderValidators.responseTimeColor(const Duration(minutes: 5)),
        ColorToken.green,
      );
      expect(
        ProviderValidators.responseTimeColor(const Duration(minutes: 30)),
        ColorToken.yellow,
      );
      expect(
        ProviderValidators.responseTimeColor(const Duration(minutes: 120)),
        ColorToken.red,
      );
    });
  });

  group('ProviderValidators.isUrgent', () {
    test('true when scheduled within 24 hours', () {
      final soon = DateTime.now().add(const Duration(hours: 12));
      expect(ProviderValidators.isUrgent(soon), isTrue);
    });

    test('false when more than 24 hours away', () {
      final later = DateTime.now().add(const Duration(hours: 48));
      expect(ProviderValidators.isUrgent(later), isFalse);
    });
  });
}
