// Pantalla principal del submódulo "Negocio". Es un scroll vertical con cinco
// secciones: horario semanal, descansos, cancelación masiva, festivos y cierre anual.
// Inspirada en el mockup `gestion_peluqueria_admin.jpeg`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colores.dart';
import 'secciones/seccion_cancelacion_masiva_widget.dart';
import 'secciones/seccion_cierre_anual_widget.dart';
import 'secciones/seccion_descansos_widget.dart';
import 'secciones/seccion_festivos_widget.dart';
import 'secciones/seccion_horario_widget.dart';

class NegocioScreen extends ConsumerWidget {
  const NegocioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Configuración del negocio',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.textMain)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: const [
          SeccionHorarioWidget(),
          SeccionDescansosWidget(),
          SeccionCancelacionMasivaWidget(),
          SeccionFestivosWidget(),
          SeccionCierreAnualWidget(),
          SizedBox(height: 80),
        ],
      ),
    );
  }
}
