import 'package:flutter/material.dart';
import 'src/screens/home/home_screen.dart';
import 'src/screens/login/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'src/providers/task_provider.dart';
import 'src/app.dart';
import 'src/providers/theme_provider.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/chat_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

void main() {
  // 初始化timeago的中文支持
  timeago.setLocaleMessages('zh', timeago.ZhMessages());
  timeago.setDefaultLocale('zh');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const GoalAchieverApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _loggedIn;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedIn = prefs.getBool('logged_in') ?? false;
      _userId = prefs.getInt('user_id');
    });
  }

  Future<void> _onLogin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedIn = true;
      _userId = prefs.getInt('user_id');
    });
  }

  Future<void> _onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_in', false);
    await prefs.remove('user_id');
    setState(() {
      _loggedIn = false;
      _userId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedIn == null) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    if (_loggedIn! && _userId != null) {
      return ChangeNotifierProvider(
        create: (_) => TaskProvider(userId: _userId!)..fetchTasks(),
        child: MaterialApp(
          title: 'GoalAchiever',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF3F51B5),
              foregroundColor: Colors.white,
              elevation: 2,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: Colors.white),
              systemOverlayStyle: SystemUiOverlayStyle.light,
              surfaceTintColor: Color(0xFF3F51B5),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF3F51B5),
              selectedItemColor: Colors.white,
              unselectedItemColor: Color(0xFFB0BEC5),
              selectedIconTheme: IconThemeData(color: Colors.white),
              unselectedIconTheme: IconThemeData(color: Color(0xFFB0BEC5)),
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
            ),
            useMaterial3: false,
          ),
          home: HomeScreen(onLogout: _onLogout),
        ),
      );
    }
    return MaterialApp(
      title: 'GoalAchiever',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3F51B5),
          foregroundColor: Colors.white,
          elevation: 2,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          surfaceTintColor: Color(0xFF3F51B5),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF3F51B5),
          selectedItemColor: Colors.white,
          unselectedItemColor: Color(0xFFB0BEC5),
          selectedIconTheme: IconThemeData(color: Colors.white),
          unselectedIconTheme: IconThemeData(color: Color(0xFFB0BEC5)),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
        useMaterial3: false,
      ),
      home: LoginScreen(onLogin: _onLogin),
    );
  }
}

// The old MyHomePage code is no longer used.
