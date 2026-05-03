// Caso de uso "iniciar sesión": orquesta la validación mínima y delega en el
// repositorio. Mantiene la lógica de presentación fuera de la UI.
import '../../../../core/errors/api_exception.dart';
import '../../../../core/errors/failure.dart';
import '../entidades/credenciales.dart';
import '../repositorios/auth_repositorio.dart';

class IniciarSesion {
  IniciarSesion(this._repositorio);

  final AuthRepositorio _repositorio;

  // Lanza ApiException(Failure) si algo falla, retorna ResultadoAuth si OK.
  Future<ResultadoAuth> ejecutar(Credenciales credenciales) async {
    // Validación mínima de seguridad: el formulario de la UI ya valida formato,
    // pero defensivamente comprobamos que no vengan vacíos.
    if (credenciales.correo.trim().isEmpty || credenciales.password.isEmpty) {
      throw ApiException(const FailureValidacion(
        'Rellena correo y contraseña', {},
      ));
    }
    return _repositorio.iniciarSesion(credenciales);
  }
}
