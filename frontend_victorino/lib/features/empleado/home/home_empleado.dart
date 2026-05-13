// Home placeholder del empleado. Pendiente de implementar agenda diaria/semanal/mensual.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colores.dart';
import '../../../shared/providers/sesion_provider.dart';

import '../../../core/widgets_compartidos/campana_notificaciones_widget.dart';

class HomeEmpleado extends ConsumerWidget {
  const HomeEmpleado({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Empleado${sesion != null ? ' · ${sesion.nombreCompleto}' : ''}'),
        actions: [
          // Campana de notificaciones in-app con badge de no leídas.
          const CampanaNotificacionesWidget(), // ******** ICONO DE NOTIFICACIONES
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(sesionProvider.notifier).cerrarSesion();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Home Empleado',
              style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí irá la agenda con las citas asignadas.',
              style: GoogleFonts.roboto(fontSize: 16, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
