import '../entidades/empleado.dart';
import '../repositorios/empleado_admin_repositorio.dart';

// ============================================================================
// CASO DE USO: EditarEmpleado
// ============================================================================
//
// Este archivo define un "caso de uso" cuyo objetivo es **editar los datos de
// un empleado existente**.
//
// En Clean Architecture, un caso de uso representa una acción del negocio.
// Aquí la acción es simple: actualizar los datos de un empleado.
//
// A diferencia del caso de uso "CrearEmpleado", aquí NO se valida la contraseña,
// porque en edición la contraseña es opcional. Si viene vacía o null, el backend
// mantiene la contraseña actual del empleado.
//
// Este caso de uso solo delega la operación al repositorio.
// ============================================================================

class EditarEmpleado {
  // El constructor recibe el repositorio que sabe comunicarse con el backend.
  EditarEmpleado(this._repositorio);

  // Repositorio que contiene los métodos HTTP (PUT en este caso).
  final EmpleadoAdminRepositorio _repositorio;

  // -------------------------------------------------------------------------
  // ejecutar()
  // Recibe:
  //   - id: el ID del empleado que queremos editar.
  //   - datos: los nuevos datos del empleado.
  //
  // No hace validaciones aquí porque:
  //   - La contraseña es opcional.
  //   - El backend o el repositorio pueden manejar validaciones adicionales.
  //
  // Simplemente llama al repositorio para hacer la petición PUT.
  // -------------------------------------------------------------------------
  Future<Empleado> ejecutar(int id, DatosEmpleado datos) {
    return _repositorio.editar(id, datos);
  }
}
