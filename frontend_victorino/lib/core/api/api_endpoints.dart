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

  // ==========================================================================
  // RUTAS DEL PANEL ADMIN
  // ==========================================================================

  // Empleados
  static const adminEmpleados = '/admin/empleados';
  static String adminEmpleadoPorId(int id) => '/admin/empleados/$id';
  static String adminEmpleadoFoto(int id) => '/admin/empleados/$id/foto';
  static String adminEmpleadoCancelarCitas(int id) => '/admin/empleados/$id/cancelar-citas';
  static String adminEmpleadoDescanso(int id) => '/admin/empleados/$id/descanso';

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
}

/*
RESUMEN DEL ARCHIVO
Este archivo define la clase ApiEndpoints, cuyo propósito es centralizar la URL base del backend y todas las rutas de la API.
Esto permite:
- Cambiar entre entornos (desarrollo, producción, local, emulador) sin tocar el resto del código.
- Evitar repetir strings de rutas en los repositorios.
- Mantener un único punto de verdad para todas las URLs del backend.
- Permitir configurar la URL base mediante --dart-define, lo cual es ideal para CI/CD o builds diferentes.

 En resumen:
 Este archivo es la fuente única de todas las rutas del backend, facilitando mantenimiento, consistencia y cambios de entorno.

 */