// Centraliza la URL base y todas las rutas relativas del API.
// Cambiar de entorno (dev/prod) implica solo tocar este archivo.
class ApiEndpoints {
  ApiEndpoints._();
  // Constructor privado: evita instanciar la clase.
  // Esta clase solo se usa como contenedor estático.

  // baseUrl recomendado por plataforma:
  // - Android emulador → http://10.0.2.2:8080/api/v1
  // - iOS simulador / web / desktop → http://localhost:8080/api/v1
  // - Dispositivo físico → IP del host en la LAN
  //
  // Para no decidir aquí, se lee desde --dart-define con fallback a 10.0.2.2
  // (compatible con Android Emulator que es el caso de uso por defecto).
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );

  // Rutas de autenticación.
  static const authRegistro = '/auth/registro';
  static const authLogin = '/auth/login';
  static const authRefresh = '/auth/refresh';
  static const authLogout = '/auth/logout';

  // Rutas de recuperación de contraseña
  static const authForgotPassword = '/auth/forgot-password';
  static const authVerifyOtp = '/auth/verify-otp';
  static const authResetPassword = '/auth/reset-password';

  // ==========================================================================
  // RUTAS DEL PANEL ADMIN / EMPLEADO
  // ==========================================================================

  // Empleados
  static const adminEmpleados = '/admin/empleados';
  static String adminEmpleadoPorId(int id) => '/admin/empleados/$id';
  static String adminEmpleadoFoto(int id) => '/admin/empleados/$id/foto';
  static String adminEmpleadoCancelarCitas(int id) => '/admin/empleados/$id/cancelar-citas';
  static String adminEmpleadoDescanso(int id) => '/admin/empleados/$id/descanso';
  static String adminCitaNoPresentado(int id) => '/admin/citas/$id/no-presentado';

  // Perfil Empleado (Estadísticas y Seguridad)
  static String empleadoPerfilResumen(int id) => '/admin/empleados/$id/resumen';
  static const empleadoCambiarPassword = '/admin/empleados/me/password';

  // Historial de cliente específico con un empleado
  static String historialClienteConEmpleado(int idCliente, int idEmpleado) => 
      '/admin/clientes/$idCliente/historial-con-empleado/$idEmpleado';

  // Servicios
  static const adminServicios = '/admin/servicios';
  static String adminServicioPorId(int id) => '/admin/servicios/$id';
  static String adminServicioFoto(int id) => '/admin/servicios/$id/foto';

  // Configuración: horario, festivos, cierre anual.
  static const adminHorario = '/admin/horario';
  static const adminFestivos = '/admin/festivos';
  static String adminFestivoPorId(int id) => '/admin/festivos/$id';
  static const adminCierreAnual = '/admin/cierre-anual';

  // Agenda y walk-in.
  static const adminAgenda = '/admin/agenda';
  static String adminHistorialCliente(int id) => '/admin/clientes/$id/historial';
  static const adminCitasWalkIn = '/admin/citas/walk-in';
  static const adminAvisosCancelaciones = '/admin/avisos/cancelaciones-frecuentes';

  // Métricas.
  static const adminMetricasResumen = '/admin/metricas/resumen';

  // ==========================================================================
  // NOTIFICACIONES / FCM
  // ==========================================================================

  /// Endpoint para registrar el token FCM de un dispositivo.
  /// POST /notificaciones/fcm-token
  static const fcmToken = '/notificaciones/fcm-token';

  /// Bandeja in-app del usuario (GET /notificaciones — JWT identifica al usuario).
  static const notificaciones = '/notificaciones';

  /// Marcar notificación como leída (PATCH /notificaciones/{id}/leer).
  static String notificacionLeer(int id) => '/notificaciones/$id/leer';

  /// Aviso general del admin (POST /notificaciones/aviso-general).
  static const notificacionesAvisoGeneral = '/notificaciones/aviso-general';

  /// Marcar TODAS las notificaciones del usuario como leídas (POST /notificaciones/leer-todas).
  /// Endpoint compartido por cualquier rol autenticado.
  static const notificacionesLeerTodas = '/notificaciones/leer-todas';

  // ==========================================================================
  // CATÁLOGO PÚBLICO (autenticado, cualquier rol)
  // ==========================================================================

  /// Catálogo de servicios activos visible al cliente (GET /servicios).
  static const servicios = '/servicios';

  /// Catálogo de empleados activos visible al cliente (GET /empleados).
  static const empleados = '/empleados';

  // ==========================================================================
  // RUTAS DEL CLIENTE FINAL (rol CLIENTE)
  // ==========================================================================

  // Perfil
  static const clientePerfil = '/cliente/perfil';
  static const clientePerfilFoto = '/cliente/perfil/foto';
  static const clientePerfilCambiarPwd = '/cliente/perfil/cambiar-pwd';
  static const clientePerfilNotificaciones = '/cliente/perfil/notificaciones';

  // Citas
  static const clienteCitas = '/cliente/citas';
  static const clienteCitaActiva = '/cliente/citas/activa';
  static const clienteCitaDisponibilidad = '/cliente/citas/disponibilidad';
  static String clienteCitaPorId(int id) => '/cliente/citas/$id';
  static String clienteCancelarCita(int id) => '/cliente/citas/$id/cancelar';

  // ==========================================================================
  // HELPERS PARA URLs DE IMÁGENES
  // ==========================================================================

  // Construye la URL absoluta de una imagen subida (`/uploads/<carpeta>/<file>`).
  // El backend sirve estos recursos bajo el mismo `context-path` que el resto
  // del API (`/api/v1`), así que basta con concatenar baseUrl + ruta relativa.
  // Devuelve cadena vacía si la ruta es null o vacía.
  static String urlImagen(String? rutaRelativa) {
    if (rutaRelativa == null || rutaRelativa.isEmpty) return '';
    if (rutaRelativa.startsWith('http://') || rutaRelativa.startsWith('https://')) {
      // Algunas migraciones futuras pueden devolver URLs absolutas (ej. CDN).
      return rutaRelativa;
    }
    return '$baseUrl$rutaRelativa';
  }
}
