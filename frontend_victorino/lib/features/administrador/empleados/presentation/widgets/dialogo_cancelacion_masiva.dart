// Diálogo de confirmación de cancelación masiva de citas futuras.
// Aparece desde la pantalla de detalle del empleado o la sección "Mass Incidents" de Negocio.
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colores.dart';

Future<bool?> mostrarDialogoCancelacionMasiva(BuildContext context, String nombreEmpleado) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cancelar todas las citas futuras'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Empleado: $nombreEmpleado',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          const Text(
            'Esto cancelará TODAS sus citas confirmadas a partir de ahora '
            'y notificará a cada cliente para que vuelva a reservar.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Esta acción no se puede deshacer.',
            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Cancelar todas'),
        ),
      ],
    ),
  );
}
