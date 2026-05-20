// Provider del cliente Dio principal con los dos interceptores conectados.
//
// Diseño:
// - dioBaseProvider     → Dio sin interceptores (lo usa el RefreshInterceptor para
//                         llamar a /auth/refresh y para reintentar peticiones).
// - dioProvider         → Dio "público" para el resto de la app, con jwt + refresh.
//
// Esta separación evita recursión: si el refresh fallara, no se intenta refrescar
// otra vez sobre la misma petición.
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_url_provider.dart';
import '../../core/api/dio_cliente.dart';
import '../../core/api/jwt_interceptor.dart';
import '../../core/api/refresh_interceptor.dart';
import 'secure_storage_provider.dart';
import 'sesion_provider.dart';

// Dio "limpio" sin interceptores.
// Observa apiBaseUrlProvider: se recrea automáticamente si la URL cambia.
final dioBaseProvider = Provider<Dio>((ref) {
  final url = ref.watch(apiBaseUrlProvider);
  return DioCliente.crearConUrl(url);
});

// Dio principal con los interceptores aplicados. Lo usan los repositorios.
// También observa apiBaseUrlProvider para reaccionar a cambios de URL.
final dioProvider = Provider<Dio>((ref) {
  final url = ref.watch(apiBaseUrlProvider);
  final dio = DioCliente.crearConUrl(url);
  // Cliente Dio principal, base para todas las peticiones HTTP.

  final dioBase = ref.watch(dioBaseProvider);
  // Dio auxiliar sin interceptores, usado para reintentos de refresh.

  final secureStorage = ref.read(secureStorageProvider);
  // Acceso al almacenamiento seguro para leer/escribir tokens.

  // ---------------------------------------------------------------------------
  // 1) JwtInterceptor: añade el access token actual a cada petición.
  // Lee el token desde SesionNotifier.
  // ---------------------------------------------------------------------------
  dio.interceptors.add(JwtInterceptor(
        () => ref.read(sesionProvider.notifier).leerAccessActual(),
    // Función que devuelve el access token actual.
  ));
// ---------------------------------------------------------------------------


  // 2) RefreshInterceptor: si el backend devuelve 401, intenta renovar el token.
  // - Usa dioBase para hacer la petición de refresh.
  // - Guarda el nuevo access token en SesionNotifier.
  // - Si falla → cierra sesión.
  // ---------------------------------------------------------------------------
  dio.interceptors.add(RefreshInterceptor(
    dioReintentos: dioBase,           // Dio sin interceptores para reintentos.
    secureStorage: secureStorage,     // Para leer el refresh token.
    actualizar: (nuevo) =>
        ref.read(sesionProvider.notifier).actualizarAccessToken(nuevo),
    // Actualiza el access token en memoria.

    cerrarSesion: () =>
        ref.read(sesionProvider.notifier).cerrarSesion(),
    // Si el refresh falla → cerrar sesión completa.
  ));

  return dio;
});

/*
RESUMEN DEL ARCHIVO
Este archivo define dos providers de Riverpod relacionados con el cliente HTTP Dio:

 1. dioBaseProvider
• Crea un Dio sin interceptores.
• Se usa exclusivamente por el RefreshInterceptor para reintentar peticiones cuando el access token expira.
• Es un Dio “limpio”, sin lógica adicional.

 Sirve como cliente auxiliar para renovar tokens.

 2. dioProvider
• Crea el Dio principal que usarán todos los repositorios.
• Le añade dos interceptores fundamentales:

🔹 JwtInterceptor
• Inserta automáticamente el access token actual en cada petición.
• Lee el token desde SesionNotifier.

🔹 RefreshInterceptor
• Si el backend devuelve 401 Unauthorized, intenta:
• Renovar el access token usando el refresh token.
• Reintentar la petición original.
• Si falla → cerrar sesión.

 Este Dio es el cliente oficial de tu app, con autenticación automática y refresh integrado.

 Repositorios (infraestructura)
   ↓
dioProvider (Dio con interceptores)
   ↓
JwtInterceptor (añade access token)
   ↓
RefreshInterceptor (renueva tokens)
   ↓
Backend

 */