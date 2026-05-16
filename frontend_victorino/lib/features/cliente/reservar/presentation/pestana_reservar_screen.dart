// Pantalla que ve el cliente al tocar la pestaña "Reservar" del bottom nav.
// Si ya tiene una cita activa, NO le dejamos iniciar el wizard: le mostramos
// un mensaje contextual con botones para modificar o cancelar la existente.
// Si no la tiene, abrimos el wizard.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colores.dart';
import '../../home/application/home_providers.dart';
import '../../home/presentation/widgets/card_proxima_cita.dart';
import '../../home/presentation/widgets/card_sin_cita.dart';
import '../../shared/application/citas_cliente_provider.dart';

class PestanaReservarScreen extends ConsumerWidget {
  const PestanaReservarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proximaCitaAsync = ref.watch(proximaCitaProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reservar'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(proximaCitaProvider.notifier).recargar(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            proximaCitaAsync.when(
              data: (cita) {
                if (cita == null) {
                  // Sin cita activa → call to action grande.
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: CardSinCita(
                      onReservar: () =>
                          context.push('/cliente/reservar/wizard'),
                    ),
                  );
                }
                // Con cita activa → bloqueo preventivo + card propia.
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.accentGlow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: AppColors.primary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ya tienes una cita activa. Modifícala o cancélala '
                                'para reservar otra distinta.',
                                style:
                                    TextStyle(color: AppColors.primary, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    CardProximaCita(
                      cita: cita,
                      onModificar: () => context
                          .push('/cliente/reservar/wizard?idCita=${cita.idCita}'),
                      onCancelar: () => _cancelar(context, ref, cita.idCita),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No se pudo comprobar tu próxima cita. Inténtalo de nuevo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelar(BuildContext context, WidgetRef ref, int idCita) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: const Text('¿Seguro que quieres cancelarla?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('No')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref.read(citasClienteRepositorioProvider).cancelar(idCita);
      await ref.read(proximaCitaProvider.notifier).recargar();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cita cancelada')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cancelar')),
        );
      }
    }
  }
}
