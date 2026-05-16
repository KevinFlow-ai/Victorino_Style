// Caso de uso: subir/reemplazar la foto del cliente.
// El archivo File llega del SelectorImagen.elegirYRecortar(formaCircular: true).

import 'dart:io';

import '../repositorios/perfil_repositorio.dart';

class SubirFoto {
  SubirFoto(this._repositorio);
  final PerfilRepositorio _repositorio;

  // Devuelve la nueva ruta relativa devuelta por el backend (ej. /uploads/cliente/abc.jpg).
  Future<String> ejecutar(File archivo) => _repositorio.subirFoto(archivo);
}
