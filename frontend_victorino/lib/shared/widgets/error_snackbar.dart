// Helper para mostrar un Failure como SnackBar con color según gravedad.
import 'package:flutter/material.dart';

import '../../core/errors/failure.dart';
import '../../core/theme/app_colores.dart';




// -----------------------------------------------------------------------------

// Determina el color del snackbar según el tipo de Failure recibido.
void mostrarErrorSnackbar(BuildContext context, Failure failure) {
  // Color según el tipo: rojo para credenciales/permiso, naranja para validación, gris para servidor.
  final Color color = switch (failure) {
    FailureCredenciales() || FailurePermiso() => AppColors.error, // Errores de credenciales o permisos → rojo.
    FailureConflicto() || FailureValidacion() => Colors.orange.shade700, // Errores de validación o conflicto → naranja.
    FailureRed() => Colors.grey.shade800, // Problemas de red → gris oscuro.
    FailureNoEncontrado() => Colors.grey.shade700, // Recurso no encontrado → gris medio.
    FailureServidor() => Colors.grey.shade900, // Error interno del servidor → gris muy oscuro.
  };





  // Muestra el snackbar.
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
  // Oculta cualquier snackbar previo para evitar acumulación.

    ..showSnackBar(
      SnackBar(
        content: Text(failure.mensaje),
        // Muestra el mensaje del Failure.

        backgroundColor: color,
        // Color determinado por el tipo de error.

        behavior: SnackBarBehavior.floating,
        // Hace que el snackbar flote sobre la UI.

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // Bordes redondeados para un estilo moderno.

        margin: const EdgeInsets.all(16),
        // Margen alrededor del snackbar.
      ),
    );
}



/*
RESUMEN DEL ARCHIVO
Este archivo define la función mostrarErrorSnackbar, que muestra un SnackBar
con un mensaje de error basado en un objeto Failure.

Su propósito es:

 1. Traducir un Failure a un color visual
Cada tipo de error (FailureCredenciales, FailureValidacion, FailureServidor, etc.) se muestra con un color distinto:

• Rojo → errores de credenciales o permisos
• Naranja → validaciones o conflictos
• Grises → errores de red, servidor o no encontrado

Esto ayuda al usuario a identificar rápidamente el tipo de error.

 2. Mostrar un SnackBar elegante y consistente

• Con bordes redondeados
• Flotante
• Con margen
• Con el mensaje del Failure

 3. Ser reutilizable en toda la app
Cualquier pantalla puede llamar a esta función para mostrar errores de forma uniforme.

 */