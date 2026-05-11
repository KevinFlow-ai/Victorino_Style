// SesionNotifier: estado global de la sesión de usuario.
//
// Estados representados con AsyncValue<SesionUsuario?>:
// - AsyncData(null)           → sesión cerrada (pantalla login).
// - AsyncData(SesionUsuario)  → sesión activa.
// - AsyncLoading              → restaurando sesión al arranque o cerrando.
// - AsyncError                → fallo al restaurar (refresh inválido).
//
// La pantalla de login NO modifica este estado directamente; pasa por iniciarSesion()
// que actualiza la sesión Y persiste el refresh en disco.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/secure_storage.dart';
import '../modelos/sesion_usuario.dart';
import 'secure_storage_provider.dart';


import 'package:flutter/foundation.dart';
import '../../features/login_admin_empleado_cliente/data/repositorios/auth_repositorio_impl.dart';
import 'dio_provider.dart';


class SesionNotifier extends AsyncNotifier<SesionUsuario?> {
  late final SecureStorage _storage;

  @override
  Future<SesionUsuario?> build() async {
    _storage = ref.read(secureStorageProvider);
    // Al arrancar, no hay sesión en memoria. La restauración (refresh)
    // la dispara explícitamente el splash llamando a intentarRestaurar().
    return null;
  }

  // ---------------------------------------------------------------------------
  // Establece la sesión tras un login/registro exitoso y persiste lo necesario.
  // ---------------------------------------------------------------------------
  Future<void> establecerSesion(SesionUsuario sesion, String refreshToken, {bool esLoginExplicito = false}) async {
    await _storage.guardarSesion(
      refreshToken: refreshToken,
      idUsuario: sesion.idUsuario,
      rol: sesion.rol,
    );
    // Guardamos refresh token, id y rol en almacenamiento seguro.

    state = AsyncData(sesion);
    // Guardamos la sesión completa en memoria (access token incluido).
  }

// ---------------------------------------------------------------------------
  // Actualiza solo el access token (lo invoca RefreshInterceptor tras renovar).
  // ---------------------------------------------------------------------------
  void actualizarAccessToken(String? nuevoAccessToken) {
    final actual = state.value;
    if (actual == null || nuevoAccessToken == null) return;

    state = AsyncData(actual.copyWith(accessToken: nuevoAccessToken));
    // Reemplaza solo el access token, manteniendo el resto igual.
  }

  // ---------------------------------------------------------------------------
  // Cierra la sesión: avisa al backend (para que borre tokens FCM y revoque
  // el refresh token), borra disco y deja state en null.
  // El aviso al backend es best-effort: si falla (sin red, token ya revocado,
  // etc.) se cierra igualmente la sesión local. Sin la llamada al backend los
  // tokens FCM quedarían en BD y las notificaciones creadas mientras la sesión
  // está cerrada se marcarían 'enviada_push=true', rompiendo el catch-up push.
  // ---------------------------------------------------------------------------
  Future<void> cerrarSesion() async {
    state = const AsyncLoading();
    // Indicamos que estamos cerrando sesión.
    // 1) Leer el refresh token ANTES de borrar el storage.
    final refreshToken = await _storage.leerRefreshToken();

    // 2) Limpiar almacenamiento local (refresh, id, rol).
    await _storage.limpiarSesion();

    // 3) Avisar al backend: revoca el refresh token Y borra los tokens FCM.
    //    Es best-effort: si falla, la sesión local ya está limpia.
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        final authRepo = AuthRepositorioImpl(dio: ref.read(dioBaseProvider));
        await authRepo.cerrarSesion(refreshToken);
        debugPrint('[Sesion] Logout confirmado en backend (tokens FCM borrados)');
      } catch (e) {
        debugPrint('[Sesion] Logout backend falló (ignorado): $e');
      }
    }

    // Borramos refresh token, id y rol del almacenamiento seguro.

    state = const AsyncData(null);
    // Dejamos la sesión en memoria como null.
  }

  // Lectura síncrona del access token actual. La usa el JwtInterceptor.
  String? leerAccessActual() => state.value?.accessToken;
}

// Provider expuesto al resto de la app.
final sesionProvider = AsyncNotifierProvider<SesionNotifier, SesionUsuario?>(
  SesionNotifier.new,
);

/*
RESUMEN DE ESTE ARCHIVO
 1. SesionNotifier
Un AsyncNotifier de Riverpod que mantiene el estado global de la sesión del usuario.

Su responsabilidad es:
• Guardar la sesión en memoria (access token, id, rol…)
• Persistir datos sensibles en SecureStorage (refresh token, id, rol)
• Actualizar el access token cuando el RefreshInterceptor lo renueva
• Cerrar sesión limpiando almacenamiento y estado
• Proveer el access token actual a los interceptores

 Es el centro de autenticación en memoria de toda la app.

 2. sesionProvider
Un AsyncNotifierProvider que expone el SesionNotifier al resto de la app.
La UI, los interceptores y los casos de uso pueden leer:

• La sesión actual
• El access token
• El rol del usuario
• Si hay sesión o no

Relación: SplashScreen → SesionNotifier → SecureStorage → Dio Interceptors → Repositorios → Casos de uso → UI

 */