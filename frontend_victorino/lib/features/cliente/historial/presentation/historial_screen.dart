// Pantalla principal del Historial del cliente.
// - Chips de filtro arriba.
// - Lista vertical de citas con pull-to-refresh.
// - Pulsar abre el detalle.
// - Si la cita está completada, botón "Repetir" (icono de refresco).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colores.dart';
import '../application/historial_providers.dart';
import 'widgets/cita_historial_card.dart';
import 'widgets/filtro_estado_chips.dart';

class HistorialScreen extends ConsumerWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historialAsync = ref.watch(historialNotifierProvider);
    final notifier = ref.read(historialNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi historial'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          FiltroEstadoChips(
            actual: notifier.filtroActual,
            onCambiar: notifier.cambiarFiltro,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: RefreshIndicator(
              onRefresh: notifier.recargar,
              child: historialAsync.when(
                data: (lista) {
                  if (lista.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No hay citas en este filtro.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: lista.length,
                    itemBuilder: (_, i) {
                      final c = lista[i];
                      return CitaHistorialCard(
                        cita: c,
                        onTap: () => context.push(
                          '/cliente/historial/detalle/${c.idCita}',
                        ),
                        onRepetir: () => context.push(
                          // "Repetir" → wizard con servicio precargado.
                          // El wizard salta al Paso 2 (peluquero) por defecto.
                          '/cliente/reservar/wizard?idServicio=${c.idServicio}',
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No pudimos cargar tu historial.',
                            style: TextStyle(color: AppColors.textMuted)),
                        TextButton(
                          onPressed: notifier.recargar,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
