// Contrato del repositorio de Perfil. Cubre todos los endpoints
// /cliente/perfil del backend.

import 'dart:io';

import '../entidades/perfil_cliente.dart';

abstract class PerfilRepositorio {
  // GET /cliente/perfil
  Future<PerfilCliente> obtener();

  // PUT /cliente/perfil
  Future<PerfilCliente> editar(DatosPerfilCliente datos);

  // POST /cliente/perfil/foto (multipart). Devuelve la nueva ruta relativa.
  Future<String> subirFoto(File archivo);

  // POST /cliente/perfil/cambiar-pwd. 204 si OK; 409 si la actual es incorrecta.
  Future<void> cambiarPassword({required String actual, required String nueva});

  // PUT /cliente/perfil/notificaciones {pushActiva: bool}.
  Future<void> configurarPush(bool pushActiva);

  // DELETE /cliente/perfil (body {password}). 204 si OK; 409 si pwd incorrecta.
  Future<void> eliminarCuenta(String password);
}
