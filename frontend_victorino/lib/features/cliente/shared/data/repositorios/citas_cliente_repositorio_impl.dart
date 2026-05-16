// ============================================================================
// CitasClienteRepositorioImpl — implementación HTTP de las operaciones de citas
// ----------------------------------------------------------------------------
// Conecta los 7 endpoints /cliente/citas/... con la app. Cada método encapsula
// la llamada Dio + el manejo de errores via ApiException(ErrorMapper.mapear).
// ============================================================================

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/errors/error_mapper.dart';
import '../../domain/entidades/cita_cliente.dart';
import '../../domain/entidades/datos_reserva.dart';
import '../../domain/entidades/estado_cita.dart';
import '../../domain/entidades/hueco.dart';
import '../../domain/repositorios/citas_cliente_repositorio.dart';
import '../modelos/cita_cliente_dto.dart';
import '../modelos/hueco_dto.dart';

class CitasClienteRepositorioImpl implements CitasClienteRepositorio {
  CitasClienteRepositorioImpl({required Dio dio, ErrorMapper? errorMapper})
      : _dio = dio,
        _errorMapper = errorMapper ?? const ErrorMapper();

  final Dio _dio;
  final ErrorMapper _errorMapper;

  // Formateador de fecha → "YYYY-MM-DD" (el formato que espera el backend para LocalDate).
  static final _formatoFecha = DateFormat('yyyy-MM-dd');

  // ==========================================================================
  // LISTAR MIS CITAS (con filtro opcional por estado)
  // ==========================================================================
  @override
  Future<List<CitaCliente>> listarMisCitas({EstadoCita? estado}) async {
    try {
      final resp = await _dio.get<List<dynamic>>(
        ApiEndpoints.clienteCitas,
        queryParameters: {
          if (estado != null) 'estado': estado.backendValue,
        },
      );
      final lista = resp.data ?? const [];
      return lista
          .map((j) => CitaClienteDto.fromJson(j as Map<String, dynamic>).aEntidad())
          .toList();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  // ==========================================================================
  // DETALLE DE UNA CITA PROPIA
  // ==========================================================================
  @override
  Future<CitaCliente> obtenerCita(int idCita) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.clienteCitaPorId(idCita),
      );
      return CitaClienteDto.fromJson(resp.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  // ==========================================================================
  // CITA ACTIVA (próxima CONFIRMADA / EN_PROCESO) → null si no hay (204)
  // ==========================================================================
  @override
  Future<CitaCliente?> obtenerCitaActiva() async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.clienteCitaActiva,
      );
      if (resp.statusCode == 204 || resp.data == null) return null;
      return CitaClienteDto.fromJson(resp.data!).aEntidad();
    } on DioException catch (e) {
      // Tratamos 204 No Content como "sin cita activa". Algunas configuraciones de Dio
      // lo lanzan como excepción si data es null y validateStatus falla.
      if (e.response?.statusCode == 204) return null;
      throw ApiException(_errorMapper.mapear(e));
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  // ==========================================================================
  // HUECOS DISPONIBLES — para el Paso 3 del wizard
  // ==========================================================================
  @override
  Future<List<Hueco>> obtenerDisponibilidad({
    required int idServicio,
    required DateTime fecha,
    int? idEmpleado,
    int? idCitaExcluir,
  }) async {
    try {
      final resp = await _dio.get<List<dynamic>>(
        ApiEndpoints.clienteCitaDisponibilidad,
        queryParameters: {
          'idServicio': idServicio,
          'fecha': _formatoFecha.format(fecha),
          if (idEmpleado != null) 'idEmpleado': idEmpleado,
          if (idCitaExcluir != null) 'idCitaExcluir': idCitaExcluir,
        },
      );
      final lista = resp.data ?? const [];
      return lista
          .map((j) => HuecoDto.fromJson(j as Map<String, dynamic>).aEntidad())
          .toList();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  // ==========================================================================
  // RESERVAR
  // ==========================================================================
  @override
  Future<CitaCliente> reservar(DatosReserva datos) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.clienteCitas,
        data: _bodyReserva(datos),
      );
      return CitaClienteDto.fromJson(resp.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  // ==========================================================================
  // MODIFICAR
  // ==========================================================================
  @override
  Future<CitaCliente> modificar(int idCita, DatosReserva datos) async {
    try {
      final resp = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.clienteCitaPorId(idCita),
        data: _bodyReserva(datos),
      );
      return CitaClienteDto.fromJson(resp.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  // ==========================================================================
  // CANCELAR
  // ==========================================================================
  @override
  Future<void> cancelar(int idCita) async {
    try {
      await _dio.post(ApiEndpoints.clienteCancelarCita(idCita));
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  // ==========================================================================
  // Helper privado: construye el body JSON de reservar/modificar.
  // ==========================================================================
  Map<String, dynamic> _bodyReserva(DatosReserva datos) {
    assert(datos.esCompleto, 'DatosReserva incompleto al llamar al backend');
    return {
      'idServicio': datos.idServicio,
      // Si el cliente eligió "Cualquiera" puede ser null igualmente.
      'idEmpleado': datos.idEmpleado,
      'fecha': _formatoFecha.format(datos.fecha!),
      'horaInicio': datos.horaInicio,
      'nota': (datos.nota == null || datos.nota!.trim().isEmpty)
          ? null
          : datos.nota!.trim(),
      'cualquieraDisponible': datos.cualquieraDisponible,
    };
  }
}
