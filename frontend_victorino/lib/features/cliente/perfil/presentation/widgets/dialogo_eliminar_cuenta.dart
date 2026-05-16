// Diálogo de eliminación de cuenta. Doble confirmación + pwd actual.
// Devuelve el password como String si el usuario confirma; null en caso contrario.

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colores.dart';

Future<String?> mostrarDialogoEliminarCuenta(BuildContext context) async {
  // Primer paso: explicación de las consecuencias.
  final confirmadoPrimero = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('¿Eliminar tu cuenta?'),
      content: const Text(
        'Esta acción es IRREVERSIBLE.\n\n'
        '• Tus citas futuras se cancelarán automáticamente.\n'
        '• Tus datos personales se anonimizarán para cumplir el RGPD.\n'
        '• No podrás recuperar el acceso.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('No, mantener'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Sí, eliminar'),
        ),
      ],
    ),
  );
  if (confirmadoPrimero != true) return null;
  if (!context.mounted) return null;

  // Segundo paso: pedir la contraseña actual como confirmación final.
  final pwdCtrl = TextEditingController();
  String? error;
  final password = await showDialog<String?>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Confirma tu contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Introduce tu contraseña para confirmar la eliminación de la cuenta.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pwdCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña actual',
                border: const OutlineInputBorder(),
                errorText: error,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (pwdCtrl.text.isEmpty) {
                setState(() => error = 'La contraseña es obligatoria');
                return;
              }
              Navigator.pop(ctx, pwdCtrl.text);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar definitivamente'),
          ),
        ],
      ),
    ),
  );

  return password;
}
