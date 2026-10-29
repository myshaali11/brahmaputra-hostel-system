import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App starts and displays login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BrahmaputraHostelApp());
    expect(find.text('Brahmaputra Hostel'), findsOneWidget);
  });
}
