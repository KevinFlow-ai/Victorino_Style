// Implementación HTTP del repositorio del catálogo público.
// Llama a GET /servicios y GET /empleados con el cliente Dio compartido.

import 'package:dio/dio.dart';

import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/errors/error_mapper.dart';
import '../../domain/entidades/empleado_publico.dart';
import '../../domain/entidades/servicio_publico.dart';
import '../../domain/repositorios/catalogo_repositorio.dart';
import '../modelos/empleado_publico_dto.dart';
import '../modelos/servicio_publico_dto.dart';

class CatalogoRepositorioImpl implements CatalogoRepositorio {
  CatalogoRepositorioImpl({required Dio dio, ErrorMapper? errorMapper})
      : _dio = dio,
        _errorMapper = errorMapper ?? const ErrorMapper();

  final Dio _dio;
  final ErrorMapper _errorMapper;

  @override
  Future<List<ServicioPublico>> obtenerServicios() async {
    try {
      final resp = await _dio.get<List<dynamic>>(ApiEndpoints.servicios);
      final lista = resp.data ?? const [];
      return lista
          .map((j) => ServicioPublicoDto.fromJson(j as Map<String, dynamic>).aEntidad())
          .toList();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  @override
  Future<List<EmpleadoPublico>> obtenerEmpleados() async {
    try {
      final resp = await _dio.get<List<dynamic>>(ApiEndpoints.empleados);
      final lista = resp.data ?? const [];
      return lista
          .map((j) => EmpleadoPublicoDto.fromJson(j as Map<String, dynamic>).aEntidad())
          .toList();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }
}
