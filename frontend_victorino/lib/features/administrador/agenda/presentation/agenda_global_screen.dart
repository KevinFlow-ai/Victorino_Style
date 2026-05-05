// Agenda global del administrador. Muestra las citas del día seleccionado
// con filtros opcionales por empleado y estado. Inspirada en
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/theme/app_colores.dart';
import '../../empleados/application/empleados_providers.dart';
import '../application/agenda_providers.dart';
import '../domain/entidades/cita.dart';
import 'widgets/cita_admin_card.dart';

class AgendaGlobalScreen extends ConsumerWidget {
  const AgendaGlobalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtros = ref.watch(filtrosAgendaProvider);
    final estado = ref.watch(agendaAdminNotifierProvider);
    final empleadosState = ref.watch(empleadosAdminNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Agenda',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.textMain)),
        actions: [
          IconButton(
            tooltip: 'Avisos',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/admin/avisos'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/admin/walk-in'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva cita'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat.yMMMMEEEEd('es').format(filtros.fecha),
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month, size: 16),
                      label: const Text('Cambiar fecha'),
                      onPressed: () async {
                        final f = await showDatePicker(
                          context: context,
                          initialDate: filtros.fecha,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        if (f == null) return;
                        ref.read(filtrosAgendaProvider.notifier)
                            .establecer(filtros.copy(fecha: f));
                        await ref.read(agendaAdminNotifierProvider.notifier).recargar();
                      },
                    ),
                    empleadosState.maybeWhen(
                      orElse: () => const SizedBox.shrink(),
                      data: (lista) => DropdownButton<int?>(
                        value: filtros.idEmpleado,
                        hint: const Text('Todos los empleados'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Todos los empleados')),
                          ...lista.where((e) => e.activo).map(
                                (e) => DropdownMenuItem(value: e.id, child: Text(e.nombreCompleto)),
                              ),
                        ],
                        onChanged: (v) async {
                          ref.read(filtrosAgendaProvider.notifier).establecer(
                              filtros.copy(idEmpleado: v, resetEmpleado: v == null));
                          await ref.read(agendaAdminNotifierProvider.notifier).recargar();
                        },
                      ),
                    ),
                    DropdownButton<EstadoCita?>(
                      value: filtros.estado,
                      hint: const Text('Cualquier estado'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Cualquier estado')),
                        ...EstadoCita.values.map(
                          (e) => DropdownMenuItem(value: e, child: Text(_etiquetaEstado(e))),
                        ),
                      ],
                      onChanged: (v) async {
                        ref.read(filtrosAgendaProvider.notifier).establecer(
                            filtros.copy(estado: v, resetEstado: v == null));
                        await ref.read(agendaAdminNotifierProvider.notifier).recargar();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: estado.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(e is Failure ? e.mensaje : 'No se pudo cargar la agenda'),
                ),
              ),
              data: (citas) => RefreshIndicator(
                onRefresh: () => ref.read(agendaAdminNotifierProvider.notifier).recargar(),
                child: citas.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 80),
                        Center(child: Text('No hay citas para esta fecha.')),
                      ])
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          ...citas.map((c) => CitaAdminCard(cita: c)),
                          const SizedBox(height: 80),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _etiquetaEstado(EstadoCita e) {
    switch (e) {
      case EstadoCita.confirmada: return 'Confirmada';
      case EstadoCita.enProceso: return 'En curso';
      case EstadoCita.completada: return 'Completada';
      case EstadoCita.canceladaCliente: return 'Cancelada (cliente)';
      case EstadoCita.canceladaPeluqueria: return 'Cancelada (peluquería)';
      case EstadoCita.noPresentado: return 'No presentado';
    }
  }
}
