// Dashboard de métricas del negocio.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/theme/app_colores.dart';
import '../application/metricas_providers.dart';
import 'widgets/grafica_estados_widget.dart';
import 'widgets/grafica_franjas_widget.dart';
import 'widgets/kpi_card_widget.dart';

class MetricasScreen extends ConsumerWidget {
  const MetricasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(metricasNotifierProvider);
    final rango = ref.watch(rangoFechasProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Estadísticas',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.textMain)),
      ),
      body: estado.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(e is Failure ? e.mensaje : 'No se pudieron cargar las métricas'),
          ),
        ),
        data: (m) => RefreshIndicator(
          onRefresh: () => ref.read(metricasNotifierProvider.notifier).recargar(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SelectorRango(rango: rango, ref: ref),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: [
                  KpiCardWidget(titulo: 'Citas totales', valor: m.totalCitas.toString(), icono: Icons.event),
                  KpiCardWidget(
                    titulo: 'Tasa asistencia',
                    valor: '${m.tasaAsistencia.toStringAsFixed(1)}%',
                    icono: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  KpiCardWidget(
                    titulo: 'Canceladas',
                    valor: m.citasCanceladas.toString(),
                    icono: Icons.cancel_outlined,
                    color: AppColors.error,
                  ),
                  KpiCardWidget(
                    titulo: 'No presentado',
                    valor: m.citasNoPresentado.toString(),
                    icono: Icons.person_off_outlined,
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GraficaEstadosWidget(
                completadas: m.citasCompletadas,
                canceladas: m.citasCanceladas,
                noPresentado: m.citasNoPresentado,
              ),
              const SizedBox(height: 16),
              GraficaFranjasWidget(datos: m.distribucionPorFranjaHoraria),
              const SizedBox(height: 16),
              if (m.servicioMasSolicitado != null)
                _RankingCard(
                  titulo: 'Servicio más solicitado',
                  icono: Icons.star_outline,
                  primario: m.servicioMasSolicitado!.nombre,
                  secundario: '${m.servicioMasSolicitado!.reservas} reservas',
                ),
              if (m.empleadoMasReservado != null) ...[
                const SizedBox(height: 8),
                _RankingCard(
                  titulo: 'Empleado más reservado',
                  icono: Icons.person_outline,
                  primario: m.empleadoMasReservado!.nombre,
                  secundario: '${m.empleadoMasReservado!.citasAtendidas} citas atendidas',
                ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectorRango extends StatelessWidget {
  const _SelectorRango({required this.rango, required this.ref});
  final RangoFechas rango;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${DateFormat.yMMMd("es").format(rango.inicio)}  →  ${DateFormat.yMMMd("es").format(rango.fin)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () async {
              final nuevo = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 30)),
                initialDateRange: DateTimeRange(start: rango.inicio, end: rango.fin),
              );
              if (nuevo == null) return;
              ref.read(rangoFechasProvider.notifier)
                  .establecer(RangoFechas(inicio: nuevo.start, fin: nuevo.end));
              await ref.read(metricasNotifierProvider.notifier).recargar();
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({
    required this.titulo,
    required this.icono,
    required this.primario,
    required this.secundario,
  });
  final String titulo;
  final IconData icono;
  final String primario;
  final String secundario;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accentGlow,
            child: Icon(icono, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Text(primario, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text(secundario, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
