// Home del cliente. Estructura vertical:
//   - Cabecera con saludo + campana
//   - Mi próxima cita (o CTA "Reservar ahora")
//   - Servicios destacados (lista horizontal, conectado al catálogo del admin)
//
// Pull-to-refresh recarga catálogo + próxima cita + bandeja.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colores.dart';
import '../../../notificaciones/application/notificaciones_notifier.dart';
import '../../shared/application/catalogo_provider.dart';
import '../../shared/application/citas_cliente_provider.dart';
import '../../shared/application/refrescar_cliente.dart';
import '../application/home_providers.dart';
import 'widgets/cabecera_home.dart';
import 'widgets/card_proxima_cita.dart';
import 'widgets/card_sin_cita.dart';
import 'widgets/servicio_destacado_card.dart';

class HomeClienteScreen extends ConsumerWidget {
  const HomeClienteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proximaCitaAsync = ref.watch(proximaCitaProvider);
    final serviciosAsync = ref.watch(serviciosCatalogoProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(serviciosCatalogoProvider);
            ref.invalidate(empleadosCatalogoProvider);
            await ref.read(proximaCitaProvider.notifier).recargar();
            await ref.read(notificacionesNotifierProvider.notifier).recargar();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const CabeceraHome(),

              // --- Próxima cita / CTA ----------------------------
              proximaCitaAsync.when(
                data: (cita) => cita == null
                    ? CardSinCita(
                        onReservar: () => context.push('/cliente/reservar/wizard'),
                      )
                    : CardProximaCita(
                        cita: cita,
                        onModificar: () => context.push(
                          '/cliente/reservar/wizard?idCita=${cita.idCita}',
                        ),
                        onCancelar: () => _confirmarCancelacion(context, ref, cita.idCita),
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _Error(
                  mensaje: 'No pudimos cargar tu próxima cita',
                  onReintentar: () =>
                      ref.read(proximaCitaProvider.notifier).recargar(),
                ),
              ),

              // --- Servicios destacados --------------------------
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Servicios destacados',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              serviciosAsync.when(
                data: (servicios) {
                  if (servicios.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Todavía no hay servicios publicados.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    );
                  }
                  // Lista vertical. Como el Home ya está dentro de un ListView
                  // exterior, usamos shrinkWrap + physics.NeverScrollable para
                  // que esta lista interna no compita por el scroll.
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: servicios.length,
                    itemBuilder: (_, i) => ServicioDestacadoCard(
                      servicio: servicios[i],
                      onTap: () => context.push(
                        '/cliente/reservar/wizard?idServicio=${servicios[i].idServicio}',
                      ),
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _Error(
                  mensaje: 'No pudimos cargar el catálogo',
                  onReintentar: () =>
                      ref.invalidate(serviciosCatalogoProvider),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarCancelacion(
      BuildContext context, WidgetRef ref, int idCita) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: const Text(
            '¿Seguro que quieres cancelar tu próxima cita? El peluquero recibirá un aviso automático.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref
          .read(citasClienteRepositorioProvider)
          .cancelar(idCita);
      // Invalida próxima cita + historial para refrescar ambas vistas.
      invalidarCitasCliente(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cita cancelada correctamente')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cancelar la cita, inténtalo de nuevo'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// Mensaje de error genérico con botón reintentar.
class _Error extends StatelessWidget {
  const _Error({required this.mensaje, required this.onReintentar});
  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.textMuted),
          const SizedBox(height: 6),
          Text(mensaje, style: const TextStyle(color: AppColors.textMuted)),
          TextButton(
            onPressed: onReintentar,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
