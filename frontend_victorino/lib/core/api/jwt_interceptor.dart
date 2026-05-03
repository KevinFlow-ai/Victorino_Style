// Interceptor que añade el header "Authorization: Bearer <access>" a
// cada
// petición saliente. El access token se mantiene en memoria (no en disco) y se
// actualiza desde el SesionNotifier tras login, registro o refresh.
import 'package:dio/dio.dart';

class JwtInterceptor extends Interceptor {
  JwtInterceptor(this._proveedorToken);

  // Función que devuelve el access token actual o null si no hay sesión.
  // Se inyecta como callback para evitar dependencias circulares con Riverpod.
  final String? Function() _proveedorToken;

  // Rutas públicas que NO deben llevar Authorization (las salta este interceptor).
  static const _rutasPublicas = {
    '/auth/registro',
    '/auth/login',
    '/auth/refresh',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Si la petición es a una ruta de auth pública, NO añadir el header.
    final esPublica = _rutasPublicas.any((ruta) => options.path.endsWith(ruta));
    if (esPublica) {
      handler.next(options);
      return;
    }

    final token = _proveedorToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
