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

import 'dart:io'; // Necesario para manejar archivos (por ejemplo, fotos)

import 'package:dio/dio.dart'; // Cliente HTTP

// Rutas del backend (URLs)
import '../../../../../core/api/api_endpoints.dart';

// Manejo de errores personalizados
import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/errors/error_mapper.dart';

// Entidades del dominio (lo que usa la app internamente)
import '../../domain/entidades/empleado.dart';

// Contrato que esta clase debe cumplir
import '../../domain/repositorios/empleado_admin_repositorio.dart';

// DTOs (objetos que representan el JSON que viene del backend)
import '../modelos/empleado_admin_dto.dart';

class EmpleadoAdminRepositorioImpl implements EmpleadoAdminRepositorio {
  // Constructor: recibe un cliente HTTP (Dio) y un mapeador de errores.
  EmpleadoAdminRepositorioImpl({required Dio dio, ErrorMapper? errorMapper})
      : _dio = dio,
        _errorMapper = errorMapper ?? const ErrorMapper();

  final Dio _dio; // Cliente HTTP
  final ErrorMapper _errorMapper; // Convierte errores de Dio en errores propios

  // ==========================================================================
  // LISTAR EMPLEADOS
  // Hace una petición GET al backend para obtener una lista de empleados.
  // Puede incluir empleados inactivos si se pasa incluirInactivos = true.
  // ==========================================================================
  @override
  Future<List<Empleado>> listar({bool incluirInactivos = false}) async {
    try {
      final resp = await _dio.get<List<dynamic>>(
        ApiEndpoints.adminEmpleados,
        queryParameters: {'incluirInactivos': incluirInactivos},
      );

      // Si no viene nada, devolvemos una lista vacía
      final lista = resp.data ?? const [];

      // Convertimos cada JSON en un DTO, y luego en una entidad de dominio
      return lista
          .map((j) => EmpleadoAdminDto.fromJson(j as Map<String, dynamic>).aEntidad())
          .toList();
    } catch (e) {
      // Cualquier error se transforma en ApiException
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  // ==========================================================================
  // OBTENER UN EMPLEADO POR ID
  // Hace un GET a /empleados/{id} y devuelve un empleado.
  // ==========================================================================
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

  // ==========================================================================
  // CREAR UN EMPLEADO
  // Hace un POST enviando los datos del empleado en formato JSON.
  // El backend devuelve el empleado creado.
  // ==========================================================================
  @override
  Future<Empleado> crear(DatosEmpleado datos) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.adminEmpleados,
        data: _aBody(datos), // Convertimos la entidad a JSON
      );

      return EmpleadoAdminDto.fromJson(resp.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  // ==========================================================================
  // EDITAR UN EMPLEADO
  // Hace un PUT a /empleados/{id} con los nuevos datos.
  // ==========================================================================
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

  // ==========================================================================
  // DAR DE BAJA A UN EMPLEADO
  // Hace un DELETE a /empleados/{id}.
  // No devuelve nada.
  // ==========================================================================
  @override
  Future<void> darBaja(int id) async {
    try {
      await _dio.delete(ApiEndpoints.adminEmpleadoPorId(id));
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  // ==========================================================================
  // SUBIR FOTO DE EMPLEADO
  // Envía un archivo (foto) al backend usando multipart/form-data.
  // El backend devuelve la URL de la foto subida.
  // ==========================================================================
  @override
  Future<String> subirFoto(int id, File archivo) async {
    try {
      // Preparamos el archivo para enviarlo
      final form = FormData.fromMap({
        'archivo': await MultipartFile.fromFile(
          archivo.path,
          filename: archivo.uri.pathSegments.last, // Nombre del archivo
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

  // ==========================================================================
  // CANCELAR TODAS LAS CITAS FUTURAS DE UN EMPLEADO
  // Hace un POST a /empleados/{id}/cancelar-citas.
  // Devuelve un resumen de cuántas citas fueron canceladas.
  // ==========================================================================
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

  // ==========================================================================
  // MÉTODOo PRIVADO: CONVERTIR DATOS DEL EMPLEADO A JSON
  // El backend espera un JSON con estos campos exactos.
  // Aquí limpiamos espacios y aseguramos que los valores estén correctos.
  // ==========================================================================
  Map<String, dynamic> _aBody(DatosEmpleado datos) => {
    'nombre': datos.nombre.trim(),
    'apellidos': datos.apellidos.trim(),
    'telefono': datos.telefono?.trim(),
    'correo': datos.correo.trim(),
    'passwordProvisional': datos.passwordProvisional ?? '',
  };
}