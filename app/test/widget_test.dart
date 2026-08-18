import 'package:flutter_test/flutter_test.dart';

import 'package:bhugtaanmilaan_app/main.dart';

void main() {
  test('channelTotals sums per channel', () {
    final t = channelTotals([Payment('cash', 100), Payment('upi', 250), Payment('cash', 50)]);
    expect(t['cash'], 150);
    expect(t['upi'], 250);
    expect(t['card'], 0);
  });

  testWidgets('renders payment logger', (tester) async {
    await tester.pumpWidget(const BhugtaanmilaanApp());
    expect(find.text('Log a payment as it happens'), findsOneWidget);
  });
}
