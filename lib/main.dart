import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';

Future<void> main() async {
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
      title: 'Reserva de Salas',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: Supabase.instance.client.auth.currentSession != null
          ? const DashboardPage()
          : const LoginPage(),
    );
  }
}
