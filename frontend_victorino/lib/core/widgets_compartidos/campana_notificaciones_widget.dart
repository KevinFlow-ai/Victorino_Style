// CampanaNotificacionesWidget
//
// Icono de campana con badge de notificaciones no leídas.
// Al pulsar, navega a /notificaciones (bandeja in-app).
//
// Se muestra en el AppBar de todas las pantallas principales
// (HomeCliente, HomeEmpleado, y cada pestaña del panel admin).
// Consume el notificacionesNotifierProvider para saber cuántas
// notificaciones no leídas hay y actualizar el badge en tiempo real.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/notificaciones/application/notificaciones_notifier.dart';

/// Icono de campana con badge numérico visible cuando hay notificaciones sin leer.
/// Uso: añadir al campo `actions` del AppBar de cualquier pantalla.
class CampanaNotificacionesWidget extends ConsumerWidget {
  const CampanaNotificacionesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observamos el provider completo para que el badge se actualice en tiempo real
    // cada vez que llega un push (el notifier recarga la bandeja).
    final bandejaAsync = ref.watch(notificacionesNotifierProvider);
    final noLeidas = bandejaAsync.value?.where((n) => !n.esLeida).length ?? 0;

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notificaciones',
          onPressed: () => context.push('/notificaciones'),
        ),
        if (noLeidas > 0)
          Positioned(
            top: 8,
            right: 8,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  noLeidas > 99 ? '99+' : '$noLeidas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

