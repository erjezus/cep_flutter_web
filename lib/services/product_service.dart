import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cep_flutter_web/config/config.dart';

/// Servicio para operaciones con productos contra la API.
///
/// Mantiene la lógica HTTP fuera de las pantallas, de forma coherente
/// con el resto de llamadas de la app (`AppConfig.baseUrl`).
class ProductService {
  ProductService._();

  static final String _baseUrl = AppConfig.baseUrl;

  /// Crea un nuevo producto y lo asocia a un evento con un precio
  /// personalizado.
  ///
  /// POST `{baseUrl}/api/products`
  ///
  /// Devuelve un mapa con:
  /// `product_id`, `name`, `typology`, `unit_price`, `event_id`, `custom_price`.
  ///
  /// Lanza [Exception] con un mensaje descriptivo si la operación falla.
  static Future<Map<String, dynamic>> createProductWithEventPrice({
    required String name,
    required String typology,
    required double unitPrice,
    required int eventId,
    required double customPrice,
    String imageUrl = '',
  }) async {
    final uri = Uri.parse('$_baseUrl/api/products');

    final body = jsonEncode({
      'name': name,
      'typology': typology,
      'unit_price': unitPrice,
      'image_url': imageUrl,
      'event_id': eventId,
      'custom_price': customPrice,
    });

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw Exception('No se pudo conectar con el servidor: $e');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } catch (_) {
        // El backend respondió OK pero sin cuerpo JSON válido; devolvemos
        // los datos enviados como confirmación.
        return {
          'name': name,
          'typology': typology,
          'unit_price': unitPrice,
          'event_id': eventId,
          'custom_price': customPrice,
        };
      }
    }

    // Errores con mensaje descriptivo según el código.
    final serverMessage = utf8.decode(response.bodyBytes).trim();
    if (response.statusCode == 400) {
      throw Exception(serverMessage.isNotEmpty
          ? serverMessage
          : 'Datos inválidos al crear el producto.');
    }
    throw Exception(
      'Error al crear el producto (código ${response.statusCode})'
      '${serverMessage.isNotEmpty ? ': $serverMessage' : ''}',
    );
  }
}

