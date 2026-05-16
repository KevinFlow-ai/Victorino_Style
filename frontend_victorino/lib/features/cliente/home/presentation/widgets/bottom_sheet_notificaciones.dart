// Bottom sheet que se abre al pulsar la campana de la cabecera del Home.
// Contiene: switch para push, botón "marcar todas leídas" y la lista de notificaciones.
//
// La bandeja completa sigue accesible en /notificaciones (también es la que abre
// la campana del admin). Este bottom sheet es la vista rápida del cliente.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colores.dart';
import '../../../../notificaciones/application/notificaciones_notifier.dart';
import '../../../../notificaciones/application/notificaciones_providers.dart';
import '../../../../notificaciones/domain/entidades/notificacion.dart';
import '../../../perfil/application/perfil_providers.dart';

// Abre el bottom sheet desde el Home.
Future<void> mostrarBottomSheetNotificaciones(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _BottomSheetNotificaciones(),
  );
}

class _BottomSheetNotificaciones extends ConsumerWidget {
  const _BottomSheetNotificaciones();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(perfilNotifierProvider);
    final bandejaAsync = ref.watch(notificacionesNotifierProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Handle de arrastre.
              const SizedBox(height: 8),
              Container(
                width: 44, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Cabecera con título + cerrar.
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notificaciones',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              // Switch de push + botón marcar todas leídas.
              perfilAsync.when(
                data: (perfil) => _ConfiguracionRow(
                  pushActiva: perfil?.pushActiva ?? false,
                  onCambiarPush: (valor) => ref
                      .read(perfilNotifierProvider.notifier)
                      .configurarPush(valor),
                  onMarcarTodasLeidas: () async {
                    await ref.read(marcarTodasLeidasProvider).ejecutar();
                    await ref.read(notificacionesNotifierProvider.notifier).recargar();
                  },
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              // Lista de notificaciones.
              Expanded(
                child: bandejaAsync.when(
                  data: (lista) {
                    if (lista.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No tienes notificaciones',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: lista.length,
                      itemBuilder: (_, i) => _FilaNotificacion(
                        notificacion: lista[i],
                        onTap: () {
                          if (!lista[i].esLeida) {
                            ref
                                .read(notificacionesNotifierProvider.notifier)
                                .marcarComoLeida(lista[i].id);
                          }
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No se pudieron cargar las notificaciones',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConfiguracionRow extends StatelessWidget {
  const _ConfiguracionRow({
    required this.pushActiva,
    required this.onCambiarPush,
    required this.onMarcarTodasLeidas,
  });

  final bool pushActiva;
  final ValueChanged<bool> onCambiarPush;
  final VoidCallback onMarcarTodasLeidas;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.notifications_active_outlined,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Expanded(child: Text('Recibir notificaciones push')),
            Switch(value: pushActiva, onChanged: onCambiarPush),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onMarcarTodasLeidas,
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Marcar todas como leídas'),
          ),
        ),
      ],
    );
  }
}

class _FilaNotificacion extends StatelessWidget {
  const _FilaNotificacion({required this.notificacion, required this.onTap});

  final Notificacion notificacion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatoFecha = DateFormat('d MMM HH:mm', 'es');
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: notificacion.esLeida
              ? Colors.transparent
              : AppColors.accentGlow.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                notificacion.esLeida
                    ? Icons.mark_email_read_outlined
                    : Icons.fiber_manual_record,
                color: notificacion.esLeida
                    ? AppColors.textMuted
                    : AppColors.primary,
                size: 14,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notificacion.titulo,
                      style: TextStyle(
                        fontWeight: notificacion.esLeida
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notificacion.cuerpo,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatoFecha.format(notificacion.fechaCreacion),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
