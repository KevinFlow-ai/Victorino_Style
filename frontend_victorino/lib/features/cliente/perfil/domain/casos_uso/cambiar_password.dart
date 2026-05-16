// Caso de uso: cambiar la contraseña del cliente.
// Validación defensiva mínima; el backend valida con BCrypt y reglas de complejidad.

import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/errors/failure.dart';
import '../repositorios/perfil_repositorio.dart';

class CambiarPassword {
  CambiarPassword(this._repositorio);
  final PerfilRepositorio _repositorio;

  Future<void> ejecutar({required String actual, required String nueva}) async {
    if (actual.isEmpty || nueva.isEmpty) {
      throw ApiException(const FailureValidacion(
        'Introduce la contraseña actual y la nueva',
        {},
      ));
    }
    if (nueva.length < 8) {
      throw ApiException(const FailureValidacion(
        'La nueva contraseña debe tener al menos 8 caracteres',
        {},
      ));
    }
    return _repositorio.cambiarPassword(actual: actual, nueva: nueva);
  }
}
