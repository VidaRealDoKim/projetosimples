import 'package:flutter/material.dart';
import 'package:projetosimples/pages/new_reservation_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://chbmftaqqllkozngwhrk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNoYm1mdGFxcWxsa296bmd3aHJrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUwMjI5MjMsImV4cCI6MjA3MDU5ODkyM30.m83vyKqGww_ZwV7Ts0XJbJ_lax5YmA1cG94_s9TPMCU',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Room',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const RootPage(),
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/new_reservation': (context) {
          final String? roomId = ModalRoute.of(context)?.settings.arguments as String?;
          return NewReservationPage(preSelectedRoomId: roomId);
        },
        // Adicione as outras rotas aqui (ex: /register, /rooms, etc)
      },
    );
  }
}

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      return const DashboardPage();
    } else {
      return const LoginPage();
    }
  }
}
