// ============================================================================
// CASO DE USO: SubirFotoEmpleado
// ============================================================================
//
// Este caso de uso representa una acción muy concreta del negocio:
// **subir la foto de un empleado al servidor**.
//
// En Clean Architecture, los casos de uso NO saben cómo se hace la petición
// HTTP ni cómo se construye el FormData. Eso lo hace el repositorio.
//
// Aquí simplemente recibimos:
//   - el ID del empleado
//   - el archivo de imagen
//
// Y delegamos la operación al repositorio, que se encarga de:
//   - preparar el archivo
//   - enviarlo al backend
//   - recibir la URL de la foto subida
//
// Este caso de uso devuelve un String con la URL relativa de la nueva foto.
// ============================================================================

import 'dart:io'; // Necesario para manejar archivos (File)

import '../repositorios/empleado_admin_repositorio.dart'; // Contrato del repositorio

// ---------------------------------------------------------------------------
// Clase SubirFotoEmpleado
// ---------------------------------------------------------------------------
// Recibe un repositorio y expone un métodoo ejecutar() que simplemente delega
// la subida de la foto al repositorio.
// ---------------------------------------------------------------------------
class SubirFotoEmpleado {
  // Constructor: recibe el repositorio que sabe hablar con el backend.
  SubirFotoEmpleado(this._repositorio);

  // Repositorio que contiene la lógica HTTP real.
  final EmpleadoAdminRepositorio _repositorio;

  // -------------------------------------------------------------------------
  // ejecutar()
  // Recibe:
  //   - id: el ID del empleado al que pertenece la foto.
  //   - archivo: el archivo físico de la imagen.
  //
  // Devuelve:
  //   - Un String con la URL relativa de la foto subida.
  //
  // Este métodoo no hace validaciones ni manipula el archivo.
  // Solo delega la acción al repositorio.
  // -------------------------------------------------------------------------
  Future<String> ejecutar(int id, File archivo) =>
      _repositorio.subirFoto(id, archivo);
}

