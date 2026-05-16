// Diálogo que se muestra cuando el backend devuelve 409 con código
// CITA_MISMO_DIA / CITA_MISMA_SEMANA / CITA_MISMO_SERVICIO. Muestra el detalle
// de la cita existente y ofrece "Modificar" o "Cerrar".

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../core/theme/app_colores.dart';

// Devuelve un Future<int?> con el id de la cita existente si el usuario
// pulsa "Modificar"; null si cierra el diálogo.
Future<int?> mostrarDialogoCitaExistente(
    BuildContext context, FailureConflicto failure) {
  final detalles = failure.detalles;
  // Sin detalles estructurados → diálogo genérico.
  if (detalles == null) {
    return showDialog<int?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Conflicto'),
        content: Text(failure.mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  final codigo = failure.codigo ?? '';
  final idCitaExistente = (detalles['idCitaExistente'] as num?)?.toInt();
  final fechaStr = detalles['fechaCitaExistente'] as String?;
  final horaStr = detalles['horaCitaExistente'] as String?;
  final nombreServicio = detalles['nombreServicioExistente'] as String? ?? '';

  String mensaje;
  if (fechaStr != null && horaStr != null) {
    final fecha = DateTime.tryParse(fechaStr);
    final fechaTxt = fecha == null
        ? fechaStr
        : DateFormat.yMMMMEEEEd('es').format(fecha);
    final horaTxt = horaStr.length >= 5 ? horaStr.substring(0, 5) : horaStr;
    mensaje = switch (codigo) {
      'CITA_MISMO_DIA' =>
        'Ya tienes una cita el $fechaTxt a las $horaTxt. ¿Quieres modificar la existente?',
      'CITA_MISMA_SEMANA' =>
        'Esta semana ya tienes una cita el $fechaTxt a las $horaTxt. Solo se permite una por semana.',
      'CITA_MISMO_SERVICIO' => nombreServicio.isEmpty
          ? 'Ya tienes una cita activa con este mismo servicio el $fechaTxt.'
          : 'Ya tienes una cita activa de $nombreServicio el $fechaTxt. Cuando se complete podrás reservar otra.',
      _ => failure.mensaje,
    };
  } else {
    mensaje = failure.mensaje;
  }

  return showDialog<int?>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Conflicto con otra cita'),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, null),
          child: const Text('Cerrar'),
        ),
        if (idCitaExistente != null)
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, idCitaExistente),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Modificar esa cita'),
          ),
      ],
    ),
  );
}
