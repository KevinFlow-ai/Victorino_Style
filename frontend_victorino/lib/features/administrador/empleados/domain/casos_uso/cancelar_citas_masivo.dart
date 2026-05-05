import '../entidades/empleado.dart';
import '../repositorios/empleado_admin_repositorio.dart';

// ============================================================================
// CASO DE USO: CancelarCitasMasivo
// ============================================================================
//
// En arquitectura limpia (Clean Architecture), un "caso de uso" representa una
// acción específica que la aplicación puede ejecutar. Es decir, una operación
// concreta del negocio.
//
// Este caso de uso se encarga de: **cancelar todas las citas futuras de un
// empleado**.
//
// No sabe cómo se hace la cancelación (eso lo hace el repositorio).
// Solo sabe que debe pedirle al repositorio que lo haga.
//
// Esta clase es muy pequeña porque su único propósito es coordinar la acción.
// ============================================================================
class CancelarCitasMasivo {
  // El constructor recibe el repositorio que sabe hablar con el backend.
  // Esto se llama "inyección de dependencias".
  CancelarCitasMasivo(this._repositorio);

  // Guardamos el repositorio en una variable privada.
  final EmpleadoAdminRepositorio _repositorio;



  // --------------------------------------------------------------------------
  // ejecutar()
  // Llama al repositorio para cancelar las citas del empleado indicado.
  //
  // Devuelve un objeto ResumenCancelacionMasiva, que contiene información como:
  // - cuántas citas fueron canceladas
  // - si hubo errores
  // - etc.
  //
  // Este métodoo simplemente delega la acción al repositorio.
  // --------------------------------------------------------------------------

  Future<ResumenCancelacionMasiva> ejecutar(int idEmpleado) =>
      _repositorio.cancelarCitasFuturas(idEmpleado);
}
