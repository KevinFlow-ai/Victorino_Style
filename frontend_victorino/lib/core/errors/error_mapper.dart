// Convierte una DioException (o cualquier error inesperado) en un Failure tipado.
// Centralizar la traducción aquí evita que cada repositorio tenga que conocer
// los detalles de Dio o la forma exacta del JSON ApiError del backend.
import 'package:dio/dio.dart';

import 'failure.dart';

class ErrorMapper {
  const ErrorMapper();

  // Punto de entrada principal: cualquier excepción acabará en un Failure.
  Failure mapear(Object error) {
    if (error is DioException) {
      return _mapearDio(error);
    }
    return const FailureServidor();
  }

  Failure _mapearDio(DioException ex) {
    // Sin respuesta del servidor: timeout, sin red, host inalcanzable.
    if (ex.type == DioExceptionType.connectionTimeout ||
        ex.type == DioExceptionType.receiveTimeout ||
        ex.type == DioExceptionType.sendTimeout ||
        ex.type == DioExceptionType.connectionError) {
      return const FailureRed();
    }

    final response = ex.response;
    if (response == null) {
      return const FailureServidor();
    }

    final data = response.data;
    final mensaje = _extraerMensaje(data);

    return switch (response.statusCode ?? 0) {
      400 => FailureValidacion(mensaje ?? 'Datos inválidos', _extraerCampos(data)),
      401 => FailureCredenciales(mensaje ?? 'Sesión inválida'),
      403 => FailurePermiso(mensaje ?? 'Sin permiso'),
      404 => FailureNoEncontrado(mensaje ?? 'No encontrado'),
      // Para los 409 leemos también el campo "detalles" si el backend lo envía (por ejemplo
      // en CITA_MISMO_DIA / CITA_MISMA_SEMANA / CITA_MISMO_SERVICIO). El frontend lo usa para
      // mostrar mensajes contextuales y abrir el wizard precargado con la cita existente.
      409 => FailureConflicto(mensaje ?? 'Conflicto al guardar', _extraerDetalles(data)),
      _ => FailureServidor(mensaje ?? 'Error del servidor'),
    };
  }

  // Lee el payload "detalles" del ApiError (puede ser null si el 409 no lo envía).
  // Convierte el Map<dynamic, dynamic> que produce Jackson a un Map<String, dynamic>.
  Map<String, dynamic>? _extraerDetalles(dynamic data) {
    if (data is Map<String, dynamic>) {
      final det = data['detalles'];
      if (det is Map) {
        return det.map((k, v) => MapEntry(k.toString(), v));
      }
    }
    return null;
  }

  // Lee el campo "message" del JSON ApiError. Si la respuesta no es JSON, devuelve null.
  String? _extraerMensaje(dynamic data) {
    if (data is Map<String, dynamic>) {
      final m = data['message'];
      if (m is String && m.isNotEmpty) return m;
    }
    return null;
  }

  // Lee la lista "fields" del ApiError y la convierte en Map<campo, mensaje>.
  Map<String, String> _extraerCampos(dynamic data) {
    if (data is Map<String, dynamic>) {
      final lista = data['fields'];
      if (lista is List) {
        return {
          for (final item in lista)
            if (item is Map &&
                item['field'] is String &&
                item['message'] is String)
              item['field'] as String: item['message'] as String,
        };
      }
    }
    return const {};
  }
}
