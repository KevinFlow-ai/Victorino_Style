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


// notificaciones
import 'package:flutter/foundation.dart';
import '../../core/notifications/fcm_service.dart';
import '../../core/notifications/local_notifications.dart';
import '../../features/notificaciones/application/notificaciones_providers.dart';
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
  // [esLoginExplicito] = true  → el usuario escribió credenciales: se enviará notificación de bienvenida.
  // [esLoginExplicito] = false → restauración de sesión desde el splash: sin notificación.
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
    try {
      final token = await FcmService.obtenerToken();
      if (token != null) {
        await ref.read(registrarDeviceTokenProvider).ejecutar(
          sesion.idUsuario,
          token,
          esLoginExplicito: esLoginExplicito,
        );
        debugPrint('[FCM] Token registrado en backend correctamente (esLoginExplicito=$esLoginExplicito)');

        // Si es login explícito, mostramos la notificación local DIRECTAMENTE
        // sin esperar el roundtrip Firebase → dispositivo.
        // Esto evita el throttling de mensajes HIGH priority en logins rápidos consecutivos.
        if (esLoginExplicito) {
          await LocalNotificationsService.mostrarLocal(
            'Sesión iniciada',
            'Has iniciado sesión en Victorino Style. Bienvenido/a.',
          );
          // Refrescar la bandeja in-app (el backend ya guardó la notificación en BD).
          FcmService.onMensajeEntrante?.call();
          debugPrint('[FCM] Notificación local de sesión mostrada directamente (sin roundtrip FCM)');
        }
      } else {
        debugPrint('[FCM] Token null – sin push para este dispositivo');
      }
    } catch (e) {
      debugPrint('[FCM] No se pudo registrar token: $e');
    }
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
  // Cierra la sesión: avisa al backend (borra tokens FCM y revoca el refresh
  // token), borra disco y deja state en null.
  // El aviso al backend es best-effort: si falla, la sesión local se cierra igualmente.  // ---------------------------------------------------------------------------
  Future<void> cerrarSesion() async {
    state = const AsyncLoading();
    // Indicamos que estamos cerrando sesión.

    // 1) Leer el refresh token ANTES de borrar el storage.
    final refreshToken = await _storage.leerRefreshToken();

    // 2) Limpiar almacenamiento local.

    await _storage.limpiarSesion();
    // Borramos refresh token, id y rol del almacenamiento seguro.

    // 3) Avisar al backend: revoca el refresh token Y borra los tokens FCM.
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        final authRepo = AuthRepositorioImpl(dio: ref.read(dioBaseProvider));
        await authRepo.cerrarSesion(refreshToken);
        debugPrint('[Sesion] Logout confirmado en backend (tokens FCM borrados)');
      } catch (e) {
        debugPrint('[Sesion] Logout backend falló (ignorado): $e');
      }
    }

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