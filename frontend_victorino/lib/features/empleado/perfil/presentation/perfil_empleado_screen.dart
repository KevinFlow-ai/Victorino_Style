import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colores.dart';
import '../../../../core/widgets_compartidos/avatar_empleado.dart';
import '../../../../shared/providers/sesion_provider.dart';
import '../application/perfil_empleado_providers.dart';
import '../domain/entidades/perfil_resumen_empleado.dart';

class PerfilEmpleadoScreen extends ConsumerWidget {
  const PerfilEmpleadoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider).value;
    final resumenAsync = ref.watch(perfilEmpleadoResumenProvider);

    if (sesion == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'MI PERFIL',
          style: GoogleFonts.poppins(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => ref.read(perfilEmpleadoResumenProvider.notifier).recargar(),
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
        ],
      ),
      body: resumenAsync.when(
        data: (resumen) => SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              // Avatar y Nombre
              Center(
                child: Column(
                  children: [
                    AvatarEmpleado(
                      url: resumen.fotoUrl ?? sesion.foto,
                      size: 140,
                      showBorder: true,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      resumen.nombreCompleto,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      'Empleado de Victorino Style',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // SECCIÓN DE ESTADÍSTICAS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _StatCard(
                      title: 'Citas',
                      value: '${resumen.citasCompletadas}',
                      subtitle: 'Citas completadas',
                      color: const Color(0xFF6B3FD4),
                      icon: Icons.check_circle_outline_rounded,
                    ),
                    const SizedBox(width: 15),
                    _StatCard(
                      title: 'Experiencia',
                      value: resumen.tiempoExperiencia,
                      subtitle: 'En el equipo',
                      color: const Color(0xFF0FA89B),
                      icon: Icons.history_rounded,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Opciones del perfil
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _OptionTile(
                      icon: Icons.lock_outline_rounded,
                      label: 'Cambiar Contraseña',
                      onTap: () {
                        context.push('/empleado/perfil/cambiar-pwd');
                      },
                    ),
                    /*
                    //BOTÓN MOSTRAR NOTIFICACIONES//
                    const SizedBox(height: 12),
                    _OptionTile(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notificaciones',
                      onTap: () {
                        context.push('/notificaciones');
                      },
                    ),
                    */
                    const SizedBox(height: 30),
                    // Botón Cerrar Sesión
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final confirmar = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Cerrar sesión'),
                              content: const Text('¿Estás seguro de que quieres salir?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('CANCELAR'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'SALIR',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirmar == true) {
                            await ref.read(sesionProvider.notifier).cerrarSesion();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.error,
                          elevation: 0,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded),
                        label: Text(
                          'CERRAR SESIÓN',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar perfil',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () => ref.read(perfilEmpleadoResumenProvider.notifier).recargar(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('REINTENTAR'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.15), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(
              value,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accentGlow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: AppColors.textMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
