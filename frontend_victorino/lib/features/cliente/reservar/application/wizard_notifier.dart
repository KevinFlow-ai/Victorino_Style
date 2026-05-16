// ============================================================================
// WizardNotifier — estado global del wizard de 4 pasos
// ----------------------------------------------------------------------------
// Guarda en memoria los datos que el cliente va eligiendo:
//   Paso 1 → idServicio
//   Paso 2 → idEmpleado (null = "Cualquiera")
//   Paso 3 → fecha + horaInicio + cualquieraDisponible
//   Paso 4 → nota
// Y el paso actual (0..3).
//
// Usa el patrón Notifier de Riverpod (no AsyncNotifier porque el estado es síncrono).
// La pantalla del wizard escucha este provider para pintar la pestaña activa,
// habilitar el botón "Siguiente" y reaccionar a "Atrás".
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/domain/entidades/datos_reserva.dart';

class EstadoWizard {
  const EstadoWizard({
    required this.pasoActual,
    required this.datos,
    this.idCitaEditar,
  });

  // Paso actual: 0 servicio, 1 empleado, 2 día/hora, 3 confirmar.
  final int pasoActual;
  // Datos acumulados.
  final DatosReserva datos;
  // Si != null, el wizard está en modo EDICIÓN de una cita existente.
  final int? idCitaEditar;

  bool get modoEdicion => idCitaEditar != null;

  EstadoWizard copyWith({
    int? pasoActual,
    DatosReserva? datos,
    int? idCitaEditar,
  }) {
    return EstadoWizard(
      pasoActual: pasoActual ?? this.pasoActual,
      datos: datos ?? this.datos,
      idCitaEditar: idCitaEditar ?? this.idCitaEditar,
    );
  }
}

class WizardNotifier extends Notifier<EstadoWizard> {
  @override
  EstadoWizard build() =>
      const EstadoWizard(pasoActual: 0, datos: DatosReserva());

  // Reinicia el wizard antes de empezar uno nuevo.
  void reiniciar({int? idServicioPreseleccionado, int? idEmpleadoPreseleccionado, int? idCitaEditar}) {
    state = EstadoWizard(
      pasoActual: idServicioPreseleccionado != null ? 1 : 0,
      datos: DatosReserva(
        idServicio: idServicioPreseleccionado,
        idEmpleado: idEmpleadoPreseleccionado,
      ),
      idCitaEditar: idCitaEditar,
    );
  }

  // Precarga TODOS los pasos cuando entramos en modo edición desde el Home.
  // Salta al Paso 3 (día/hora) para que el cliente solo cambie lo que quiera.
  void precargarParaEdicion({
    required int idCita,
    required int idServicio,
    required int idEmpleado,
    required DateTime fecha,
    required String horaInicio,
    String? nota,
  }) {
    state = EstadoWizard(
      pasoActual: 2,
      idCitaEditar: idCita,
      datos: DatosReserva(
        idServicio: idServicio,
        idEmpleado: idEmpleado,
        fecha: fecha,
        horaInicio: horaInicio,
        nota: nota,
      ),
    );
  }

  // ----- Mutadores por paso ------------------------------------------------
  void setServicio(int idServicio) {
    state = state.copyWith(
      datos: state.datos.copyWith(idServicio: idServicio),
    );
  }

  void setEmpleado({int? idEmpleado, required bool cualquieraDisponible}) {
    state = state.copyWith(
      datos: state.datos.copyWith(
        idEmpleado: idEmpleado,
        limpiarEmpleado: idEmpleado == null && !cualquieraDisponible,
        cualquieraDisponible: cualquieraDisponible,
      ),
    );
  }

  void setFechaHora({
    required DateTime fecha,
    required String horaInicio,
    int? idEmpleadoFallback,
  }) {
    state = state.copyWith(
      datos: state.datos.copyWith(
        fecha: fecha,
        horaInicio: horaInicio,
        // Si veníamos de "Cualquiera", actualizamos el id del empleado que el
        // backend nos devolvió debajo del chip.
        idEmpleado: idEmpleadoFallback ?? state.datos.idEmpleado,
      ),
    );
  }

  void setNota(String? nota) {
    state = state.copyWith(
      datos: state.datos.copyWith(nota: nota),
    );
  }

  // ----- Navegación entre pasos -------------------------------------------
  void siguiente() {
    if (state.pasoActual < 3) {
      state = state.copyWith(pasoActual: state.pasoActual + 1);
    }
  }

  void anterior() {
    if (state.pasoActual > 0) {
      state = state.copyWith(pasoActual: state.pasoActual - 1);
    }
  }

  void irAlPaso(int paso) {
    if (paso < 0 || paso > 3) return;
    state = state.copyWith(pasoActual: paso);
  }
}

final wizardNotifierProvider = NotifierProvider<WizardNotifier, EstadoWizard>(
  WizardNotifier.new,
);
