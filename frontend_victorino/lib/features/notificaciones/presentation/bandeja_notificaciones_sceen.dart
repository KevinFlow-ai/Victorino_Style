import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/sesion_provider.dart';
import '../application/notificaciones_notifier.dart';
import 'widgets/notificacion_card.dart';

// Bandeja de notificaciones in-app. Accesible desde cualquier rol mediante la ruta /notificaciones.
class BandejaNotificacionesScreen extends ConsumerStatefulWidget {
  const BandejaNotificacionesScreen({super.key});

  @override
  ConsumerState<BandejaNotificacionesScreen> createState() =>
      _BandejaNotificacionesScreenState();
}

class _BandejaNotificacionesScreenState
    extends ConsumerState<BandejaNotificacionesScreen> {
  @override
  Widget build(BuildContext context) {
    final bandejaAsync = ref.watch(notificacionesNotifierProvider);
    final sesion = ref.watch(sesionProvider).value;
    final esAdmin = sesion?.rol == 'ADMINISTRADOR';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: () => ref
                .read(notificacionesNotifierProvider.notifier)
                .recargar(),
          ),
        ],
      ),
      // El FAB solo aparece para el administrador: permite enviar un aviso general.
      floatingActionButton: esAdmin
          ? FloatingActionButton.extended(
        onPressed: () => context.push('/admin/notificaciones/enviar'),
        icon: const Icon(Icons.send_outlined),
        label: const Text('Enviar aviso'),
        tooltip: 'Enviar aviso general a un usuario',
      )
          : null,
      body: bandejaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 10),
              Text(
                'No se pudieron cargar las notificaciones.\n$e',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => ref
                    .read(notificacionesNotifierProvider.notifier)
                    .recargar(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (lista) {
          if (lista.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Sin notificaciones',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref
                .read(notificacionesNotifierProvider.notifier)
                .recargar(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: lista.length,
              itemBuilder: (context, index) {
                final notif = lista[index];
                return NotificacionCard(
                  notificacion: notif,
                  onTap: () {
                    if (!notif.esLeida) {
                      ref
                          .read(notificacionesNotifierProvider.notifier)
                          .marcarComoLeida(notif.id);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
