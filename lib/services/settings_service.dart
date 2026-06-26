import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cep_flutter_web/config/config.dart';

/// Excepción específica de las operaciones de configuración.
class SettingsException implements Exception {
  final String message;
  final int? statusCode;

  SettingsException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Servicio para la gestión de parámetros globales (solo ADMIN).
class SettingsService {
  final String _baseUrl;
  final int adminUserId;
  final String adminUserRole;

  SettingsService({
    required this.adminUserId,
    required this.adminUserRole,
  }) : _baseUrl = AppConfig.baseUrl;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-User-ID': adminUserId.toString(),
        'X-User-Role': adminUserRole,
      };

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Never _fail(http.Response res, String fallback) {
    final body = utf8.decode(res.bodyBytes).trim();
    throw SettingsException(
      body.isNotEmpty ? body : fallback,
      statusCode: res.statusCode,
    );
  }

  Future<http.Response> _safe(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 15));
    } on SettingsException {
      rethrow;
    } catch (e) {
      throw SettingsException('No se pudo conectar con el servidor: $e');
    }
  }

  /// GET /api/settings — devuelve la configuración actual.
  Future<Map<String, dynamic>> getSettings() async {
    final res = await _safe(
      () => http.get(_uri('/api/settings'), headers: _headers),
    );
    if (res.statusCode != 200) {
      _fail(res, 'Error al obtener la configuración (${res.statusCode})');
    }
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    // El backend puede devolver una lista [{key, value}, ...] o un objeto {key: value}.
    if (decoded is List) {
      return {
        for (final item in decoded)
          (item['key'] as String): item['value'],
      };
    }
    return decoded as Map<String, dynamic>;
  }

  /// PUT /api/settings/apply_deposit — activa o desactiva el modo "A cuenta".
  Future<void> setApplyDeposit({required bool enabled}) async {
    final res = await _safe(
      () => http.put(
        _uri('/api/settings/apply_deposit'),
        headers: _headers,
        body: jsonEncode({'value': enabled.toString()}),
      ),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      _fail(res, 'Error al actualizar la configuración (${res.statusCode})');
    }
  }
}
