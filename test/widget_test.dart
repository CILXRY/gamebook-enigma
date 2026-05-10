import 'package:flutter_test/flutter_test.dart';

import 'package:gamebook_enigma/main.dart';

void main() {
  testWidgets('App should show title', (WidgetTester tester) async {
    await tester.pumpWidget(const GameBookApp());
    expect(find.text('游戏本子'), findsOneWidget);
  });
}
