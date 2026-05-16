// Providers del submódulo Home del cliente.
// - AsyncNotifier de la próxima cita activa (puede ser null).
// - Reusa los providers compartidos de catálogo (servicios destacados).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reservar/domain/casos_uso/obtener_cita_activa.dart';
import '../../shared/application/citas_cliente_provider.dart';
import '../../shared/domain/entidades/cita_cliente.dart';

// Caso de uso: obtener cita activa. Inyecta el repositorio compartido.
final obtenerCitaActivaProvider = Provider<ObtenerCitaActiva>(
  (ref) => ObtenerCitaActiva(ref.read(citasClienteRepositorioProvider)),
);

// AsyncNotifier de la próxima cita activa. null si el cliente no tiene ninguna.
class ProximaCitaNotifier extends AsyncNotifier<CitaCliente?> {
  @override
  Future<CitaCliente?> build() async {
    return ref.read(obtenerCitaActivaProvider).ejecutar();
  }

  // Recarga al hacer pull-to-refresh o tras reservar/cancelar/modificar.
  Future<void> recargar() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(obtenerCitaActivaProvider).ejecutar(),
    );
  }
}

final proximaCitaProvider =
    AsyncNotifierProvider<ProximaCitaNotifier, CitaCliente?>(
  ProximaCitaNotifier.new,
);
