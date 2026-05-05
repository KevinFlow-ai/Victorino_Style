import '../entidades/metricas_resumen.dart';

abstract class MetricasRepositorio {
  Future<MetricasResumen> resumen({required String fechaInicio, required String fechaFin});
}
