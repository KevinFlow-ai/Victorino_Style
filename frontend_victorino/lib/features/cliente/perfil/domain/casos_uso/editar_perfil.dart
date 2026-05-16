// Caso de uso: editar nombre/apellidos/correo/teléfono del perfil.
// Validación defensiva: campos obligatorios no vacíos antes de llamar al backend.

import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/errors/failure.dart';
import '../entidades/perfil_cliente.dart';
import '../repositorios/perfil_repositorio.dart';

class EditarPerfil {
  EditarPerfil(this._repositorio);
  final PerfilRepositorio _repositorio;

  Future<PerfilCliente> ejecutar(DatosPerfilCliente datos) async {
    if (datos.nombre.trim().isEmpty ||
        datos.apellidos.trim().isEmpty ||
        datos.correo.trim().isEmpty) {
      throw ApiException(const FailureValidacion(
        'Rellena todos los campos obligatorios',
        {},
      ));
    }
    return _repositorio.editar(datos);
  }
}
