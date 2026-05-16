// Card del historial. Muestra fecha, hora, empleado, servicio y un chip
// con el estado coloreado. Si la cita está COMPLETADA, ofrece botón "Repetir"
// que abre el wizard con servicio + empleado precargados.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colores.dart';
import '../../../shared/domain/entidades/cita_cliente.dart';
import '../../../shared/domain/entidades/estado_cita.dart';

class CitaHistorialCard extends StatelessWidget {
  const CitaHistorialCard({
    super.key,
    required this.cita,
    required this.onTap,
    required this.onRepetir,
  });

  final CitaCliente cita;
  final VoidCallback onTap;
  // Solo se invoca si la cita es COMPLETADA. La pantalla pasa null si no aplica.
  final VoidCallback onRepetir;

  @override
  Widget build(BuildContext context) {
    final fechaTxt = DateFormat.yMMMMd('es').format(cita.fecha);
    final esCompletada = cita.estado == EstadoCita.completada;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accentGlow),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.accentGlow,
              backgroundImage:
                  NetworkImage(ApiEndpoints.urlImagen(cita.fotoEmpleado)),
              onBackgroundImageError: (_, _) {},
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cita.nombreServicio,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$fechaTxt · ${cita.horaInicioCorta}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Con ${cita.nombreCompletoEmpleado}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  _ChipEstado(estado: cita.estado),
                ],
              ),
            ),
            if (esCompletada)
              IconButton(
                tooltip: 'Repetir esta cita',
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                onPressed: onRepetir,
              ),
          ],
        ),
      ),
    );
  }
}

class _ChipEstado extends StatelessWidget {
  const _ChipEstado({required this.estado});
  final EstadoCita estado;

  @override
  Widget build(BuildContext context) {
    final color = switch (estado) {
      EstadoCita.confirmada => AppColors.primary,
      EstadoCita.enProceso => AppColors.secondary,
      EstadoCita.completada => Colors.green.shade600,
      EstadoCita.canceladaCliente || EstadoCita.canceladaPeluqueria => AppColors.error,
      EstadoCita.noPresentado => Colors.orange.shade700,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.etiqueta,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
