import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';

String getApiBaseUrl() {
  if (kIsWeb) {
    // Para Flutter Web usa la IP local
    return 'http://192.168.1.123:8080'; // <-- Cambia esto por tu IP real
  } else if (Platform.isAndroid) {
    // Para emulador Android
    return 'http://10.0.2.2:8080';
  } else {
    // Para iOS o Flutter Desktop
    return 'http://localhost:8080';
  }
}
