// lib/pages/new_reservation_page.dart
import 'package:flutter/material.dart';

// Importe seu SupabaseService
import 'package:projetosimples/services/supabase_service.dart'; //

class NewReservationPage extends StatefulWidget {
  final String? preSelectedRoomId;

  const NewReservationPage({super.key, this.preSelectedRoomId});

  @override
  State<NewReservationPage> createState() => _NewReservationPageState();
}

class _NewReservationPageState extends State<NewReservationPage> {
  final _formKey = GlobalKey<FormState>();
  // Instancie seu serviço. Idealmente, injetado via Provider.
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _rooms = [];
  String? _selectedRoomId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _participantsController = TextEditingController();

  bool _isLoadingRooms = true;
  bool _isReserving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRooms();
    if (widget.preSelectedRoomId != null) {
      _selectedRoomId = widget.preSelectedRoomId;
    }
    // Define uma data inicial que não seja no passado para o DatePicker
    if (_selectedDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      _selectedDate = DateTime.now();
    }
  }

  Future<void> _fetchRooms() async {
    setState(() {
      _isLoadingRooms = true;
      _errorMessage = null;
    });
    try {
      final roomsData = await _supabaseService.getRooms();
      if (!mounted) return;
      setState(() {
        _rooms = roomsData;
        // Se um quarto pré-selecionado foi passado e não existe na lista, limpa a seleção
        if (widget.preSelectedRoomId != null && !_rooms.any((room) => room['id'] == widget.preSelectedRoomId)) {
          _selectedRoomId = null;
        }
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
        setState(() => _isLoadingRooms = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(), // Não permite selecionar datas passadas
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && date != _selectedDate) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickStartTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _startTime = time);
    }
  }

  Future<void> _pickEndTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: _endTime ?? (_startTime != null ? TimeOfDay(hour: _startTime!.hour + 1, minute: _startTime!.minute) : TimeOfDay.now()),
    );
    if (time != null) {
      setState(() => _endTime = time);
    }
  }

  Future<void> _reserve() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_selectedRoomId == null || _startTime == null || _endTime == null) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Por favor, preencha todos os campos de data, hora e sala.')));
      return;
    }

    final DateTime startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final DateTime endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('O horário final deve ser após o horário inicial.')));
      return;
    }

    setState(() => _isReserving = true);

    try {
      final hasConflict = await _supabaseService.checkReservationConflict(
        roomId: _selectedRoomId!,
        newStartTime: startDateTime,
        newEndTime: endDateTime,
      );

      if (!mounted) return;

      if (hasConflict) {
        scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Conflito de horário detectado para esta sala e período.')));
        setState(() => _isReserving = false);
        return;
      }

      final userId = _supabaseService.getCurrentUser()?.id;
      if (userId == null) {
        scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Usuário não autenticado. Faça login novamente.')));
        setState(() => _isReserving = false);
        // Idealmente, redirecionar para login
        return;
      }

      final int? participants = int.tryParse(_participantsController.text);

      await _supabaseService.createReservation(
        userId: userId,
        roomId: _selectedRoomId!,
        startTime: startDateTime,
        endTime: endDateTime,
        participants: participants,
      );

      if (!mounted) return;

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Reserva criada com sucesso!')),
      );
      // Retorna true para a página anterior saber que deve atualizar a lista
      navigator.pop(true);

      // Se você tivesse uma página de confirmação:
      // navigator.pushReplacementNamed(
      //   context,
      //   '/confirmation', // Sua rota de confirmação
      //   arguments: {
      //     'roomName': _rooms.firstWhere((r) => r['id'] == _selectedRoomId!)['name'],
      //     'startTime': startDateTime,
      //     'endTime': endDateTime,
      //   },
      // );

    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (mounted) {
        setState(() => _isReserving = false);
      }
    }
  }

  @override
  void dispose() {
    _participantsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String formatTimeOfDay(TimeOfDay? tod) {
      if (tod == null) return 'Selecione';
      final hour = tod.hour.toString().padLeft(2, '0');
      final minute = tod.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    String formatDate(DateTime dt) =>
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

    return Scaffold(
        appBar: AppBar(
        title: const Text('Nova Reserva'),
    ),
    body: _isLoadingRooms
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null && _rooms.isEmpty
        ? Center(
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
    )
        : _rooms.isEmpty
        ? Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.meeting_room_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Nenhuma sala disponível', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Não há salas cadastradas no momento.'),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _fetchRooms, child: const Text('Atualizar Salas')),
          ],
        ),
      ),
    )
        : Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Selecione a Sala',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.meeting_room),
              ),
              items: _rooms.map((room) {
                final String roomName = room['name'] as String? ?? 'Sala Desconhecida';
                final int? capacity = room['capacity'] as int?;
                return DropdownMenuItem<String>(
                  value: room['id'] as String,
                  child: Text('$roomName${capacity != null ? " (Cap: $capacity)" : ""}'),
                );
              }).toList(),
              value: _selectedRoomId,
              onChanged: (value) => setState(() => _selectedRoomId = value),
              validator: (value) => value == null ? 'Selecione uma sala' : null,
              isExpanded: true,
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: Colors.teal),
              title: const Text('Data da Reserva'),
              subtitle: Text(formatDate(_selectedDate)),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _pickDate,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time, color: Colors.teal),
              title: const Text('Horário de Início'),
              subtitle: Text(formatTimeOfDay(_startTime)),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _pickStartTime,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time_filled, color: Colors.teal),
              title: const Text('Horário de Fim'),
              subtitle: Text(formatTimeOfDay(_endTime)),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _pickEndTime,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _participantsController,
              decoration: InputDecoration(
                labelText: 'Número de Participantes (Opcional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.people_outline),
              ),
              keyboardType: TextInputType.number,
              // Não é obrigatório, então não precisa de validator a menos que queira validar o formato
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isReserving ? null : _reserve,
              child: _isReserving
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              )
                  : const Text('Confirmar Reserva', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    ),
    );
  }
}