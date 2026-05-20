// Implementación HTTP del repositorio de configuración del negocio.
import 'package:dio/dio.dart';

import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/errors/error_mapper.dart';
import '../../domain/entidades/horario_peluqueria.dart';
import '../../domain/repositorios/negocio_admin_repositorio.dart';
import '../modelos/negocio_dtos.dart';



// ============================================================================
//  INTRODUCCIÓN
// ============================================================================
//
// Este archivo contiene la **implementación del repositorio** que se comunica
// con el backend mediante HTTP usando la librería **Dio**.
//
// En Clean Architecture:
//
//   UI → Notifier → Caso de Uso → Repositorio → API
//
// Este archivo es la parte:
//
//   ✔️ Repositorio (capa DATA)
//
// Su trabajo es:
//
//   - Hacer peticiones HTTP al backend
//   - Convertir JSON → DTO → Entidad
//   - Manejar errores de la API
//   - Devolver datos limpios al dominio
//
// ============================================================================
// DIAGRAMA DEL FLUJO DE DATOS
// ============================================================================
//
//   ┌──────────────┐
//   │     UI        │
//   └───────┬──────┘
//           ▼
//   ┌──────────────┐
//   │   Notifier    │
//   └───────┬──────┘
//           ▼
//   ┌──────────────┐
//   │ Caso de Uso   │
//   └───────┬──────┘
//           ▼
//   ┌──────────────────────────────┐
//   │ Repositorio (este archivo)   │
//   └───────┬──────────────────────┘
//           ▼
//   ┌──────────────┐
//   │     API       │
//   └──────────────┘




// ============================================================================
//  IMPLEMENTACIÓN DEL REPOSITORIO
// ============================================================================
//
// Esta clase implementa la interfaz "NegocioAdminRepositorio".
// Eso significa que esta clase es la que realmente hace las peticiones HTTP.
//
// Dio = cliente HTTP para hacer GET, POST, PUT, DELETE.
//
// ErrorMapper = convierte errores de Dio en errores entendibles por la app.
//
class NegocioAdminRepositorioImpl implements NegocioAdminRepositorio {
  NegocioAdminRepositorioImpl({required Dio dio, ErrorMapper? errorMapper})
      : _dio = dio,
        _errorMapper = errorMapper ?? const ErrorMapper();

  final Dio _dio;            // Cliente HTTP
  final ErrorMapper _errorMapper; // Mapea errores de Dio a ApiException

  // ==========================================================================
  //  OBTENER HORARIO (GET)
  // ==========================================================================
  //
  // 1. Llama al endpoint GET /admin/horario
  // 2. Recibe JSON
  // 3. Convierte JSON → DTO → Entidad
  //
  @override
  Future<HorarioPeluqueria> obtenerHorario() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(ApiEndpoints.adminHorario);

      // r.data es JSON → HorarioDto → Entidad
      return HorarioDto.fromJson(r.data!).aEntidad();
    } catch (e) {
      // Si algo falla, se convierte en ApiException
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  // ==========================================================================
  //  ACTUALIZAR HORARIO (PUT)
  // ==========================================================================
  //
  // 1. Convierte entidad → JSON (DTO.aBody)
  // 2. Envía PUT al backend
  // 3. Convierte respuesta JSON → DTO → Entidad
  //
  @override
  Future<HorarioPeluqueria> actualizarHorario(HorarioPeluqueria horario) async {
    try {
      final r = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.adminHorario,
        data: HorarioDto.aBody(horario),
      );

      return HorarioDto.fromJson(r.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  // ==========================================================================
  //  ACTUALIZAR DESCANSO DE EMPLEADO (PUT)
  // ==========================================================================
  //
  // 1. Envía PUT con horaInicio y duración
  // 2. Convierte JSON → DTO → Entidad
  //
  @override
  Future<DescansoEmpleado> actualizarDescanso(
      int idEmpleado, String horaInicio, int duracionMinutos) async {
    try {
      final r = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.adminEmpleadoDescanso(idEmpleado),
        data: {
          'horaInicio': '$horaInicio:00', // backend quiere segundos
          'duracionMinutos': duracionMinutos,
        },
      );

      return DescansoDto.fromJson(r.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  // ==========================================================================
  //  LISTAR FESTIVOS (GET)
  // ==========================================================================
  //
  // 1. GET /admin/festivos
  // 2. Recibe una lista de JSON
  // 3. Convierte cada JSON → DTO → Entidad
  //
  @override
  Future<List<Festivo>> listarFestivos() async {
    try {
      final r = await _dio.get<List<dynamic>>(ApiEndpoints.adminFestivos);

      return (r.data ?? const [])
          .map((j) => FestivoDto.fromJson(j as Map<String, dynamic>).aEntidad())
          .toList();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  // ==========================================================================
  //  CREAR FESTIVO (POST)
  // ==========================================================================
  //
  // 1. Envía POST con fecha, descripción y tipo
  // 2. Convierte JSON → DTO → Entidad
  //
  @override
  Future<Festivo> crearFestivo(
      String fecha, String descripcion, TipoFestivo tipo) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.adminFestivos,
        data: {
          'fecha': fecha,
          'descripcion': descripcion,
          'tipo': FestivoDto.tipoAString(tipo), // enum → string
        },
      );

      return FestivoDto.fromJson(r.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  // ==========================================================================
  //  ELIMINAR FESTIVO (DELETE)
  // ==========================================================================
  //
  // 1. DELETE /admin/festivos/{id}
  // 2. No devuelve nada
  //
  @override
  Future<void> eliminarFestivo(int id) async {
    try {
      await _dio.delete(ApiEndpoints.adminFestivoPorId(id));
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  // ==========================================================================
  //  OBTENER CIERRE ANUAL (GET)
  // ==========================================================================
  @override
  Future<CierreAnual> obtenerCierreAnual() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(ApiEndpoints.adminCierreAnual);
      return CierreAnualDto.fromJson(r.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  // ==========================================================================
  //  ACTUALIZAR CIERRE ANUAL (PUT)
  // ==========================================================================
  @override
  Future<CierreAnual> actualizarCierreAnual(
      String? fechaInicio, String? fechaFin) async {
    try {
      final r = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.adminCierreAnual,
        data: {'fechaInicio': fechaInicio, 'fechaFin': fechaFin},
      );

      return CierreAnualDto.fromJson(r.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  // ==========================================================================
  //  OBTENER CONFIGURACIÓN DE CORREO (GET)
  // ==========================================================================
  @override
  Future<ConfiguracionCorreo> obtenerConfigCorreo() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(ApiEndpoints.adminCorreo);
      return ConfiguracionCorreoDto.fromJson(r.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  // ==========================================================================
  //  ACTUALIZAR CONFIGURACIÓN DE CORREO (PUT)
  // ==========================================================================
  @override
  Future<ConfiguracionCorreo> actualizarConfigCorreo(
      String host, int port, String user, String password, bool ssl) async {
    try {
      final r = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.adminCorreo,
        data: {
          'host': host,
          'port': port,
          'user': user,
          'password': password,
          'ssl': ssl,
        },
      );
      return ConfiguracionCorreoDto.fromJson(r.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }
}
