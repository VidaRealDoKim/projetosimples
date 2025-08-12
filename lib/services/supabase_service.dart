// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client; // Mantenha privado

  // Auth
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      // Re-throw para ser tratado na UI ou logar
      // print('SupabaseService signIn Error: $e');
      throw Exception('Falha no login: ${e is AuthException ? e.message : e.toString()}');
    }
  }

  Future<AuthResponse> signUp(String email, String password, {Map<String, dynamic>? userData}) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: userData, // Corrigido: usa o parâmetro 'data'
      );
      return response;
    } catch (e) {
      // print('SupabaseService signUp Error: $e');
      throw Exception('Falha no cadastro: ${e is AuthException ? e.message : e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      // print('SupabaseService signOut Error: $e');
      throw Exception('Falha ao sair: ${e is AuthException ? e.message : e.toString()}');
    }
  }

  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Profiles
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      // .select() sem tipo genérico retorna List<dynamic> por padrão,
      // mas com .single() ele tentará retornar o primeiro Map<String, dynamic> ou lançar erro se não for único.
      // Usar .maybeSingle() é mais seguro se o perfil puder não existir.
      final response = await _client
          .from('profiles')
          .select('name') // Adicione outros campos do perfil se necessário
          .eq('id', userId)
          .maybeSingle(); // Retorna Map<String, dynamic>?

      // O resultado de maybeSingle já é o Map ou null, não um PostgrestResponse com data e error.
      return response;
    } catch (e) {
      // print('SupabaseService getProfile Error: $e');
      throw Exception('Falha ao buscar perfil: $e');
    }
  }

  // Reservations
  Future<List<Map<String, dynamic>>> getReservations(String userId) async {
    try {
      final response = await _client
          .from('reservations')
          .select('id, start_time, end_time, room_id, rooms(id, name, capacity)') // Especifique campos da sala
          .eq('user_id', userId)
          .order('start_time', ascending: true);
      // .select() sem .single() ou .maybeSingle() retorna List<Map<String, dynamic>> diretamente
      return response;
    } catch (e) {
      // print('SupabaseService getReservations Error: $e');
      throw Exception('Falha ao buscar reservas: $e');
    }
  }

  Future<void> createReservation({
    required String userId,
    required String roomId,
    required DateTime startTime,
    required DateTime endTime,
    int? participants, // Tornar opcional se a coluna permitir null
  }) async {
    try {
      await _client.from('reservations').insert({
        'user_id': userId,
        'room_id': roomId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        if (participants != null) 'participants': participants, // Insere apenas se não for nulo
        // 'created_at' geralmente é definido pelo banco com default now()
      });
      // .insert() não retorna dados por padrão, a menos que você use .select() após ele.
      // Se não houver erro, a operação foi bem-sucedida.
    } catch (e) {
      // print('SupabaseService createReservation Error: $e');
      throw Exception('Falha ao criar reserva: $e');
    }
  }

  // Verificar conflitos de reserva
  // Retorna true se houver conflito, false caso contrário.
  Future<bool> checkReservationConflict({
    required String roomId,
    required DateTime newStartTime,
    required DateTime newEndTime,
    String? excludeReservationId, // Para permitir atualização de uma reserva existente
  }) async {
    try {
      // Queremos encontrar reservas para a mesma sala que:
      // 1. Começam ANTES do newEndTime E terminam DEPOIS do newStartTime
      var query = _client
          .from('reservations')
          .select('id') // Só precisamos saber se existe alguma
          .eq('room_id', roomId)
          .lt('start_time', newEndTime.toIso8601String()) // Começa antes do fim do novo período
          .gt('end_time', newStartTime.toIso8601String()); // Termina depois do início do novo período

      if (excludeReservationId != null) {
        query = query.not('id', 'eq', excludeReservationId); // Exclui a própria reserva ao editar
      }

      final response = await query;

      return response.isNotEmpty; // Se a lista não estiver vazia, há conflito
    } catch (e) {
      // print('SupabaseService checkReservationConflict Error: $e');
      throw Exception('Falha ao verificar conflito: $e');
    }
  }


  // Rooms
  Future<List<Map<String, dynamic>>> getRooms() async {
    try {
      final response = await _client
          .from('rooms')
          .select('id, name, capacity'); // Especifique os campos que você precisa
      return response;
    } catch (e) {
      // print('SupabaseService getRooms Error: $e');
      throw Exception('Falha ao buscar salas: $e');
    }
  }
}