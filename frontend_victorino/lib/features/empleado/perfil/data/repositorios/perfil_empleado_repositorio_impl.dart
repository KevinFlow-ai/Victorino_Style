import 'package:dio/dio.dart';

import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/errors/error_mapper.dart';
import '../../../../administrador/agenda/data/modelos/agenda_dtos.dart';
import '../../../../administrador/agenda/domain/entidades/cita.dart';
import '../../domain/entidades/perfil_resumen_empleado.dart';
import '../../domain/repositorios/perfil_empleado_repositorio.dart';

class PerfilEmpleadoRepositorioImpl implements PerfilEmpleadoRepositorio {
  PerfilEmpleadoRepositorioImpl({required Dio dio, ErrorMapper? errorMapper})
      : _dio = dio,
        _errorMapper = errorMapper ?? const ErrorMapper();

  final Dio _dio;
  final ErrorMapper _errorMapper;

  @override
  Future<PerfilResumenEmpleado> obtenerResumen(int idEmpleado) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(ApiEndpoints.empleadoPerfilResumen(idEmpleado));
      final data = resp.data;

      if (data == null) throw Exception('Servidor devolvió datos vacíos');

      return PerfilResumenEmpleado(
        id: (data['id'] as num?)?.toInt() ?? 0,
        nombreCompleto: data['nombreCompleto']?.toString() ?? 'Sin nombre',
        fotoUrl: data['fotoUrl']?.toString(),
        citasCompletadas: (data['citasCompletadas'] as num?)?.toInt() ?? 0,
        tiempoExperiencia: data['tiempoExperiencia']?.toString() ?? 'N/A',
      );
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  @override
  Future<void> cambiarPassword({required String actual, required String nueva}) async {
    try {
      await _dio.patch(
        ApiEndpoints.empleadoCambiarPassword,
        data: {'oldPassword': actual, 'newPassword': nueva},
      );
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  @override
  Future<HistorialCliente> obtenerHistorialClienteConEmpleado(int idCliente, int idEmpleado) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.historialClienteConEmpleado(idCliente, idEmpleado),
      );
      return HistorialClienteDto(resp.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }
}
