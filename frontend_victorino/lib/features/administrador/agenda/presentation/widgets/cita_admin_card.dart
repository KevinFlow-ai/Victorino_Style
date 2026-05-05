// Tarjeta de cita para la agenda global del admin.
// -------------------------------------------------------------
// Este widget representa visualmente una cita (CitaAdmin) dentro de la agenda.
// Muestra:
// - Hora de inicio y fin
// - Nombre del cliente (y si es Walk-in)
// - Servicio y empleado
// - Nota (si existe)
// - Un chip con el estado de la cita
// - Un borde lateral coloreado según el estado

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colores.dart';
import '../../domain/entidades/cita.dart';

class CitaAdminCard extends StatelessWidget {
  const CitaAdminCard({super.key, required this.cita});
  final CitaAdmin cita; // La cita que se va a mostrar en la tarjeta

  @override
  Widget build(BuildContext context) {
    // Color según el estado de la cita (confirmada, cancelada, etc.)
    final color = _colorEstado(cita.estado);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),

        // Borde lateral izquierdo coloreado según el estado
        border: Border(left: BorderSide(color: color, width: 4)),

        // Sombra suave para elevar la tarjeta
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      // Contenido principal de la tarjeta
      child: Row(
        children: [
          // Bloque con la hora de inicio y fin
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${cita.horaInicio} - ${cita.horaFin}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Información principal de la cita
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre del cliente + indicador si es Walk-in
                Text(
                  '${cita.nombreCliente}${cita.esInvitado ? "  ·  Walk-in" : ""}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),

                // Servicio y empleado
                Text(
                  '${cita.nombreServicio} · ${cita.nombreEmpleado}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),

                // Nota (si existe)
                if (cita.nota != null && cita.nota!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '“${cita.nota}”',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Chip con el estado de la cita
          _Chip(estado: cita.estado),
        ],
      ),
    );
  }

  // Devuelve un color según el estado de la cita
  static Color _colorEstado(EstadoCita e) {
    switch (e) {
      case EstadoCita.confirmada:
        return AppColors.primary;
      case EstadoCita.enProceso:
        return Colors.orange;
      case EstadoCita.completada:
        return Colors.green;
      case EstadoCita.canceladaCliente:
      case EstadoCita.canceladaPeluqueria:
      case EstadoCita.noPresentado:
        return AppColors.error;
    }
  }
}


// -----------------------------------------------------------------------------
// CHIP DE ESTADO
// -----------------------------------------------------------------------------
// Pequeño indicador visual que muestra el estado de la cita en texto corto.
class _Chip extends StatelessWidget {
  const _Chip({required this.estado});
  final EstadoCita estado;

  @override
  Widget build(BuildContext context) {
    // Texto según el estado
    final texto = switch (estado) {
      EstadoCita.confirmada => 'CONFIRMADA',
      EstadoCita.enProceso => 'EN CURSO',
      EstadoCita.completada => 'OK',
      EstadoCita.canceladaCliente => 'CANC. CLIENTE',
      EstadoCita.canceladaPeluqueria => 'CANC. PELUQ.',
      EstadoCita.noPresentado => 'NO PRES.',
    };

    // Color según el estado
    final color = CitaAdminCard._colorEstado(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
