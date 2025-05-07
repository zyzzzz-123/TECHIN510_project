import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/src/screens/login/login_screen.dart';
import 'package:flutter_app/src/screens/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LoginScreen displays email, password fields and login button', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: LoginScreen(),
    ));
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });

  testWidgets('shows error if email is invalid when login is pressed', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(),
    ));
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'invalid-email');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();
    expect(find.text('Please enter a valid email'), findsOneWidget);
  });

  testWidgets('shows error if password is empty or too short when login is pressed', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(),
    ));
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), '');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();
    expect(find.text('Please enter a password'), findsOneWidget);

    // Test too short password
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), '12');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });

  testWidgets('Login button is disabled if form is invalid and shows loading when pressed', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(),
    ));
    // Initially invalid form, button should be enabled (legacy behavior), but we want to disable it
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'invalid-email');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), '');
    await tester.pump();
    final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Login'));
    expect(button.onPressed, isNull);

    // Enter valid form, button should be enabled
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
    await tester.pump();
    final button2 = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Login'));
    expect(button2.onPressed, isNotNull);

    // Tap login, should show loading indicator
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(seconds: 1)); // Wait for loading to finish
  });

  testWidgets('sets persistent login flag after successful login', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(),
    ));
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('logged_in'), isTrue);
  });

  testWidgets('shows HomeScreen if already logged in on app start', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'logged_in': true});
    await tester.pumpWidget(const MyAppForTest());
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('logs out and returns to LoginScreen, clearing persistent flag', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'logged_in': true});
    await tester.pumpWidget(const MyAppForLogoutTest());
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreenWithLogout), findsOneWidget);
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('logged_in'), isFalse);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}

class MyAppForTest extends StatefulWidget {
  const MyAppForTest({super.key});
  @override
  State<MyAppForTest> createState() => _MyAppForTestState();
}

class _MyAppForTestState extends State<MyAppForTest> {
  bool? _loggedIn;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedIn = prefs.getBool('logged_in') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedIn == null) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }
    return MaterialApp(
      home: _loggedIn! ? const HomeScreen() : const LoginScreen(),
    );
  }
}

class MyAppForLogoutTest extends StatefulWidget {
  const MyAppForLogoutTest({super.key});
  @override
  State<MyAppForLogoutTest> createState() => _MyAppForLogoutTestState();
}

class _MyAppForLogoutTestState extends State<MyAppForLogoutTest> {
  bool? _loggedIn;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedIn = prefs.getBool('logged_in') ?? false;
    });
  }

  void _onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_in', false);
    setState(() {
      _loggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedIn == null) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }
    return MaterialApp(
      home: _loggedIn!
          ? HomeScreenWithLogout(onLogout: _onLogout)
          : const LoginScreen(),
    );
  }
}

class HomeScreenWithLogout extends StatelessWidget {
  final VoidCallback onLogout;
  const HomeScreenWithLogout({super.key, required this.onLogout});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: onLogout,
          child: const Text('Logout'),
        ),
      ),
    );
  }
}
