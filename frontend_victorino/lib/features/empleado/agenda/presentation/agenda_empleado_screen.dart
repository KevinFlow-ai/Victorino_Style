import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/theme/app_colores.dart';
import '../../../../core/widgets_compartidos/campana_notificaciones_widget.dart';
import '../../../../shared/providers/sesion_provider.dart';
import '../../../administrador/agenda/application/agenda_providers.dart';
import '../../../administrador/agenda/domain/entidades/cita.dart';
import '../../../administrador/agenda/presentation/widgets/agenda_grid/agenda_grid.dart';
import '../../../administrador/agenda/presentation/widgets/agenda_grid/agenda_grid_helpers.dart';
import '../../../administrador/agenda/presentation/widgets/agenda_grid/bottom_sheet_crear_cita_rapida.dart';
import '../../../administrador/negocio/application/negocio_providers.dart';
import '../../../administrador/negocio/domain/entidades/horario_peluqueria.dart';
import '../../../administrador/empleados/domain/entidades/empleado.dart';

class AgendaEmpleadoScreen extends ConsumerWidget {
  const AgendaEmpleadoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider).value;
    final filtros = ref.watch(filtrosAgendaProvider);
    final horarioState = ref.watch(horarioNotifierProvider);
    final festivosState = ref.watch(festivosNotifierProvider);
    final cierreAnualState = ref.watch(cierreAnualNotifierProvider);
    final citasState = ref.watch(agendaAdminNotifierProvider);

    if (sesion == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: Text(
          'MI AGENDA',
          style: GoogleFonts.poppins(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        actions: [
          const CampanaNotificacionesWidget(),
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: AppColors.textMain),
            onPressed: () async {
              await ref.read(sesionProvider.notifier).cerrarSesion();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _CabeceraFecha(
              fecha: filtros.fecha,
              onCambiarFecha: () =>
                  _seleccionarFecha(context, ref, filtros.fecha),
            ),
            const SizedBox(height: 4), // Un pequeño respiro antes de la agenda
            Expanded(
              child: _CuerpoAgenda(
                sesion: sesion,
                fecha: filtros.fecha,
                citasState: citasState,
                horarioState: horarioState,
                festivosState: festivosState,
                cierreAnualState: cierreAnualState,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarFecha(
      BuildContext context,
      WidgetRef ref,
      DateTime actual,
      ) async {
    final f = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      locale: const Locale('es'),
    );

    if (f != null) {
      ref
          .read(filtrosAgendaProvider.notifier)
          .establecer(ref.read(filtrosAgendaProvider).copy(fecha: f));
    }
  }
}

class _CuerpoAgenda extends ConsumerWidget {
  const _CuerpoAgenda({
    required this.sesion,
    required this.fecha,
    required this.citasState,
    required this.horarioState,
    required this.festivosState,
    required this.cierreAnualState,
  });

  final dynamic sesion;
  final DateTime fecha;
  final AsyncValue<List<CitaAdmin>> citasState;
  final AsyncValue<HorarioPeluqueria> horarioState;
  final AsyncValue<List<Festivo>> festivosState;
  final AsyncValue<CierreAnual> cierreAnualState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (horarioState.isLoading || citasState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = horarioState.error ?? citasState.error;

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 54,
              ),
              const SizedBox(height: 16),
              Text(
                error is Failure ? error.mensaje : 'Error: $error',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(horarioNotifierProvider);
                  ref.invalidate(festivosNotifierProvider);
                  ref.invalidate(cierreAnualNotifierProvider);
                  ref.read(agendaAdminNotifierProvider.notifier).recargar();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final horario = horarioState.value;

    if (horario == null) {
      return const Center(child: Text('No hay datos de horario'));
    }

    final motivo = motivoCierre(
      fecha: fecha,
      horario: horario,
      festivos: festivosState.value ?? [],
      cierreAnual: cierreAnualState.value,
    );

    if (motivo != MotivoCierre.abierto) {
      return CartelCerrado(motivo: motivo);
    }

    final rango = rangoDelDia(horario, fecha);

    if (rango == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Cálculo del ancho dinámico:
        // constraints.maxWidth es el ancho total de la pantalla.
        // - 24: Márgenes horizontales del contenedor del grid (12 + 12).
        // - 56: Ancho de la columna de horas fija (_kAnchoColHoras).
        // - 8: Márgenes horizontales internos de la columna del empleado (4 + 4).
        final anchoCalculado = constraints.maxWidth - 24 - 56 - 8;

        final todasLasCitas = citasState.value ?? [];

        final citasEmpleado = todasLasCitas
            .where((c) => c.idEmpleado == sesion.idUsuario)
            .toList();

        final partesNombre = sesion.nombreCompleto.trim().split(' ');
        final nombre = partesNombre.isNotEmpty ? partesNombre.first : '';
        final apellidos = partesNombre.length > 1
            ? partesNombre.sublist(1).join(' ')
            : '';

        final empleado = Empleado(
          id: sesion.idUsuario,
          nombre: nombre,
          apellidos: apellidos,
          correo: '',
          telefono: '',
          fotoUrl: sesion.foto ?? '',
          activo: true,
          esAdministrador: false,
          horaDescanso: null,
          duracionDescansoMinutos: null,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AgendaGrid(
            fecha: fecha,
            rango: rango,
            empleados: [empleado],
            citas: citasEmpleado,
            anchoColumna: anchoCalculado, // Aplicamos el ancho calculado aquí
            onHuecoPulsado: ({
              required int idEmpleado,
              required String nombreEmpleado,
              required DateTime fecha,
              required String horaInicio,
              required String horaFinHueco,
            }) {
              _abrirBottomSheet(
                context: context,
                idEmpleado: idEmpleado,
                nombreEmpleado: nombreEmpleado,
                fecha: fecha,
                horaInicio: horaInicio,
                horaFinHueco: horaFinHueco,
              );
            },
          ),
        );
      },
    );
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

class _CabeceraFecha extends StatelessWidget {
  const _CabeceraFecha({required this.fecha, required this.onCambiarFecha});

  final DateTime fecha;
  final VoidCallback onCambiarFecha;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 10, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              DateFormat.yMMMMEEEEd('es').format(fecha).toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
                letterSpacing: 0.5,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            onPressed: onCambiarFecha,
          ),
        ],
      ),
    );
  }
}