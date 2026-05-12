import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/theme/app_colores.dart';
import '../application/servicios_providers.dart';
import 'widgets/servicio_card.dart';

class ListaServiciosScreen extends ConsumerWidget {
  const ListaServiciosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(serviciosAdminNotifierProvider);
    final notifier = ref.read(serviciosAdminNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Gestión de servicios',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.textMain)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          await context.push('/admin/servicios/nuevo');
          await notifier.recargar();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo servicio'),
      ),
      body: estado.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(e is Failure ? e.mensaje : 'No se pudieron cargar los servicios'),
          ),
        ),
        data: (lista) => RefreshIndicator(
          onRefresh: () => notifier.recargar(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Switch(
                    value: notifier.incluirInactivos,
                    activeThumbColor: AppColors.primary,
                    onChanged: notifier.alternarInactivos,
                  ),
                  const Text('Incluir servicios dados de baja'),
                ],
              ),
              if (lista.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('No hay servicios para mostrar.')),
                )
              else
                ...lista.map((s) => ServicioCard(
                      servicio: s,
                      alEditar: () async {
                        await context.push('/admin/servicios/${s.id}/editar');
                        await notifier.recargar();
                      },
                      alDarBaja: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Dar de baja servicio'),
                            content: Text('Se ocultará "${s.nombre}" del catálogo. Las citas pasadas se conservan.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancelar')),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Dar de baja'),
                              ),
                            ],
                          ),
                        );
                        if (ok != true || !context.mounted) return;
                        try {
                          await ref.read(darBajaServicioProvider).ejecutar(s.id);
                          await notifier.recargar();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${s.nombre} dado de baja')),
                            );
                          }
                        } catch (err) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $err')),
                            );
                          }
                        }
                      },
                    )),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
