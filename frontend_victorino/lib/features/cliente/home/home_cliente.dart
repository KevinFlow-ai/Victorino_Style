// Home placeholder del cliente. Sirve para verificar el flujo de auth end-to-end.
// Las pantallas reales (calendario, reservas, perfil) se implementarán en otras tareas.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colores.dart';
import '../../../shared/providers/sesion_provider.dart';


import '../../../core/widgets_compartidos/campana_notificaciones_widget.dart';



class HomeCliente extends ConsumerWidget {
  const HomeCliente({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Bienvenido${sesion != null ? ', ${sesion.nombreCompleto}' : ''}'),
        actions: [
          // Campana de notificaciones in-app con badge de no leídas.
          const CampanaNotificacionesWidget(),
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
              'Home Cliente',
              style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí irán el calendario de reservas y el perfil.',
              style: GoogleFonts.roboto(fontSize: 16, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
