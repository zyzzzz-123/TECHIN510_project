import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/chat/chat_screen_v2.dart';

class GoalAchieverApp extends StatefulWidget {
  const GoalAchieverApp({super.key});

  @override
  State<GoalAchieverApp> createState() => _GoalAchieverAppState();
}

class _GoalAchieverAppState extends State<GoalAchieverApp> {
  @override
  void initState() {
    super.initState();
    // 初始化用户认证状态
    Future.microtask(() {
      Provider.of<AuthProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
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
                  systemOverlayStyle: SystemUiOverlayStyle.dark,
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
              darkTheme: ThemeData.dark(useMaterial3: false),
              themeMode: themeProvider.themeMode,
              home: authProvider.isLoading
                  ? const Scaffold(body: Center(child: CircularProgressIndicator()))
                  : (authProvider.isAuthenticated
                      ? const HomeScreen() // 移除了不存在的参数
                      : const LoginScreen()),
              // 定义页面路由
              routes: {
                '/chat': (context) => const ChatScreenV2(),
              },
            );
          },
        );
      },
    );
  }
} 