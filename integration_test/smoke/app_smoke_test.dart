import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taptapdoner/app/tap_tap_doner_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots to the game shell', (tester) async {
    await tester.pumpWidget(const TapTapDonerApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('TapTap Doner'), findsWidgets);
  });
}
