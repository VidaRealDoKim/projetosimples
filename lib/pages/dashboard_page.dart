import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<dynamic> rooms = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    setState(() => loading = true);
    final response = await Supabase.instance.client.from('rooms').select();
    setState(() {
      rooms = response;
      loading = false;
    });
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Future<void> _reserveRoom(String roomId) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    await Supabase.instance.client.from('reservations').insert({
      'room_id': roomId,
      'user_id': userId,
      'start_time': DateTime.now().toIso8601String(),
      'end_time': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reserva feita com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          return ListTile(
            title: Text(room['name']),
            subtitle: Text('Capacidade: ${room['capacity']}'),
            trailing: ElevatedButton(
              onPressed: () => _reserveRoom(room['id']),
              child: const Text('Reservar'),
            ),
          );
        },
      ),
    );
  }
}
