// Smoke test — verifies the test runner itself is healthy.
// Feature tests live in test/domain/ and test/widget/.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('arithmetic sanity', () {
    expect(2 + 2, 4);
    expect(10 - 3, 7);
    expect(2 * 6, 12);
  });
}
