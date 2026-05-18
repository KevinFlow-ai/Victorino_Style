import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colores.dart';
import '../../../administrador/agenda/presentation/widgets/cita_admin_card.dart';
import '../application/perfil_empleado_providers.dart';

class HistorialClienteEmpleadoScreen extends ConsumerWidget {
  final int idCliente;

  const HistorialClienteEmpleadoScreen({
    super.key,
    required this.idCliente,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historialAsync = ref.watch(historialClienteConEmpleadoProvider(idCliente));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'HISTORIAL CLIENTE',
          style: GoogleFonts.poppins(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: historialAsync.when(
        data: (historial) {
          if (historial.citas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_rounded, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No hay citas previas contigo',
                    style: GoogleFonts.poppins(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera con info del cliente
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.accentGlow,
                      backgroundImage: historial.fotoUrl != null && historial.fotoUrl!.isNotEmpty
                          ? NetworkImage(historial.fotoUrl!)
                          : null,
                      child: historial.fotoUrl == null || historial.fotoUrl!.isEmpty
                          ? const Icon(Icons.person, color: AppColors.primary, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            historial.nombreCompleto,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),
                          Text(
                            '${historial.totalCitas} citas en total',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(
                  'TUS CITAS CON ESTE CLIENTE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: historial.citas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final cita = historial.citas[index];
                    return CitaAdminCard(cita: cita);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text('Error al cargar el historial', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () => ref.refresh(historialClienteConEmpleadoProvider(idCliente)),
                child: const Text('REINTENTAR'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
