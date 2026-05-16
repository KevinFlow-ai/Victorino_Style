// Caso de uso: eliminar la cuenta del cliente (RGPD).
// El backend verifica la pwd, cancela citas futuras, anonimiza datos y devuelve 204.
// Tras llamar este caso de uso, el frontend debe cerrar sesión y navegar a /login.

import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/errors/failure.dart';
import '../repositorios/perfil_repositorio.dart';

class EliminarCuenta {
  EliminarCuenta(this._repositorio);
  final PerfilRepositorio _repositorio;

  Future<void> ejecutar(String password) async {
    if (password.isEmpty) {
      throw ApiException(const FailureValidacion(
        'Introduce tu contraseña para confirmar la eliminación',
        {},
      ));
    }
    return _repositorio.eliminarCuenta(password);
  }
}
