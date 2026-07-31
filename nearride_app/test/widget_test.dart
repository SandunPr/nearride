import 'package:flutter_test/flutter_test.dart';
import 'package:nearride_app/app.dart';

void main() {
  testWidgets('NearRide renders its home shell', (tester) async {
    await tester.pumpWidget(const NearRideApp());
    expect(find.text('NearRide'), findsOneWidget);
  });
}
