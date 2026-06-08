import 'package:flutter_test/flutter_test.dart';
import 'package:space_invaders/main.dart';

void main() {
  testWidgets('Game loads without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const SpaceInvadersApp());
    await tester.pump();
    expect(find.byType(SpaceInvadersApp), findsOneWidget);
  });
}
