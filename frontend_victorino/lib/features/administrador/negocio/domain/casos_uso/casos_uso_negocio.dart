// Casos de uso del submódulo "negocio". Son orquestadores muy finos sobre el
// repositorio: validan parámetros mínimos y delegan. Se agrupan en un único
// archivo para reducir ruido (todos pertenecen al mismo dominio).
import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/errors/failure.dart';
import '../entidades/horario_peluqueria.dart';
import '../repositorios/negocio_admin_repositorio.dart';


// ============================================================================
// INTRODUCCIÓN
// ============================================================================
//
// Este archivo contiene los "Casos de Uso" del dominio "negocio".
//
// En Clean Architecture, un "Caso de Uso":
//
//   - Representa una acción concreta del negocio.
//   - Es la forma oficial de pedirle algo al dominio.
//   - No sabe nada de HTTP, ni de la UI, ni de Riverpod.
//   - Solo sabe hablar con el repositorio.
//
// Los casos de uso son "orquestadores finos":
//   - Validan parámetros mínimos.
//   - Llaman al repositorio.
//   - Devuelven entidades limpias.
//
// DIAGRAMA:
//
//   UI → Notifier → Caso de Uso → Repositorio → API
//
// Este archivo agrupa todos los casos de uso del dominio "negocio" para
// mantener el proyecto más ordenado.
//


// ============================================================================
// CASO DE USO: ObtenerHorario
// ============================================================================
//
// Este caso de uso simplemente pide al repositorio que obtenga el horario.
// No hace validaciones porque no hay parámetros.
//
class ObtenerHorario {
  ObtenerHorario(this._r);
  final NegocioAdminRepositorio _r;

  Future<HorarioPeluqueria> ejecutar() => _r.obtenerHorario();
}

// ============================================================================
// CASO DE USO: ActualizarHorario
// ============================================================================
//
// Recibe un objeto HorarioPeluqueria y lo envía al repositorio.
// No valida nada porque se asume que la UI ya controla los datos.
//
class ActualizarHorario {
  ActualizarHorario(this._r);
  final NegocioAdminRepositorio _r;

  Future<HorarioPeluqueria> ejecutar(HorarioPeluqueria h) =>
      _r.actualizarHorario(h);
}

// ============================================================================
// CASO DE USO: ActualizarDescanso
// ============================================================================
//
// Este caso de uso sí tiene validación:
//   - La duración del descanso debe estar entre 10 y 120 minutos.
//
// Si la validación falla, lanza ApiException con FailureValidacion.
// Esto permite que la UI muestre un mensaje adecuado.
//
class ActualizarDescanso {
  ActualizarDescanso(this._r);
  final NegocioAdminRepositorio _r;

  Future<DescansoEmpleado> ejecutar(
      int idEmpleado, String horaInicio, int duracionMinutos) {
    if (duracionMinutos < 10 || duracionMinutos > 120) {
      throw ApiException(const FailureValidacion(
        'La duración del descanso debe estar entre 10 y 120 minutos',
        {},
      ));
    }

    return _r.actualizarDescanso(idEmpleado, horaInicio, duracionMinutos);
  }
}

// ============================================================================
// CASO DE USO: ObtenerFestivos
// ============================================================================
//
// No requiere validaciones.
// Simplemente pide al repositorio la lista de festivos.
//
class ObtenerFestivos {
  ObtenerFestivos(this._r);
  final NegocioAdminRepositorio _r;

  Future<List<Festivo>> ejecutar() => _r.listarFestivos();
}

// ============================================================================
// CASO DE USO: CrearFestivo
// ============================================================================
//
// Este caso de uso valida que la descripción no esté vacía.
// Si está vacía, lanza ApiException con FailureValidacion.
//
class CrearFestivo {
  CrearFestivo(this._r);
  final NegocioAdminRepositorio _r;

  Future<Festivo> ejecutar(
      String fecha, String descripcion, TipoFestivo tipo) {
    if (descripcion.trim().isEmpty) {
      throw ApiException(const FailureValidacion(
        'La descripción del festivo es obligatoria',
        {},
      ));
    }

    return _r.crearFestivo(fecha, descripcion.trim(), tipo);
  }
}

// ============================================================================
// CASO DE USO: EliminarFestivo
// ============================================================================
//
// No requiere validaciones.
// Simplemente delega en el repositorio.
//
class EliminarFestivo {
  EliminarFestivo(this._r);
  final NegocioAdminRepositorio _r;

  Future<void> ejecutar(int id) => _r.eliminarFestivo(id);
}

// ============================================================================
// CASO DE USO: ObtenerCierreAnual
// ============================================================================
//
// No requiere validaciones.
// Pide al repositorio el cierre anual.
//
class ObtenerCierreAnual {
  ObtenerCierreAnual(this._r);
  final NegocioAdminRepositorio _r;

  Future<CierreAnual> ejecutar() => _r.obtenerCierreAnual();
}

// ============================================================================
// CASO DE USO: ActualizarCierreAnual
// ============================================================================
//
// Este caso de uso valida que:
//
//   - Si ambas fechas existen,
//   - La fecha de fin no sea anterior a la fecha de inicio.
//
// Si la validación falla, lanza ApiException con FailureValidacion.
//
class ActualizarCierreAnual {
  ActualizarCierreAnual(this._r);
  final NegocioAdminRepositorio _r;

  Future<CierreAnual> ejecutar(String? fechaInicio, String? fechaFin) {
    if (fechaInicio != null &&
        fechaFin != null &&
        fechaFin.compareTo(fechaInicio) < 0) {
      throw ApiException(const FailureValidacion(
        'La fecha de fin debe ser igual o posterior al inicio',
        {},
      ));
    }

    return _r.actualizarCierreAnual(fechaInicio, fechaFin);
  }
}
