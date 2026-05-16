// Providers del submódulo Historial del cliente.
// AsyncNotifier de la lista de citas con filtro de estado.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/application/citas_cliente_provider.dart';
import '../../shared/domain/entidades/cita_cliente.dart';
import '../../shared/domain/entidades/estado_cita.dart';
import '../domain/casos_uso/cancelar_cita.dart';
import '../domain/casos_uso/obtener_detalle_cita.dart';
import '../domain/casos_uso/obtener_historial.dart';

final obtenerHistorialProvider = Provider<ObtenerHistorial>(
  (ref) => ObtenerHistorial(ref.read(citasClienteRepositorioProvider)),
);

final obtenerDetalleCitaProvider = Provider<ObtenerDetalleCita>(
  (ref) => ObtenerDetalleCita(ref.read(citasClienteRepositorioProvider)),
);

final cancelarCitaProvider = Provider<CancelarCita>(
  (ref) => CancelarCita(ref.read(citasClienteRepositorioProvider)),
);

// AsyncNotifier del historial con filtro de estado. Si filtroActual es null,
// devuelve TODAS las citas. Cambiar el filtro recarga la lista.
class HistorialNotifier extends AsyncNotifier<List<CitaCliente>> {
  EstadoCita? _filtroActual;

  EstadoCita? get filtroActual => _filtroActual;

  @override
  Future<List<CitaCliente>> build() async {
    return ref.read(obtenerHistorialProvider).ejecutar(estado: _filtroActual);
  }

  Future<void> recargar() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(obtenerHistorialProvider).ejecutar(estado: _filtroActual),
    );
  }

  Future<void> cambiarFiltro(EstadoCita? nuevo) async {
    _filtroActual = nuevo;
    await recargar();
  }
}

final historialNotifierProvider =
    AsyncNotifierProvider<HistorialNotifier, List<CitaCliente>>(
  HistorialNotifier.new,
);
