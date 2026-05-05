// ============================================================================
// CASO DE USO: CrearEmpleado
// ============================================================================
//
// Este archivo define un "caso de uso". En Clean Architecture, un caso de uso
// representa una acción concreta que la aplicación puede realizar. En este caso:
// **dar de alta (crear) un nuevo empleado**.
//
// Este caso de uso:
//   1. Valida que los datos obligatorios no estén vacíos.
//   2. Si todo está correcto, delega la creación al repositorio.
//   3. Si falta algún dato, lanza una ApiException con un mensaje de validación.
//
// El caso de uso NO sabe cómo se hace la petición HTTP.
// Eso lo hace el repositorio. Aquí solo se controla la lógica del negocio.
// ============================================================================

import '../../../../../core/errors/api_exception.dart'; // Para lanzar errores controlados
import '../../../../../core/errors/failure.dart';        // Tipos de fallos (validación, servidor, etc.)
import '../entidades/empleado.dart';                    // Entidad de dominio Empleado
import '../repositorios/empleado_admin_repositorio.dart'; // Contrato del repositorio

// ---------------------------------------------------------------------------
// Clase CrearEmpleado
// ---------------------------------------------------------------------------
// Recibe un repositorio (inyección de dependencias) y expone un métodoo
// ejecutar() que valida los datos y luego llama al repositorio.
// ---------------------------------------------------------------------------
class CrearEmpleado {
  CrearEmpleado(this._repositorio);

  // Repositorio que sabe hablar con el backend
  final EmpleadoAdminRepositorio _repositorio;

  // -------------------------------------------------------------------------
  // ejecutar()
  // Recibe los datos del empleado y:
  //   - Valida que los campos obligatorios no estén vacíos.
  //   - Si falta algo, lanza un error de validación.
  //   - Si todoo está bien, llama al repositorio para crear el empleado.
  // -------------------------------------------------------------------------
  Future<Empleado> ejecutar(DatosEmpleado datos) async {
    // Validación defensiva: comprobamos que los campos obligatorios no estén vacíos.
    if (datos.nombre.trim().isEmpty ||
        datos.apellidos.trim().isEmpty ||
        datos.correo.trim().isEmpty ||
        (datos.passwordProvisional ?? '').isEmpty) {

      // Si algo está vacío, lanzamos una excepción con un mensaje claro.
      throw ApiException(
        const FailureValidacion(
          'Rellena todos los campos obligatorios',
          {}, // Aquí podrían ir detalles adicionales del error
        ),
      );
    }

    // Si todo está correcto, delegamos en el repositorio.
    return _repositorio.crear(datos);
  }
}
