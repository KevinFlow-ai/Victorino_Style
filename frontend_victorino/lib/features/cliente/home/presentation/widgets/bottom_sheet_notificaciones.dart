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
              const SizedBox(height: 4),
              Divider(height: 1, color: AppColors.textMuted.withValues(alpha: 0.15)),
              const SizedBox(height: 4),
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

  static IconData _iconoPorTipo(String tipo) {
    switch (tipo) {
      case 'CONFIRMACION_RESERVA':
        return Icons.event_available_rounded;
      case 'RECORDATORIO_24H':
        return Icons.alarm_rounded;
      case 'CANCELACION_CLIENTE':
        return Icons.event_busy_rounded;
      case 'CANCELACION_PELUQUERIA':
        return Icons.cancel_schedule_send_rounded;
      case 'NUEVA_CITA_EMPLEADO':
        return Icons.person_add_alt_1_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);
    if (diferencia.inMinutes < 60) return 'Hace ${diferencia.inMinutes} min';
    if (diferencia.inHours < 24) return 'Hace ${diferencia.inHours} h';
    return DateFormat('d MMM', 'es').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    final esLeida = notificacion.esLeida;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: esLeida ? Colors.transparent : AppColors.accentGlow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(
                  color: esLeida
                      ? Colors.transparent
                      : AppColors.primary,
                  width: 3,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono contextual con fondo circular.
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: esLeida
                        ? AppColors.textMuted.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconoPorTipo(notificacion.tipo),
                    size: 20,
                    color: esLeida ? AppColors.textMuted : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                // Contenido textual.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notificacion.titulo,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: esLeida
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatearFecha(notificacion.fechaCreacion),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        notificacion.cuerpo,
                        style: TextStyle(
                          fontSize: 12,
                          color: esLeida
                              ? AppColors.textMuted
                              : AppColors.textMain.withValues(alpha: 0.75),
                          height: 1.4,
                        ),
                        maxLines: 3, // evita que mensajes largos rompan el layout.
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Punto indicador de no leída.
                if (!esLeida)
                  Padding(
                    padding: const EdgeInsets.only(left: 6, top: 2),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
