// ============================================================================
// REPOSITORIO HTTP PARA ADMINISTRAR EMPLEADOS
// ============================================================================
//
// Este archivo implementa un "repositorio". En programación, un repositorio es
// una clase que se encarga de hablar con el servidor (backend) para obtener,
// crear, editar o borrar datos. En este caso, datos de EMPLEADOS.
//
// Aquí usamos la librería "Dio" para hacer peticiones HTTP (GET, POST, PUT, DELETE).
// Cada vez que algo falla, convertimos el error en un ApiException para que
// el resto de la app pueda manejarlo de forma uniforme.
//
// También convertimos los JSON del backend en objetos de Dart (DTO → Entidad).
// ============================================================================

import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/errors/error_mapper.dart';
import '../../domain/entidades/empleado.dart';
import '../../domain/repositorios/empleado_admin_repositorio.dart';
import '../modelos/empleado_admin_dto.dart';

class EmpleadoAdminRepositorioImpl implements EmpleadoAdminRepositorio {
  // Constructor: recibe Dio y un ErrorMapper opcional.
  EmpleadoAdminRepositorioImpl({required Dio dio, ErrorMapper? errorMapper})
      : _dio = dio,
        _errorMapper = errorMapper ?? const ErrorMapper();

  final Dio _dio;              // Cliente HTTP
  final ErrorMapper _errorMapper; // Convierte errores de Dio en errores de dominio

  @override
  Future<List<Empleado>> listar({bool incluirInactivos = false}) async {
    try {
      final resp = await _dio.get<List<dynamic>>(
        ApiEndpoints.adminEmpleados,
        queryParameters: {'incluirInactivos': incluirInactivos},
      );

      return (resp.data ?? const [])
          .map((j) => EmpleadoAdminDto.fromJson(j as Map<String, dynamic>).aEntidad())
          .toList();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  @override
  Future<Empleado> obtener(int id) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.adminEmpleadoPorId(id),
      );

      return EmpleadoAdminDto.fromJson(resp.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  @override
  Future<Empleado> crear(DatosEmpleado datos) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.adminEmpleados,
        data: _aBody(datos),
      );

      return EmpleadoAdminDto.fromJson(resp.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  @override
  Future<Empleado> editar(int id, DatosEmpleado datos) async {
    try {
      final resp = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.adminEmpleadoPorId(id),
        data: _aBody(datos),
      );

      return EmpleadoAdminDto.fromJson(resp.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  @override
  Future<void> darBaja(int id) async {
    try {
      await _dio.delete(ApiEndpoints.adminEmpleadoPorId(id));
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  @override
  Future<String> subirFoto(int id, File archivo) async {
    try {
      final form = FormData.fromMap({
        'archivo': await MultipartFile.fromFile(
          archivo.path,
          filename: archivo.uri.pathSegments.last,
        ),
      });

      final resp = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.adminEmpleadoFoto(id),
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );

      return resp.data!['fotoUrl'] as String;
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  @override
  Future<ResumenCancelacionMasiva> cancelarCitasFuturas(int id) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.adminEmpleadoCancelarCitas(id),
      );

      return CancelacionMasivaDto.fromJson(resp.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  // Método privado para convertir los datos del empleado a un body JSON.
  Map<String, dynamic> _aBody(DatosEmpleado d) => {
    'nombre': d.nombre.trim(),
    'apellidos': d.apellidos.trim(),
    'telefono': d.telefono?.trim(),
    'correo': d.correo.trim(),
    if (d.passwordProvisional != null && d.passwordProvisional!.isNotEmpty)
      'passwordProvisional': d.passwordProvisional,
  };
}
