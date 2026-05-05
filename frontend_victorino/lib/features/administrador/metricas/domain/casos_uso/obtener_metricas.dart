import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/errors/failure.dart';
import '../entidades/metricas_resumen.dart';
import '../repositorios/metricas_repositorio.dart';



// ============================================================================
// CASO DE USO:
// ============================================================================
//
// En arquitectura limpia (Clean Architecture), un "caso de uso" representa una
// acción específica que la aplicación puede ejecutar. Es decir, una operación
// concreta del negocio.
//
// Este caso de uso se encarga de: **Obtener las metricas**.
//
// No sabe cómo se hace la cancelación (eso lo hace el repositorio).
// Solo sabe que debe pedirle al repositorio que lo haga.
//
// Esta clase es muy pequeña porque su único propósito es coordinar la acción.
// ============================================================================
class ObtenerMetricas {
  ObtenerMetricas(this._r);
  final MetricasRepositorio _r;

  Future<MetricasResumen> ejecutar({required String fechaInicio, required String fechaFin}) {
    if (fechaFin.compareTo(fechaInicio) < 0) {
      throw ApiException(const FailureValidacion(
        'La fecha de fin debe ser posterior o igual a la de inicio', {},
      ));
    }
    return _r.resumen(fechaInicio: fechaInicio, fechaFin: fechaFin);
  }
}
