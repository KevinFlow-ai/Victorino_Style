// Interceptor que detecta respuestas 401 y, si tenemos refresh token, intenta
// renovar el access llamando a /auth/refresh y reintenta la petición original.
//
// Bloqueo: si llegan varias peticiones a la vez con 401, solo la primera dispara
// el refresh; las demás esperan al mismo Future con un Completer.
import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

// Tipo de callback que actualiza el access en memoria tras un refresh exitoso.
typedef ActualizadorAccessToken = void Function(String? nuevoAccessToken);

// Tipo de callback que cierra la sesión cuando el refresh falla definitivamente.
typedef CerradorSesion = Future<void> Function();

class RefreshInterceptor extends Interceptor {
  RefreshInterceptor({
    required Dio dioReintentos,
    required SecureStorage secureStorage,
    required ActualizadorAccessToken actualizar,
    required CerradorSesion cerrarSesion,
  })  : _dioReintentos = dioReintentos,
        _secureStorage = secureStorage,
        _actualizar = actualizar,
        _cerrarSesion = cerrarSesion;

  // Dio independiente para llamar a /auth/refresh y para reintentar la petición
  // original sin volver a entrar en este interceptor (evita recursión).
  final Dio _dioReintentos;
  final SecureStorage _secureStorage;
  final ActualizadorAccessToken _actualizar;
  final CerradorSesion _cerrarSesion;

  // Completer único en curso. Si vale null, no hay refresh activo.
  Completer<String?>? _refreshEnCurso;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final esCodigo401 = err.response?.statusCode == 401;
    final esLlamadaAuth = err.requestOptions.path.contains('/auth/');
    // Marca para no entrar dos veces en este interceptor con la misma petición.
    final yaReintentado = err.requestOptions.extra['_reintentado'] == true;

    if (!esCodigo401 || esLlamadaAuth || yaReintentado) {
      handler.next(err);
      return;
    }

    final refresh = await _secureStorage.leerRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      // No hay con qué renovar: cerramos sesión y propagamos el error.
      await _cerrarSesion();
      handler.next(err);
      return;
    }

    try {
      // Si ya hay un refresh en curso, esperamos a su resultado.
      final nuevoAccess = await _obtenerNuevoAccess(refresh);
      if (nuevoAccess == null) {
        await _cerrarSesion();
        handler.next(err);
        return;
      }

      // Reintenta la petición original con el nuevo token.
      final opciones = err.requestOptions;
      opciones.headers['Authorization'] = 'Bearer $nuevoAccess';
      opciones.extra['_reintentado'] = true;

      final respuesta = await _dioReintentos.fetch<dynamic>(opciones);
      handler.resolve(respuesta);
    } catch (_) {
      // Si el refresh o el reintento fallan, cerramos sesión.
      await _cerrarSesion();
      handler.next(err);
    }
  }

  // Coordina el refresh: solo una llamada simultánea, las demás esperan.
  Future<String?> _obtenerNuevoAccess(String refreshToken) {
    if (_refreshEnCurso != null) {
      return _refreshEnCurso!.future;
    }

    final completer = Completer<String?>();
    _refreshEnCurso = completer;

    () async {
      try {
        final resp = await _dioReintentos.post<Map<String, dynamic>>(
          ApiEndpoints.authRefresh,
          data: {'refreshToken': refreshToken},
        );
        final nuevoAccess = resp.data?['accessToken'] as String?;
        _actualizar(nuevoAccess);
        completer.complete(nuevoAccess);
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        _refreshEnCurso = null;
      }
    }();

    return completer.future;
  }
}
