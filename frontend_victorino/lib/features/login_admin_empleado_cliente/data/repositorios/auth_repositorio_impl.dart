// Implementación HTTP del AuthRepositorio.
// Se apoya en Dio + ErrorMapper. Cualquier excepción se transforma en
// ApiException(Failure) antes de salir del repositorio.
import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../shared/modelos/sesion_usuario.dart';
import '../../domain/entidades/credenciales.dart';
import '../../domain/repositorios/auth_repositorio.dart';
import '../modelos/auth_response_dto.dart';

class AuthRepositorioImpl implements AuthRepositorio {
  // Implementación concreta del repositorio de autenticación.
  // Pertenece a la CAPA DE INFRAESTRUCTURA.

  AuthRepositorioImpl({required Dio dio, ErrorMapper? errorMapper})
      : _dio = dio,
        _errorMapper = errorMapper ?? const ErrorMapper();
  // Recibe el cliente Dio (inyectado desde Riverpod).
  // Recibe un ErrorMapper opcional para transformar errores en Failure.

  final Dio _dio;
  // Cliente HTTP usado para hacer peticiones al backend.

  final ErrorMapper _errorMapper;
  // Convierte errores de Dio en objetos Failure manejables.

  @override
  Future<ResultadoAuth> iniciarSesion(Credenciales credenciales) async {
    // Métodoo que implementa el login.
    // Pertenece a la interfaz AuthRepositorio.

    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authLogin,
        // Ruta del backend para iniciar sesión.

        data: {
          'correo': credenciales.correo.trim(),
          'password': credenciales.password,
        },
        // Datos enviados al backend.
      );

      return _aResultado(AuthResponseDto.fromJson(resp.data!));
      // Convierte la respuesta JSON en DTO y luego en ResultadoAuth.

    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
      // Si ocurre un error, se transforma en Failure y se envuelve en ApiException.
    }
  }

  @override
  Future<ResultadoAuth> registrarCliente(DatosRegistro datos) async {
    // Métodoo que implementa el registro de cliente.

    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authRegistro,
        // Ruta del backend para registrar cliente.

        data: {
          'nombre': datos.nombre.trim(),
          'apellidos': datos.apellidos.trim(),
          'telefono': datos.telefono?.trim(),
          'correo': datos.correo.trim(),
          'password': datos.password,
        },
      );

      return _aResultado(AuthResponseDto.fromJson(resp.data!));
      // Convierte la respuesta del backend en ResultadoAuth.

    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
      // Mapea el error y lo lanza como ApiException.
    }
  }

  @override
  Future<void> cerrarSesion(String refreshToken) async {
    // Métodoo para cerrar sesión en el backend.

    try {
      await _dio.post(
        ApiEndpoints.authLogout,
        data: {'refreshToken': refreshToken},
      );
      // Envía el refresh token para invalidarlo en el backend.

    } catch (e) {
      // Logout idempotente: si falla, no lo propagamos.
      // La app igualmente borrará la sesión local.
    }
  }

  // Convierte el DTO en (SesionUsuario + refreshToken).
  ResultadoAuth _aResultado(AuthResponseDto dto) {
    // Métodoo privado que transforma el DTO del backend en modelos internos.

    final sesion = SesionUsuario(
      idUsuario: dto.idUsuario,
      rol: dto.rol,
      nombreCompleto: dto.nombreCompleto,
      foto: dto.foto,
      accessToken: dto.accessToken,
    );
    // Crea el modelo de sesión que usará la app.

    return ResultadoAuth(sesion: sesion, refreshToken: dto.refreshToken);
    // Devuelve el resultado completo para la capa de dominio.
  }
}


/*
  RESUMEN DEL ARCHIVO
Este archivo define  la implementación concreta del repositorio de autenticación.
Forma parte de la capa de infraestructura dentro de una arquitectura limpia.

Su propósito es:

 1. Conectarse con el backend usando Dio
    Recibe un cliente Dio ya configurado (desde un provider).
    Hace peticiones HTTP a las rutas definidas en ApiEndpoints.

2. Implementar la interfaz AuthRepositorio
    Esto permite que la capa de dominio (casos de uso) dependa de una abstracción, no de detalles técnicos

3. Manejar errores de red
    Usa ErrorMapper para convertir errores de Dio en objetos Failure.
    Lanza ApiException para que los casos de uso o notifiers puedan gestionarlos.

4. Convertir respuestas del backend en modelos internos
      Convierte AuthResponseDto en SesionUsuario + refreshToken.
      Devuelve un ResultadoAuth listo para usar en la capa de dominio.

      Relación dentro de la arquitectura: UI → Notifier → Caso de uso → AuthRepositorio (este archivo) → Dio → Backend

 */
