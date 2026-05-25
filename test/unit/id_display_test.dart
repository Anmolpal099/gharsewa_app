import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/core/utils/id_display.dart';

void main() {
  test('shortId does not throw on short ids', () {
    expect(shortId('bkg-001'), 'bkg-001');
    expect(shortId('1234567890123456'), '12345678');
  });
}
