// Pantalla de detalle de una cita del historial. Reusa el caso de uso obtenerDetalle.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/theme/app_colores.dart';
import '../../shared/application/refrescar_cliente.dart';
import '../../shared/domain/entidades/cita_cliente.dart';
import '../../shared/domain/entidades/estado_cita.dart';
import '../application/historial_providers.dart';

class DetalleCitaScreen extends ConsumerStatefulWidget {
  const DetalleCitaScreen({super.key, required this.idCita});

  final int idCita;

  @override
  ConsumerState<DetalleCitaScreen> createState() => _DetalleCitaScreenState();
}

class _DetalleCitaScreenState extends ConsumerState<DetalleCitaScreen> {
  late Future<CitaCliente> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = ref.read(obtenerDetalleCitaProvider).ejecutar(widget.idCita);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detalle de la cita')),
      body: FutureBuilder<CitaCliente>(
        future: _futuro,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return const Center(
              child: Text('No se pudo cargar la cita.',
                  style: TextStyle(color: AppColors.textMuted)),
            );
          }
          final c = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Servicio destacado.
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  ApiEndpoints.urlImagen(c.fotoServicio),
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 160,
                    color: AppColors.accentGlow,
                    child: const Icon(Icons.content_cut,
                        color: AppColors.primary, size: 40),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(c.nombreServicio,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                '${c.duracionMinutos} min · ${c.precioServicio.toStringAsFixed(2)} €',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),
              _FilaInfo(
                icono: Icons.event_outlined,
                titulo: DateFormat.yMMMMEEEEd('es').format(c.fecha),
                subtitulo: '${c.horaInicioCorta} – ${c.horaFinCorta}',
              ),
              _FilaInfo(
                icono: Icons.person_outline,
                titulo: c.nombreCompletoEmpleado,
                subtitulo: 'Tu peluquero',
                fotoUrl: c.fotoEmpleado,
              ),
              _FilaInfo(
                icono: Icons.flag_outlined,
                titulo: c.estado.etiqueta,
                subtitulo: 'Estado actual',
              ),
              if (c.nota != null && c.nota!.isNotEmpty)
                _FilaInfo(
                  icono: Icons.sticky_note_2_outlined,
                  titulo: c.nota!,
                  subtitulo: 'Tu nota',
                ),
              const SizedBox(height: 24),
              if (c.estado == EstadoCita.confirmada) ...[
                FilledButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modificar'),
                  onPressed: () => context.push(
                      '/cliente/reservar/wizard?idCita=${c.idCita}'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Cancelar cita'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  onPressed: () => _confirmarCancelacion(context, c.idCita),
                ),
              ],
              if (c.estado == EstadoCita.completada)
                FilledButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Repetir esta cita'),
                  onPressed: () => context.push(
                      '/cliente/reservar/wizard?idServicio=${c.idServicio}'),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmarCancelacion(BuildContext context, int idCita) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: const Text('¿Seguro que quieres cancelarla?'),
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
      await ref.read(cancelarCitaProvider).ejecutar(idCita);
      // Invalida próxima cita + historial para refrescar ambas vistas.
      invalidarCitasCliente(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cita cancelada')),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cancelar')),
        );
      }
    }
  }
}

class _FilaInfo extends StatelessWidget {
  const _FilaInfo({
    required this.icono,
    required this.titulo,
    this.subtitulo,
    this.fotoUrl,
  });
  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final String? fotoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentGlow),
      ),
      child: Row(
        children: [
          if (fotoUrl != null && fotoUrl!.isNotEmpty)
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.accentGlow,
              backgroundImage:
                  NetworkImage(ApiEndpoints.urlImagen(fotoUrl)),
              onBackgroundImageError: (_, _) {},
            )
          else
            Icon(icono, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                if (subtitulo != null)
                  Text(
                    subtitulo!,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
