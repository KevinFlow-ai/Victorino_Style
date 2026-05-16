// Caso de uso: cargar los datos del perfil del cliente autenticado.

import '../entidades/perfil_cliente.dart';
import '../repositorios/perfil_repositorio.dart';

class ObtenerPerfil {
  ObtenerPerfil(this._repositorio);
  final PerfilRepositorio _repositorio;

  Future<PerfilCliente> ejecutar() => _repositorio.obtener();
}
