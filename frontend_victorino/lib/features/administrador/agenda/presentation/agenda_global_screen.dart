// Agenda global del administrador con vista de cuadrícula temporal.
//
// Eje Y = horas del día (adaptadas al horario real de la peluquería).
// Eje X = una columna por empleado activo (con su foto y nombre).
// Cada cita se posiciona en su columna según hora inicio y duración.
// En los huecos libres aparece un "+" que abre un bottom-sheet rápido para
// crear un walk-in en esa franja.
//
// Si el día seleccionado está cerrado (festivo, vacaciones, mantenimiento,
// cierre anual o domingo sin horario), la cuadrícula se sustituye por un
// cartel a pantalla completa con el motivo.
//
// Todos los datos vienen de providers ya existentes (no hay lógica nueva en
// el backend):
//   - agendaAdminNotifierProvider     → citas del día
//   - empleadosAdminNotifierProvider  → columnas (foto, nombre, descanso)
//   - horarioNotifierProvider         → horario semanal
//   - festivosNotifierProvider        → festivos personalizados
//   - cierreAnualNotifierProvider     → periodo de cierre anual
//
// El encabezado de empleados se mantiene siempre sincronizado: cualquier
// alta, baja o edición de empleado dispara `ref.invalidate` sobre el provider
// de empleados, así que la cuadrícula se redibuja al instante.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/theme/app_colores.dart';
import '../../../../shared/providers/sesion_provider.dart';
import '../../empleados/application/empleados_providers.dart';
import '../../empleados/domain/entidades/empleado.dart';
import '../../negocio/application/negocio_providers.dart';
import '../../negocio/domain/entidades/horario_peluqueria.dart';
import '../application/agenda_providers.dart';
import '../domain/entidades/cita.dart';
import 'widgets/agenda_grid/agenda_grid.dart';
import 'widgets/agenda_grid/agenda_grid_helpers.dart';
import 'widgets/agenda_grid/bottom_sheet_crear_cita_rapida.dart';

class AgendaGlobalScreen extends ConsumerWidget {
  const AgendaGlobalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtros          = ref.watch(filtrosAgendaProvider);
    final citasState       = ref.watch(agendaAdminNotifierProvider);
    final empleadosState   = ref.watch(empleadosAdminNotifierProvider);
    final horarioState     = ref.watch(horarioNotifierProvider);
    final festivosState    = ref.watch(festivosNotifierProvider);
    final cierreAnualState = ref.watch(cierreAnualNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'AGENDA DIARIA',
          style: GoogleFonts.poppins(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Avisos',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/admin/avisos'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(sesionProvider.notifier).cerrarSesion();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Cabecera(
              fecha: filtros.fecha,
              onCambiarFecha: () => _abrirSelectorFecha(context, ref, filtros.fecha),
              onRefrescar: () => _refrescarTodo(ref),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _cuerpo(
                ref: ref,
                fecha: filtros.fecha,
                citasState: citasState,
                empleadosState: empleadosState,
                horarioState: horarioState,
                festivosState: festivosState,
                cierreAnualState: cierreAnualState,
                onHueco: (
                        {required int idEmpleado,
                        required String nombreEmpleado,
                        required DateTime fecha,
                        required String horaInicio,
                        required String horaFinHueco}) =>
                    _abrirBottomSheet(
                  context: context,
                  idEmpleado: idEmpleado,
                  nombreEmpleado: nombreEmpleado,
                  fecha: fecha,
                  horaInicio: horaInicio,
                  horaFinHueco: horaFinHueco,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Cuerpo de la pantalla ───────────────────────────

  // Combina los 5 AsyncValue. Loading si alguno carga; error si alguno falla.
  // Cuando todos están listos, decide si pintar el cartel de cerrado o la grid.
  Widget _cuerpo({
    required WidgetRef ref,
    required DateTime fecha,
    required AsyncValue<List<CitaAdmin>> citasState,
    required AsyncValue<List<Empleado>> empleadosState,
    required AsyncValue<HorarioPeluqueria> horarioState,
    required AsyncValue<List<Festivo>> festivosState,
    required AsyncValue<CierreAnual> cierreAnualState,
    required OnHuecoPulsado onHueco,
  }) {
    if (citasState.isLoading ||
        empleadosState.isLoading ||
        horarioState.isLoading ||
        festivosState.isLoading ||
        cierreAnualState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = citasState.error ??
        empleadosState.error ??
        horarioState.error ??
        festivosState.error ??
        cierreAnualState.error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(error is Failure ? error.mensaje : 'No se pudo cargar la agenda'),
        ),
      );
    }

    final motivo = motivoCierre(
      fecha: fecha,
      horario: horarioState.requireValue,
      festivos: festivosState.requireValue,
      cierreAnual: cierreAnualState.requireValue,
    );
    if (motivo != MotivoCierre.abierto) {
      return RefreshIndicator(
        onRefresh: () => _refrescarTodo(ref),
        child: ListView(
          // Necesario para que RefreshIndicator funcione con poco contenido.
          children: [
            SizedBox(
              height: MediaQuery.of(ref.context).size.height * 0.7,
              child: CartelCerrado(motivo: motivo),
            ),
          ],
        ),
      );
    }

    final rango = rangoDelDia(horarioState.requireValue, fecha)!;
    // En el caso "abierto" el grid ocupa TODOo el espacio del `Expanded`
    // padre y se adapta automáticamente al horario del día: si el día es
    // corto (10–13), el contenedor mide solo lo necesario y el scroll
    // interno del grid no genera espacio muerto al final.
    // El pull-to-refresh queda accesible por el botón refresh de la cabecera.
    if (empleadosState.requireValue.where((e) => e.activo).isEmpty) {
      return _SinEmpleados();
    }
    return AgendaGrid(
      fecha: fecha,
      rango: rango,
      empleados: empleadosState.requireValue,
      citas: citasState.requireValue,
      onHuecoPulsado: onHueco,
    );
  }

  // ─────────────────────────── Acciones ───────────────────────────

  Future<void> _abrirSelectorFecha(
      BuildContext context, WidgetRef ref, DateTime actual) async {
    final f = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 31)), // para cambiar la agenda como maximo
      locale: const Locale('es'),
    );
    if (f == null) return;
    final filtros = ref.read(filtrosAgendaProvider);
    ref.read(filtrosAgendaProvider.notifier).establecer(filtros.copy(fecha: f));
    await ref.read(agendaAdminNotifierProvider.notifier).recargar();
  }

  // Pull-to-refresh: fuerza recarga de los 5 providers que alimentan la
  // cuadrícula. Invalidar empleados garantiza que cualquier alta/edición
  // hecha en otra pantalla quede reflejada al instante.
  Future<void> _refrescarTodo(WidgetRef ref) async {
    ref.invalidate(empleadosAdminNotifierProvider);
    ref.invalidate(horarioNotifierProvider);
    ref.invalidate(festivosNotifierProvider);
    ref.invalidate(cierreAnualNotifierProvider);
    await ref.read(agendaAdminNotifierProvider.notifier).recargar();
  }

  Future<void> _abrirBottomSheet({
    required BuildContext context,
    required int idEmpleado,
    required String nombreEmpleado,
    required DateTime fecha,
    required String horaInicio,
    required String horaFinHueco,
  }) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BottomSheetCrearCitaRapida(
        idEmpleado: idEmpleado,
        nombreEmpleado: nombreEmpleado,
        fecha: fecha,
        horaInicio: horaInicio,
        horaFinHueco: horaFinHueco,
      ),
    );
  }
}

// ─────────────────────────── Cabecera (título + fecha) ───────────────────────────

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.fecha,
    required this.onCambiarFecha,
    required this.onRefrescar,
  });

  final DateTime fecha;
  final VoidCallback onCambiarFecha;
  final Future<void> Function() onRefrescar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const SizedBox(height: 6),
          Text(
            DateFormat.yMMMMEEEEd('es').format(fecha),
            style: GoogleFonts.poppins(
              color: AppColors.textMain,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: onCambiarFecha,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAEAEF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 15, color: AppColors.textMain),
                      const SizedBox(width: 8),
                      Text(
                        'Cambiar fecha',
                        style: GoogleFonts.poppins(
                          color: AppColors.textMain,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Refrescar',
                icon: const Icon(Icons.refresh),
                onPressed: onRefrescar,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SinEmpleados extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'No hay empleados activos. Da de alta al menos uno desde la pantalla de empleados.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
