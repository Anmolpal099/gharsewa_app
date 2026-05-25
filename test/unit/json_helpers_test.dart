import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/core/utils/json_helpers.dart';

void main() {
  group('asJsonMap', () {
    test('returns empty map for JSON array metadata', () {
      expect(asJsonMap(<dynamic>[]), isEmpty);
    });

    test('copies string-keyed maps', () {
      final input = {'skills': ['plumbing'], 'bio': 'Hello'};
      expect(asJsonMap(input), input);
    });
  });

  group('requireJsonMap', () {
    test('throws for list payloads', () {
      expect(
        () => requireJsonMap(<dynamic>[], field: 'data'),
        throwsFormatException,
      );
    });
  });
}
