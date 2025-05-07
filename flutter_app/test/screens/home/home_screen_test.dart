import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/src/screens/home/home_screen.dart';

void main() {
  testWidgets('HomeScreen displays title', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: HomeScreen(),
    ));
    expect(find.text('My Goals'), findsOneWidget);
  });

  testWidgets('HomeScreen displays a list of goals with progress bars', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: HomeScreen(),
    ));
    // Check for mock goal titles
    expect(find.text('📚 Academic Growth'), findsOneWidget);
    expect(find.text('💡 Personal Growth'), findsOneWidget);
    expect(find.text('🎨 Learn a New Skill'), findsOneWidget);
    // Check for three progress indicators
    expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
  });

  testWidgets('HomeScreen displays a BottomNavigationBar with three items', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: HomeScreen(),
    ));
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
  });

  testWidgets("HomeScreen displays Today's Tasks to-do list", (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: HomeScreen(),
    ));
    expect(find.text("Today's Tasks"), findsOneWidget);
    expect(find.text('Finish 1 chapter of HCI textbook'), findsOneWidget);
    expect(find.text('Watch 30-min tutorial on Figma'), findsOneWidget);
  });
}
