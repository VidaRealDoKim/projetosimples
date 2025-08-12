// lib/pages/dashboard_page.dart
import 'package:flutter/material.dart';
// Importe seu SupabaseService
import 'package:projetosimples/services/supabase_service.dart'; // AJUSTE O CAMINHO
// Importe sua página de login (ou a rota)
// import 'package:seu_projeto/pages/login_page.dart';
// import 'package:seu_projeto/routes.dart'; // Se usar rotas nomeadas

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Instancie seu serviço. Idealmente, injetado via Provider.
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _reservations = []; // Tipado corretamente
  bool _isLoading = true;
  String _userName = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final currentUser = _supabaseService.getCurrentUser();
    if (currentUser == null) {
      // Se não houver usuário, não há o que carregar, redireciona para login
      // Isso pode ser tratado por um AuthGate/AuthWidget no nível do MaterialApp
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login'); // Ou sua rota de login
      }
      return;
    }

    try {
      // Carrega nome do usuário e reservas em paralelo
      final profileDataFuture = _supabaseService.getProfile(currentUser.id);
      final reservationsFuture = _supabaseService.getReservations(currentUser.id);

      final results = await Future.wait([profileDataFuture, reservationsFuture]);

      final profileData = results[0] as Map<String, dynamic>?;
      final reservationsData = results[1] as List<Map<String, dynamic>>;

      if (!mounted) return;

      setState(() {
        if (profileData != null && profileData['name'] != null) {
          _userName = profileData['name'] as String;
        } else {
          _userName = currentUser.email ?? 'Usuário'; // Fallback para email
        }
        _reservations = reservationsData;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
        _userName = currentUser.email ?? 'Usuário'; // Fallback em caso de erro no perfil
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context); // Para navegação
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _supabaseService.signOut();
      if (!mounted) return;
      // Navega para a tela de login. Idealmente, isso é gerenciado por um listener de auth state.
      navigator.pushReplacementNamed('/login'); // Ou sua rota de login
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${_userName.isEmpty ? 'Usuário' : _userName.split(" ").first}!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _loadInitialData,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Perfil',
            onPressed: () {
              // Navigator.pushNamed(context, '/profile'); // Se tiver página de perfil
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Nova Reserva',
        onPressed: () async {
          // Navega para a página de nova reserva e atualiza a lista ao retornar
          final result = await Navigator.pushNamed(context, '/new_reservation');
          if (result == true && mounted) { // Se a reserva foi criada com sucesso
            _loadInitialData(); // Recarrega as reservas
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Reservar"),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _reservations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Erro ao carregar dados', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _loadInitialData, child: const Text('Tentar Novamente')),
            ],
          ),
        ),
      );
    }

    if (_reservations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Nenhuma reserva encontrada', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Você ainda não fez nenhuma reserva.'),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
        onRefresh: _loadInitialData,
        child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
    itemCount: _reservations.length,
    itemBuilder: (context, index) {
    final resv = _reservations[index];
    // Acessa 'rooms' que é um Map aninhado (se o select incluiu 'rooms(name)')
    final roomData = resv['rooms'] as Map<String, dynamic>?;
    final roomName = roomData?['name'] as String? ?? 'Sala Desconhecida';

    // Converte as strings para DateTime
    // Certifique-se que 'start_time' e 'end_time' são strings ISO 8601 válidas
    final DateTime startTime = DateTime.parse(resv['start_time'] as String);
    final DateTime endTime = DateTime.parse(resv['end_time'] as String);

    String formatTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    String formatDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

    return Card(
    margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
    child: ListTile(
    leading: CircleAvatar(
    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
    child: Icon(Icons.meeting_room_outlined, color: Theme.of(context).primaryColor),
    ),
    title: Text(roomName, style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text(
    '${formatDate(startTime)}\nDas ${formatTime(startTime)} às ${formatTime(endTime)}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Poderia navegar para uma página de detalhes da reserva
        // Navigator.pushNamed(context, '/reservation_details', arguments: resv['id']);
      },
    ),
    );
    },
        ),
    );
  }
}