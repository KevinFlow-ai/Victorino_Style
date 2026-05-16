// ============================================================================
// PerfilRepositorioImpl — implementación HTTP del repositorio de perfil
// ----------------------------------------------------------------------------
// Cubre los 6 endpoints /cliente/perfil del backend usando Dio.
// Maneja multipart (foto) y errores con ApiException(ErrorMapper.mapear).
// ============================================================================

import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/errors/error_mapper.dart';
import '../../domain/entidades/perfil_cliente.dart';
import '../../domain/repositorios/perfil_repositorio.dart';
import '../modelos/perfil_cliente_dto.dart';

class PerfilRepositorioImpl implements PerfilRepositorio {
  PerfilRepositorioImpl({required Dio dio, ErrorMapper? errorMapper})
      : _dio = dio,
        _errorMapper = errorMapper ?? const ErrorMapper();

  final Dio _dio;
  final ErrorMapper _errorMapper;

  @override
  Future<PerfilCliente> obtener() async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(ApiEndpoints.clientePerfil);
      return PerfilClienteDto.fromJson(resp.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  @override
  Future<PerfilCliente> editar(DatosPerfilCliente datos) async {
    try {
      final resp = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.clientePerfil,
        data: {
          'nombre': datos.nombre.trim(),
          'apellidos': datos.apellidos.trim(),
          'correo': datos.correo.trim(),
          'telefono':
              (datos.telefono == null || datos.telefono!.isBlank()) ? null : datos.telefono!.trim(),
        },
      );
      return PerfilClienteDto.fromJson(resp.data!).aEntidad();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  @override
  Future<String> subirFoto(File archivo) async {
    try {
      final form = FormData.fromMap({
        'foto': await MultipartFile.fromFile(
          archivo.path,
          filename: archivo.uri.pathSegments.last,
        ),
      });
      final resp = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.clientePerfilFoto,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return resp.data!['fotoUrl'] as String;
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  @override
  Future<void> cambiarPassword({required String actual, required String nueva}) async {
    try {
      await _dio.post(
        ApiEndpoints.clientePerfilCambiarPwd,
        data: {'actual': actual, 'nueva': nueva},
      );
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  @override
  Future<void> configurarPush(bool pushActiva) async {
    try {
      await _dio.put(
        ApiEndpoints.clientePerfilNotificaciones,
        data: {'pushActiva': pushActiva},
      );
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  @override
  Future<void> eliminarCuenta(String password) async {
    try {
      await _dio.delete(
        ApiEndpoints.clientePerfil,
        data: {'password': password},
      );
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }
}

// Extensión privada para evitar el típico `s.trim().isEmpty` repetido.
extension _CadenaUtil on String {
  bool isBlank() => trim().isEmpty;
}
