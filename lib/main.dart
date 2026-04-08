import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'admin/admin_panel_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_nav_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.instance.init();
  runApp(const CashyProApp());
}

class CashyProApp extends StatelessWidget {
  const CashyProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CashyPro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B5BFF), brightness: Brightness.light),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0, surfaceTintColor: Colors.transparent),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<AppAuthState>(
        stream: AuthService.instance.authState,
        builder: (context, snapshot) {
          final state = snapshot.data;
          if (state == null || !state.loggedIn) {
            return const AuthScreen();
          }
          if (state.role == 'admin') {
            return const AdminPanelScreen();
          }
          return const MainNavScreen();
        },
      ),
    );
  }
}
