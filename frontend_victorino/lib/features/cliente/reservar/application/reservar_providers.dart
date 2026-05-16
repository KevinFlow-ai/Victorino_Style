// Providers del submódulo Reservar (wizard). Inyecta el repositorio compartido
// de citas y los casos de uso específicos del wizard.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/application/citas_cliente_provider.dart';
import '../domain/casos_uso/crear_cita.dart';
import '../domain/casos_uso/modificar_cita.dart';
import '../domain/casos_uso/obtener_cita_activa.dart';
import '../domain/casos_uso/obtener_disponibilidad.dart';

final obtenerDisponibilidadProvider = Provider<ObtenerDisponibilidad>(
  (ref) => ObtenerDisponibilidad(ref.read(citasClienteRepositorioProvider)),
);

final crearCitaProvider = Provider<CrearCita>(
  (ref) => CrearCita(ref.read(citasClienteRepositorioProvider)),
);

final modificarCitaProvider = Provider<ModificarCita>(
  (ref) => ModificarCita(ref.read(citasClienteRepositorioProvider)),
);

// Reusable también desde el submódulo Reservar (lo usa la pestaña con bloqueo preventivo).
final obtenerCitaActivaReservarProvider = Provider<ObtenerCitaActiva>(
  (ref) => ObtenerCitaActiva(ref.read(citasClienteRepositorioProvider)),
);
