// Implementación HTTP del repositorio de agenda del admin.
// --------------------------------------------------------
// Este archivo contiene la implementación concreta del repositorio
// AgendaAdminRepositorio, usando Dio para hacer peticiones HTTP al backend.

import 'package:dio/dio.dart';

import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/errors/error_mapper.dart';
import '../../domain/entidades/cita.dart';
import '../../domain/repositorios/agenda_admin_repositorio.dart';
import '../modelos/agenda_dtos.dart';


// ============================================================================
// REPOSITORIO HTTP PARA LA AGENDA-CITAS
// ============================================================================
//
// Este archivo implementa un "repositorio". En programación, un repositorio es
// una clase que se encarga de hablar con el servidor (backend) para obtener,
// crear, editar o borrar datos.
//
// Aquí usamos la librería "Dio" para hacer peticiones HTTP (GET, POST, PUT, DELETE).
// Cada vez que algo falla, convertimos el error en un ApiException para que
// el resto de la app pueda manejarlo de forma uniforme.
//
// También convertimos los JSON del backend en objetos de Dart (DTO → Entidad).
// ============================================================================


class AgendaAdminRepositorioImpl implements AgendaAdminRepositorio {
  // Constructor: recibe Dio y un ErrorMapper opcional.
  AgendaAdminRepositorioImpl({required Dio dio, ErrorMapper? errorMapper})
      : _dio = dio,
        _errorMapper = errorMapper ?? const ErrorMapper();

  final Dio _dio;              // Cliente HTTP
  final ErrorMapper _errorMapper; // Convierte errores de Dio en errores de dominio


  // ---------------------------------------------------------------------------
  // OBTENER AGENDA GLOBAL
  // ---------------------------------------------------------------------------
  // Llama al endpoint GET /admin/agenda con filtros:
  // - desde
  // - hasta
  // - empleadoId (opcional)
  // - estado (opcional)
  @override
  Future<List<CitaAdmin>> agendaGlobal({
    required String desde,
    required String hasta,
    int? idEmpleado,
    EstadoCita? estado,
  }) async {
    try {
      // Convierte el enum EstadoCita a String para enviarlo al backend.
      final estadoStr = estado == null ? null : estadoCitaAString(estado);

      // Petición GET con query parameters.
      final r = await _dio.get<List<dynamic>>(
        ApiEndpoints.adminAgenda,
        queryParameters: {
          'desde': desde,
          'hasta': hasta,
          // null-aware element: si el valor es null, NO se envía al backend.
          'empleadoId': ?idEmpleado,
          'estado': ?estadoStr,
        },
      );

      // Convierte cada JSON recibido en una entidad CitaAdmin.
      return (r.data ?? const [])
          .map((j) => CitaAdminDto(j as Map<String, dynamic>).aEntidad())
          .toList();

    } catch (e) {
      // Si hay error HTTP, se mapea a ApiException.
      throw ApiException(_errorMapper.mapear(e));
    }
  }


  // ---------------------------------------------------------------------------
  // OBTENER HISTORIAL DE UN CLIENTE
  // ---------------------------------------------------------------------------
  // Llama a GET /admin/clientes/{id}/historial
  @override
  Future<HistorialCliente> historialCliente(int idCliente) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.adminHistorialCliente(idCliente),
      );

      // Convierte el JSON en la entidad HistorialCliente.
      return HistorialClienteDto(r.data!).aEntidad();

    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }


  // ---------------------------------------------------------------------------
  // CREAR WALK-IN
  // ---------------------------------------------------------------------------
  // Llama a POST /admin/citas/walk-in
  // Envía un body construido con walkInABody()
  @override
  Future<CitaAdmin> crearWalkIn(DatosWalkIn datos) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.adminCitasWalkIn,
        data: walkInABody(datos), // Convierte DatosWalkIn → JSON
      );

      // Convierte el JSON en una entidad CitaAdmin.
      return CitaAdminDto(r.data!).aEntidad();

    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }


  // ---------------------------------------------------------------------------
  // OBTENER AVISOS DE CANCELACIONES FRECUENTES
  // ---------------------------------------------------------------------------
  // Llama a GET /admin/avisos/cancelaciones
  @override
  Future<List<AvisoCliente>> avisosCancelacionesFrecuentes() async {
    try {
      final r = await _dio.get<List<dynamic>>(
        ApiEndpoints.adminAvisosCancelaciones,
      );

      // Convierte cada JSON en AvisoCliente.
      return (r.data ?? const [])
          .map((j) => AvisoClienteDto(j as Map<String, dynamic>).aEntidad())
          .toList();

    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }
}
