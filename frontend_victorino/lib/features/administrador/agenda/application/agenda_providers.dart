// Providers del submódulo agenda.
// Este archivo define todos los providers y notifiers necesarios para manejar
// la agenda del administrador: citas, filtros, avisos, historial, etc.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/providers/dio_provider.dart';
import '../data/repositorios/agenda_admin_repositorio_impl.dart';
import '../domain/casos_uso/casos_uso_agenda.dart';
import '../domain/entidades/cita.dart';
import '../domain/repositorios/agenda_admin_repositorio.dart';


// -----------------------------------------------------------------------------
// REPOSITORIO PRINCIPAL DE AGENDA
// -----------------------------------------------------------------------------
// Crea una instancia del repositorio AgendaAdminRepositorioImpl, que usa Dio
// para comunicarse con el backend. Este repositorio es la capa de infraestructura.
final agendaRepositorioProvider = Provider<AgendaAdminRepositorio>((ref) {
  return AgendaAdminRepositorioImpl(dio: ref.read(dioProvider));
});


// -----------------------------------------------------------------------------
// PROVIDERS DE CASOS DE USO (USE CASES)
// -----------------------------------------------------------------------------
// Cada uno de estos providers expone un caso de uso del dominio.
// La UI o los notifiers pueden leerlos para ejecutar lógica de negocio.

final obtenerAgendaProvider =
Provider((ref) => ObtenerAgendaGlobal(ref.read(agendaRepositorioProvider)));

final obtenerHistorialClienteProvider =
Provider((ref) => ObtenerHistorialCliente(ref.read(agendaRepositorioProvider)));

final crearWalkInProvider =
Provider((ref) => CrearWalkIn(ref.read(agendaRepositorioProvider)));

final obtenerAvisosProvider =
Provider((ref) => ObtenerAvisosCancelaciones(ref.read(agendaRepositorioProvider)));


// -----------------------------------------------------------------------------
// ESTADO LOCAL: FILTROS DE LA AGENDA
// -----------------------------------------------------------------------------
// Esta clase representa los filtros aplicados a la agenda global:
// - fecha seleccionada
// - empleado seleccionado
// - estado de la cita
class FiltrosAgenda {
  const FiltrosAgenda({required this.fecha, this.idEmpleado, this.estado});

  final DateTime fecha;
  final int? idEmpleado;
  final EstadoCita? estado;

  // Método copy() para actualizar solo algunos campos sin perder los demás.
  FiltrosAgenda copy({
    DateTime? fecha,
    int? idEmpleado,
    EstadoCita? estado,
    bool resetEmpleado = false,
    bool resetEstado = false,
  }) {
    return FiltrosAgenda(
      fecha: fecha ?? this.fecha,
      idEmpleado: resetEmpleado ? null : (idEmpleado ?? this.idEmpleado),
      estado: resetEstado ? null : (estado ?? this.estado),
    );
  }
}


// -----------------------------------------------------------------------------
// NOTIFIER PARA MANEJAR LOS FILTROS
// -----------------------------------------------------------------------------
// Riverpod 3 ya no usa StateProvider para objetos complejos, así que se usa Notifier.
// Este notifier mantiene el estado actual de los filtros.
class FiltrosAgendaNotifier extends Notifier<FiltrosAgenda> {
  @override
  FiltrosAgenda build() => FiltrosAgenda(fecha: DateTime.now());

  // Permite reemplazar completamente los filtros.
  void establecer(FiltrosAgenda nuevo) => state = nuevo;
}

// Provider asociado al notifier de filtros.
final filtrosAgendaProvider =
NotifierProvider<FiltrosAgendaNotifier, FiltrosAgenda>(FiltrosAgendaNotifier.new);


// -----------------------------------------------------------------------------
// NOTIFIER PRINCIPAL: CARGA LA AGENDA DEL ADMIN
// -----------------------------------------------------------------------------
// Este notifier es asíncrono porque carga datos desde el backend.
// Observa los filtros y cada vez que cambian, vuelve a cargar la agenda.
class AgendaAdminNotifier extends AsyncNotifier<List<CitaAdmin>> {
  @override
  Future<List<CitaAdmin>> build() async {
    // Lee los filtros actuales.
    final f = ref.watch(filtrosAgendaProvider);

    // Convierte la fecha a formato ISO (yyyy-MM-dd).
    final iso = DateFormat('yyyy-MM-dd').format(f.fecha);

    // Ejecuta el caso de uso para obtener la agenda.
    return ref.read(obtenerAgendaProvider).ejecutar(
      desde: iso,
      hasta: iso,
      idEmpleado: f.idEmpleado,
      estado: f.estado,
    );
  }

  // Método para recargar manualmente la agenda.
  Future<void> recargar() async {
    // Indica que está cargando.
    state = const AsyncLoading();

    // Ejecuta la carga protegida con AsyncValue.guard (maneja errores automáticamente).
    state = await AsyncValue.guard(() async {
      final f = ref.read(filtrosAgendaProvider);
      final iso = DateFormat('yyyy-MM-dd').format(f.fecha);

      return ref.read(obtenerAgendaProvider).ejecutar(
        desde: iso,
        hasta: iso,
        idEmpleado: f.idEmpleado,
        estado: f.estado,
      );
    });
  }
}

// Provider asociado al notifier de agenda.
final agendaAdminNotifierProvider =
AsyncNotifierProvider<AgendaAdminNotifier, List<CitaAdmin>>(AgendaAdminNotifier.new);


// -----------------------------------------------------------------------------
// NOTIFIER PARA AVISOS DE CANCELACIONES
// -----------------------------------------------------------------------------
// Carga los avisos que deben mostrarse al administrador.
class AvisosNotifier extends AsyncNotifier<List<AvisoCliente>> {
  @override
  Future<List<AvisoCliente>> build() =>
      ref.read(obtenerAvisosProvider).ejecutar();

  // Permite recargar manualmente los avisos.
  Future<void> recargar() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
          () => ref.read(obtenerAvisosProvider).ejecutar(),
    );
  }
}

// Provider asociado al notifier de avisos.
final avisosNotifierProvider =
AsyncNotifierProvider<AvisosNotifier, List<AvisoCliente>>(AvisosNotifier.new);

