// Interfaz del repositorio de autenticación
// La capa data implementa esta interfaz contra el backend HTTP; la capa de
// dominio solo conoce este contrato.
import '../../../../shared/modelos/sesion_usuario.dart';
import '../entidades/credenciales.dart';
// Importa modelos del dominio: SesionUsuario y Credenciales.

// -----------------------------------------------------------------------------
// Resultado conjunto de un login/registro: la sesión + el refresh token plano.
// El refresh se devuelve aparte porque NO forma parte del modelo de sesión en memoria
// (se persiste en SecureStorage por su lado).
// -----------------------------------------------------------------------------
class ResultadoAuth {
  const ResultadoAuth({
    required this.sesion,
    required this.refreshToken,
  });

  final SesionUsuario sesion;   // Modelo interno con datos del usuario autenticado.
  final String refreshToken;    // Token persistible para renovar sesión.
}

// -----------------------------------------------------------------------------
// Datos completos para el registro de un cliente nuevo.
// Este modelo pertenece a la CAPA DE DOMINIO.
// -----------------------------------------------------------------------------
class DatosRegistro {
  const DatosRegistro({
    required this.nombre,
    required this.apellidos,
    required this.correo,
    required this.password,
    this.telefono,
  });

  final String nombre;       // Nombre del cliente.
  final String apellidos;    // Apellidos del cliente.
  final String? telefono;    // Teléfono opcional.
  final String correo;       // Correo electrónico.
  final String password;     // Contraseña.
}

// -----------------------------------------------------------------------------
// Contrato del repositorio. Las implementaciones lanzan ApiException(Failure)
// cuando algo va mal (HTTP 4xx/5xx, sin red, etc.).
//
// Esta interfaz pertenece a la CAPA DE DOMINIO.
// La implementación real (AuthRepositorioImpl) pertenece a la CAPA DE INFRAESTRUCTURA.
// -----------------------------------------------------------------------------
abstract class AuthRepositorio {
  Future<ResultadoAuth> iniciarSesion(Credenciales credenciales);
  // Inicia sesión con correo y contraseña.

  Future<ResultadoAuth> registrarCliente(DatosRegistro datos);
  // Registra un nuevo cliente.

  Future<void> cerrarSesion(String refreshToken);
  // Cierra sesión invalidando el refresh token en el backend.

  // --- Métodos de recuperación de contraseña ---

  Future<void> enviarCodigoRecuperacion(String correo);
  // Solicita el envío de un código de 6 dígitos al correo.

  Future<void> verificarCodigoOtp(String correo, String codigo);
  // Verifica si el código introducido es correcto para ese correo.

  Future<void> restablecerContrasena(String correo, String codigo, String nuevaPassword);
// Cambia la contraseña usando el código verificado.
}

