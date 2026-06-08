import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_app/main.dart';

void main() {
  testWidgets('app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const OshiApp());

    expect(find.byType(OshiApp), findsOneWidget);
  });
}
