// Caso de uso "registrar cliente": valida políticas mínimas y delega en el
// repositorio compartido de auth. La validación principal de pwd ya la hace
// el formulario, pero defensivamente protegemos el contrato del backend.
import '../../../../../core/errors/api_exception.dart'; // Importa la clase ApiException para lanzar errores de API.
import '../../../../../core/errors/failure.dart'; // Importa tipos de Failure, como FailureValidacion.
import '../../../../login_admin_empleado_cliente/domain/repositorios/auth_repositorio.dart';
// Importa el repositorio de autenticación, que se usará para registrar al cliente.


// -----------------------------------------------------------------------------
// RESUMEN DEL ARCHIVO
// -----------------------------------------------------------------------------
// Este caso de uso "RegistrarCliente":
// 1. Recibe unos datos de registro (DatosRegistro).
// 2. Valida reglas mínimas de negocio ANTES de llamar al backend:
//    - Nombre y apellidos obligatorios.
//    - Correo con formato válido.
//    - Teléfono opcional, pero si se informa debe tener solo números y longitud válida.
//    - Contraseña con política mínima: 8-72 caracteres, al menos una mayúscula y un número.
// 3. Si alguna validación falla, lanza una ApiException con un FailureValidacion,
//    lo que permite informar al usuario de forma controlada.
// 4. Si todoo es correcto, delega el registro en el repositorio de autenticación
//    (_repositorio.registrarCliente), que se encarga de hablar con el backend.
// -----------------------------------------------------------------------------


// Caso de uso "registrar cliente": valida políticas mínimas y delega en el
// repositorio compartido de auth. La validación principal de pwd ya la hace
// el formulario, pero defensivamente protegemos el contrato del backend.
class RegistrarCliente {
  RegistrarCliente(this._repositorio);
  // Constructor que recibe una implementación de AuthRepositorio e inicializa el campo privado.

  final AuthRepositorio _repositorio;

  // Misma regex que el backend para mantener coherencia.
  static final _regexPwd = RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,72}$');// contraseña: entre 8 y 72 caracteres, al menos una mayúscula y un número.

  static final _regexEmail = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');// Expresión regular básica para validar el formato del correo electrónico.

  static final _regexTelefono = RegExp(r'^[0-9]{9,15}$'); // Expresión regular para teléfono: solo dígitos, entre 9 y 15 caracteres.


  Future<ResultadoAuth> ejecutar(DatosRegistro datos) async {
    // Métodos principal del caso de uso: ejecuta el registro de cliente.
    // Devuelve un ResultadoAuth (probablemente con info de sesión/token, etc.).

    if (datos.nombre.trim().isEmpty || datos.apellidos.trim().isEmpty) {
      // Valida que nombre y apellidos no estén vacíos (tras quitar espacios).
      throw ApiException(
        const FailureValidacion('Nombre y apellidos obligatorios', {}),
      );
      // Si están vacíos, lanza una excepción de validación con un mensaje descriptivo.
    }
    if (!_regexEmail.hasMatch(datos.correo.trim())) {
      throw ApiException(const FailureValidacion('Correo inválido', {}));
    }

    final telefono = datos.telefono?.trim();
    // Obtiene el teléfono, si no es null, y le aplica trim(). Si es null, se queda en null.



    if (telefono != null && telefono.isNotEmpty) {
      // Solo valida el teléfono si el usuario ha informado algo (no null y no vacío).
      if (!_regexTelefono.hasMatch(telefono)) {
        // Comprueba que el teléfono cumpla la regex (solo números y longitud válida).
        throw ApiException(
          const FailureValidacion(
            'El número de teléfono solo puede contener números',
            {},
          ),
        );
        // Si no cumple, lanza una excepción de validación con un mensaje específico.
      }
    }



    if (!_regexPwd.hasMatch(datos.password)) {
      throw ApiException(const FailureValidacion(
        'La contraseña debe tener entre 8 y 72 caracteres, una mayúscula y un número', {},
      ));
    }
    return _repositorio.registrarCliente(datos);
    // Si todas las validaciones pasan, delega en el repositorio para registrar al cliente.
    // Aquí se hace la llamada real al backend (API, base de datos, etc.).
  }
}
