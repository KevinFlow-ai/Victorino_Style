import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/entidades/notificacion.dart';
import '../../domain/repositorios/notificacion_repositorio.dart';
import '../modelos/notificacion_dto.dart';

class NotificacionesRepositorioImpl implements NotificacionesRepositorio {
  NotificacionesRepositorioImpl({required Dio dio, ErrorMapper? errorMapper})
      : _dio = dio,
        _errorMapper = errorMapper ?? const ErrorMapper();

  final Dio _dio;
  final ErrorMapper _errorMapper;

  @override
  Future<List<Notificacion>> obtenerBandeja() async {
    try {
      final resp = await _dio.get<List<dynamic>>(
        ApiEndpoints.notificaciones,
        // El JWT del usuario se envía automáticamente via JwtInterceptor.
        // El backend extrae el idUsuario del token.
      );
      final lista = resp.data ?? const [];
      return lista
          .cast<Map<String, dynamic>>()
          .map(NotificacionDto.fromJson)
          .map((dto) => dto.aEntidad())
          .toList();
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  @override
  Future<void> marcarLeida(int idNotificacion) async {
    try {
      await _dio.patch<void>(ApiEndpoints.notificacionLeer(idNotificacion));
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  @override
  Future<void> marcarTodasLeidas() async {
    try {
      await _dio.post<void>(ApiEndpoints.notificacionesLeerTodas);
    } catch (e) {
      throw ApiException(_errorMapper.mapear(e));
    }
  }

  @override
  Future<void> registrarDeviceToken(int idUsuario, String tokenFcm, {bool esLoginExplicito = false}) async {
    try {
      // El endpoint /notificaciones/fcm-token es público; necesita idUsuario en el body.
      // esLoginExplicito=true → login con credenciales: el backend enviará notificación de bienvenida.
      // esLoginExplicito=false → restauración de sesión (splash): sin notificación.
      await _dio.post<void>(
        ApiEndpoints.fcmToken,
        data: {
          'idUsuario': idUsuario,
          'tokenFcm': tokenFcm,
          'plataformaFcm': 'ANDROID',
          'esLoginExplicito': esLoginExplicito,
        },
      );
    } catch (e) {
      // Notificación push opcional: si falla el registro del token, la app sigue con in-app.
      throw ApiException(_errorMapper.mapear(e));
    }
  }
}

