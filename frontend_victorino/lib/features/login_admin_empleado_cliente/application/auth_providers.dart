// Providers compartidos entre las features de login y registro:
// - authRepositorioProvider → instancia del repositorio HTTP.
// - iniciarSesionProvider   → caso de uso de login.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/dio_provider.dart';
import '../data/repositorios/auth_repositorio_impl.dart';
import '../domain/casos_uso/iniciar_sesion.dart';
import '../domain/repositorios/auth_repositorio.dart';

final authRepositorioProvider = Provider<AuthRepositorio>((ref) {
  final dio = ref.read(dioProvider);
  // Lee el cliente Dio previamente configurado (baseUrl, headers, timeouts, etc.).

  return AuthRepositorioImpl(dio: dio);
  // Devuelve la implementación concreta del repositorio de autenticación,
  // inyectándole el cliente HTTP.
});

final iniciarSesionProvider = Provider<IniciarSesion>((ref) {
  return IniciarSesion(ref.read(authRepositorioProvider));
});


/*
  RESUMEN DEL ARCHIVO
Este archivo define dos providers de Riverpod:

1) authRepositorioProvider
    Crea una instancia de AuthRepositorioImpl usando un cliente Dio.
    Es la capa de acceso a datos para autenticación (login, registro, refresh, logout).

2) iniciarSesionProvider
    Crea el caso de uso IniciarSesion, inyectándole el repositorio anterior.
    Permite que la UI o los notifiers ejecuten el inicio de sesión sin conocer detalles del backend.

En resumen:
  Este archivo conecta la infraestructura (Dio) con la capa de dominio (casos de uso), siguiendo una arquitectura limpia y desacoplada.

Relación entre capas (arquitectura limpia)
UI  →  Notifier  →  Caso de uso (dominio)  →  Repositorio (infraestructura)  →  Dio (HTTP)
- Providers de Riverpod conectan las capas sin acoplarlas.
- Dio es el cliente HTTP que hace las peticiones reales.
- Repositorio transforma datos de la API en modelos internos.
- Caso de uso ejecuta la lógica de negocio.
- Notifier controla el estado y se comunica con la UI.
 */