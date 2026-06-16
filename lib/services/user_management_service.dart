import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/models/user.dart';

/// Excepción específica de las operaciones de gestión de usuarios.
class UserManagementException implements Exception {
  final String message;
  final int? statusCode;

  UserManagementException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Servicio para la administración de usuarios (solo ADMIN).
///
/// Todas las peticiones incluyen las cabeceras de identidad
/// `X-User-ID` y `X-User-Role` del administrador que realiza la acción.
class UserManagementService {
  final String _baseUrl;
  final int adminUserId;
  final String adminUserRole;

  UserManagementService({
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
    throw UserManagementException(
      body.isNotEmpty ? body : fallback,
      statusCode: res.statusCode,
    );
  }

  Future<http.Response> _safe(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 15));
    } on UserManagementException {
      rethrow;
    } catch (e) {
      throw UserManagementException('No se pudo conectar con el servidor: $e');
    }
  }

  /// GET /api/admin/users
  Future<List<User>> listUsers() async {
    final res = await _safe(
      () => http.get(_uri('/api/admin/users'), headers: _headers),
    );
    if (res.statusCode != 200) {
      _fail(res, 'Error al listar usuarios (${res.statusCode})');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final list = data is List ? data : (data['users'] as List? ?? []);
    return list
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/admin/users/{id}
  Future<User> getUserById(int id) async {
    final res = await _safe(
      () => http.get(_uri('/api/admin/users/$id'), headers: _headers),
    );
    if (res.statusCode != 200) {
      _fail(res, 'Error al obtener el usuario (${res.statusCode})');
    }
    return User.fromJson(
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
  }

  /// POST /api/admin/users — crea un usuario.
  ///
  /// El backend documentado expone la gestión bajo /api/admin/users;
  /// para crear se envía username, email, password y role.
  Future<Map<String, dynamic>> createUser({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    final res = await _safe(() => http.post(
          _uri('/api/admin/users'),
          headers: _headers,
          body: jsonEncode({
            'username': username,
            'email': email,
            'password': password,
            'role': role,
          }),
        ));
    if (res.statusCode != 200 && res.statusCode != 201) {
      _fail(res, 'Error al crear el usuario (${res.statusCode})');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  /// PUT /api/admin/users/{id}
  ///
  /// Actualiza username, email y role. Si [password] no es nulo ni vacío,
  /// también se envía para cambiarla.
  Future<Map<String, dynamic>> updateUser(
    int id, {
    required String username,
    required String email,
    required String role,
    String? password,
  }) async {
    final body = <String, dynamic>{
      'username': username,
      'email': email,
      'role': role,
    };
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }

    final res = await _safe(() => http.put(
          _uri('/api/admin/users/$id'),
          headers: _headers,
          body: jsonEncode(body),
        ));
    if (res.statusCode != 200) {
      _fail(res, 'Error al actualizar el usuario (${res.statusCode})');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  /// PUT /api/admin/users/{id}/role
  Future<Map<String, dynamic>> changeUserRole(int id, String newRole) async {
    final res = await _safe(() => http.put(
          _uri('/api/admin/users/$id/role'),
          headers: _headers,
          body: jsonEncode({'role': newRole}),
        ));
    if (res.statusCode != 200) {
      _fail(res, 'Error al cambiar el rol (${res.statusCode})');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  /// DELETE /api/admin/users/{id}
  Future<void> deleteUser(int id) async {
    final res = await _safe(
      () => http.delete(_uri('/api/admin/users/$id'), headers: _headers),
    );
    if (res.statusCode != 204 && res.statusCode != 200) {
      _fail(res, 'Error al eliminar el usuario (${res.statusCode})');
    }
  }
}

