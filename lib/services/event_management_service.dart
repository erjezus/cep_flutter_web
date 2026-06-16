import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cep_flutter_web/config/config.dart';

/// Excepción específica para errores de gestión de eventos.
class EventManagementException implements Exception {
  final String message;
  EventManagementException(this.message);
  @override
  String toString() => message;
}

/// Servicio para las operaciones CRUD de eventos (solo admin).
class EventManagementService {
  final String baseUrl;

  EventManagementService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.baseUrl;

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  /// Lista todos los eventos.
  Future<List<Map<String, dynamic>>> listEvents() async {
    final res = await http.get(Uri.parse('$baseUrl/api/events'));
    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    }
    throw EventManagementException('Error al cargar eventos (${res.statusCode})');
  }

  /// Crea un nuevo evento.
  Future<void> createEvent({
    required String name,
    required String status,
  }) async {
    final body = <String, dynamic>{'name': name, 'status': status};

    final res = await http.post(
      Uri.parse('$baseUrl/api/events'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw EventManagementException('Error al crear el evento (${res.statusCode})');
    }
  }

  /// Actualiza un evento existente.
  Future<void> updateEvent({
    required int id,
    required String name,
    required String status,
  }) async {
    final body = <String, dynamic>{'id': id, 'name': name, 'status': status};

    final res = await http.put(
      Uri.parse('$baseUrl/api/events/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw EventManagementException('Error al actualizar el evento (${res.statusCode})');
    }
  }

  /// Elimina un evento.
  Future<void> deleteEvent(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/events/$id'));
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw EventManagementException('Error al eliminar el evento (${res.statusCode})');
    }
  }
}

