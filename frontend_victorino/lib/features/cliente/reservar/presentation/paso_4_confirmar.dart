// Paso 4 del wizard: resumen + nota + botón "Confirmar reserva".
// Si está en modo edición, el texto del botón es "Guardar cambios".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/theme/app_colores.dart';
import '../../shared/application/catalogo_provider.dart';
import '../application/wizard_notifier.dart';

class Paso4Confirmar extends ConsumerStatefulWidget {
  const Paso4Confirmar({super.key});

  @override
  ConsumerState<Paso4Confirmar> createState() => _Paso4ConfirmarState();
}

class _Paso4ConfirmarState extends ConsumerState<Paso4Confirmar> {
  late final TextEditingController _notaCtrl;

  @override
  void initState() {
    super.initState();
    _notaCtrl = TextEditingController(
      text: ref.read(wizardNotifierProvider).datos.nota ?? '',
    );
  }

  @override
  void dispose() {
    _notaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(wizardNotifierProvider);
    final serviciosAsync = ref.watch(serviciosCatalogoProvider);
    final empleadosAsync = ref.watch(empleadosCatalogoProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Resumen de la reserva',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),

        // Fecha y hora.
        if (estado.datos.fecha != null && estado.datos.horaInicio != null)
          _FilaResumen(
            icono: Icons.calendar_today_outlined,
            titulo: DateFormat.yMMMMEEEEd('es').format(estado.datos.fecha!),
            subtitulo:
                'A las ${_corta(estado.datos.horaInicio!)}',
          ),

        // Empleado.
        empleadosAsync.maybeWhen(
          data: (lista) {
            final emp = estado.datos.idEmpleado == null
                ? null
                : lista.where((e) => e.idEmpleado == estado.datos.idEmpleado).firstOrNull;
            return _FilaResumen(
              icono: Icons.person_outline,
              titulo: emp != null
                  ? emp.nombreCompleto
                  : (estado.datos.cualquieraDisponible
                      ? 'Peluquero asignado al confirmar'
                      : 'Sin peluquero'),
              subtitulo: estado.datos.cualquieraDisponible
                  ? 'Has elegido "Cualquiera disponible"'
                  : null,
              fotoUrl: emp?.fotoUrl,
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),

        // Servicio.
        serviciosAsync.maybeWhen(
          data: (lista) {
            final s = estado.datos.idServicio == null
                ? null
                : lista.where((x) => x.idServicio == estado.datos.idServicio).firstOrNull;
            if (s == null) return const SizedBox.shrink();
            return _FilaResumen(
              icono: Icons.content_cut,
              titulo: s.nombre,
              subtitulo: '${s.duracionMinutos} min · ${s.precio.toStringAsFixed(2)} €',
              fotoUrl: s.fotoUrl,
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),

        const SizedBox(height: 12),
        // Nota.
        TextField(
          controller: _notaCtrl,
          maxLines: 3,
          maxLength: 280,
          decoration: const InputDecoration(
            labelText: 'Nota para el peluquero (opcional)',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) =>
              ref.read(wizardNotifierProvider.notifier).setNota(v),
        ),
        const SizedBox(height: 16),
        if (estado.modoEdicion)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Modo edición: los cambios sustituirán la reserva actual.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  String _corta(String hora) => hora.length >= 5 ? hora.substring(0, 5) : hora;
}

// ---- Helpers visuales ------------------------------------------------------

class _FilaResumen extends StatelessWidget {
  const _FilaResumen({
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentGlow),
      ),
      child: Row(
        children: [
          if (fotoUrl != null && fotoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                ApiEndpoints.urlImagen(fotoUrl),
                width: 44, height: 44, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(icono, color: AppColors.primary),
              ),
            )
          else
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentGlow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icono, color: AppColors.primary),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                if (subtitulo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitulo!,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
