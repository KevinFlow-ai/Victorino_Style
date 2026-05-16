// Modelo de error de dominio. La UI nunca habla de DioException ni de status HTTP:
// recibe un Failure y decide qué mensaje mostrar.
//
// Sealed class con subclases concretas para que el switch sea exhaustivo
sealed class Failure {
  const Failure(this.mensaje);

  // Mensaje listo para mostrar al usuario en español.
  final String mensaje;

  @override
  String toString() => 'Failure($runtimeType, $mensaje)';
}

// 0 / sin red / timeout. La app debe ofrecer reintentar.
class FailureRed extends Failure {
  const FailureRed([String mensaje = 'Sin conexión, inténtalo de nuevo']) : super(mensaje);
}

// 400. Errores por campo (lista field → mensaje).
class FailureValidacion extends Failure {
  const FailureValidacion(super.mensaje, this.errores);

  // Mapa campo → mensaje devuelto por el backend.
  final Map<String, String> errores;
}

// 401 en login → credenciales incorrectas.
// 401 en otras rutas → sesión expirada (refresh ya falló).
class FailureCredenciales extends Failure {
  const FailureCredenciales([String mensaje = 'Correo o contraseña incorrectos']) : super(mensaje);
}

// 403 → autenticado pero sin permiso.
class FailurePermiso extends Failure {
  const FailurePermiso([String mensaje = 'No tienes permiso para esta acción']) : super(mensaje);
}

// 404 → recurso inexistente.
class FailureNoEncontrado extends Failure {
  const FailureNoEncontrado([String mensaje = 'No se ha encontrado lo solicitado']) : super(mensaje);
}

// 409 → conflicto (correo duplicado, hueco ya ocupado, regla 1 cita por día/semana/servicio…).
// El campo "detalles" llega cuando el backend envía contenido extra estructurado en el ApiError
// (por ejemplo: id, fecha, hora y nombre del servicio de la cita existente que bloquea la nueva
// reserva, junto con un código como CITA_MISMO_DIA / CITA_MISMA_SEMANA / CITA_MISMO_SERVICIO).
// Es null cuando el 409 es genérico (correo duplicado, etc.).
class FailureConflicto extends Failure {
  const FailureConflicto(super.mensaje, [this.detalles]);

  final Map<String, dynamic>? detalles;

  // Helper: lee el "codigo" del payload de detalles. Devuelve null si no hay payload o no hay código.
  String? get codigo {
    final d = detalles;
    if (d == null) return null;
    final c = d['codigo'];
    return c is String ? c : null;
  }
}

// 5xx o cualquier otro error inesperado.
class FailureServidor extends Failure {
  const FailureServidor([String mensaje = 'Error del servidor, prueba más tarde']) : super(mensaje);
}
