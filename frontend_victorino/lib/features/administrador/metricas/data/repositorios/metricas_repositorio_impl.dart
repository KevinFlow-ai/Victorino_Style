import 'package:dio/dio.dart';

import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/errors/error_mapper.dart';
import '../../domain/entidades/metricas_resumen.dart';
import '../../domain/repositorios/metricas_repositorio.dart';
import '../modelos/metricas_dto.dart';



// ============================================================================
// REPOSITORIO METRICAS
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
class MetricasRepositorioImpl implements MetricasRepositorio {
  MetricasRepositorioImpl({required Dio dio, ErrorMapper? errorMapper})
      : _dio = dio,
        _errorMapper = errorMapper ?? const ErrorMapper();

  final Dio _dio;
  final ErrorMapper _errorMapper;

  @override
  Future<MetricasResumen> resumen({required String fechaInicio, required String fechaFin}) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.adminMetricasResumen,
        queryParameters: {'fechaInicio': fechaInicio, 'fechaFin': fechaFin},
      );
      return MetricasResumenDto(r.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }
}
