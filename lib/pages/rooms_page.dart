// lib/pages/rooms_page.dart
import 'package:flutter/material.dart';
// Importe seu SupabaseService
import 'package:projetosimples/services/supabase_service.dart'; // AJUSTE O CAMINHO
// Importe a página de nova reserva para passar argumentos tipados se desejar
// import 'package:projetosimples/pages/new_reservation_page.dart';

class RoomsPage extends StatefulWidget {
  const RoomsPage({super.key});

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  // Instancie seu serviço. Idealmente, injetado via Provider.
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _rooms = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final roomsData = await _supabaseService.getRooms();
      if (!mounted) return;
      setState(() {
        _rooms = roomsData;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
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

  void _reserveNow(String roomId, String roomName) {
    // Navega para a página de nova reserva, pré-selecionando a sala
    Navigator.pushNamed(
      context,
      '/new_reservation',
      arguments: roomId, // Passa diretamente o ID da sala.
      // NewReservationPage precisa ser ajustada para receber String?
      // ou um Map {'roomId': roomId, 'roomName': roomName}
    ).then((result) {
      // Se a reserva foi bem sucedida (NewReservationPage.pop(true)),
      // você pode querer atualizar algo aqui, embora a lista de salas não mude.
      // Mas se você tivesse uma indicação de "disponibilidade" na sala, poderia atualizar.
      if (result == true) {
        // Ex: Mostrar um SnackBar de sucesso ou atualizar a UI se necessário
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salas Disponíveis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _fetchRooms,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Erro ao carregar salas', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _fetchRooms, child: const Text('Tentar Novamente')),
            ],
          ),
        ),
      );
    }

    if (_rooms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.meeting_room_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Nenhuma sala encontrada', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Não há salas cadastradas no momento.'),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRooms,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _rooms.length,
        itemBuilder: (context, index) {
          final room = _rooms[index];
          final String roomId = room['id'] as String;
          final String roomName = room['name'] as String? ?? 'Sala Desconhecida';
          final int? capacity = room['capacity'] as int?;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Icon(Icons.meeting_room, color: Theme.of(context).primaryColor),
              ),
              title: Text(roomName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(capacity != null ? 'Capacidade: $capacity pessoas' : 'Capacidade não informada'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  // backgroundColor: Theme.of(context).colorScheme.secondary, // Exemplo de cor
                ),
                onPressed: () => _reserveNow(roomId, roomName),
                child: const Text('Reservar'),
              ),
              onTap: () => _reserveNow(roomId, roomName), // Permite clicar no item todo
            ),
          );
        },
      ),
    );
  }
}