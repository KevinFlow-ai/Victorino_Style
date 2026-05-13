import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entidades/notificacion.dart';

// Tarjeta de una sola notificación en la bandeja.
// Al pulsar, se llama onTap (que dispara marcarComoLeida desde el notifier).
class NotificacionCard extends StatelessWidget {
  const NotificacionCard({
    super.key,
    required this.notificacion,
    required this.onTap,
  });

  final Notificacion notificacion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esLeida = notificacion.esLeida;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: esLeida ? 0 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: esLeida
          ? theme.colorScheme.surface
          : theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono según el tipo.
              _icono(context, notificacion.tipo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila título + fecha.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notificacion.titulo,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: esLeida
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatearFecha(notificacion.fechaCreacion),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notificacion.cuerpo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Punto indicador si no está leída.
              if (!esLeida)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 6),
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _icono(BuildContext context, String tipo) {
    final color = Theme.of(context).colorScheme.primary;
    IconData icono;
    switch (tipo) {
      case 'CONFIRMACION_RESERVA':
        icono = Icons.event_available_rounded;
        break;
      case 'RECORDATORIO_24H':
        icono = Icons.alarm_rounded;
        break;
      case 'CANCELACION_CLIENTE':
        icono = Icons.event_busy_rounded;
        break;
      case 'CANCELACION_PELUQUERIA':
        icono = Icons.cancel_schedule_send_rounded;
        break;
      case 'NUEVA_CITA_EMPLEADO':
        icono = Icons.person_add_alt_1_rounded;
        break;
      case 'CONTRASENA_ACTUALIZADA':
        icono = Icons.lock_reset_rounded;
        break;
      default:
        icono = Icons.notifications_rounded;
    }
    return Icon(icono, color: color, size: 26);
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);
    if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} min';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} h';
    } else {
      return DateFormat('dd/MM', 'es').format(fecha);
    }
  }
}

