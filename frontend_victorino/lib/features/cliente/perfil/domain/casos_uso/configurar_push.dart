// Caso de uso: activar o desactivar las notificaciones push del cliente.
// El switch del bottom sheet del Home y la sección de Configuración del Perfil lo invocan.

import '../repositorios/perfil_repositorio.dart';

class ConfigurarPush {
  ConfigurarPush(this._repositorio);
  final PerfilRepositorio _repositorio;

  Future<void> ejecutar(bool pushActiva) => _repositorio.configurarPush(pushActiva);
}
