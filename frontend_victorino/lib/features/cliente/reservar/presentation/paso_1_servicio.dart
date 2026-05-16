// Paso 1 del wizard: elegir SERVICIO. Lista vertical de cards con foto, nombre,
// descripción, duración y precio. Selección única; al elegir, se habilita "Siguiente".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/theme/app_colores.dart';
import '../../shared/application/catalogo_provider.dart';
import '../application/wizard_notifier.dart';

class Paso1Servicio extends ConsumerWidget {
  const Paso1Servicio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(wizardNotifierProvider);
    final serviciosAsync = ref.watch(serviciosCatalogoProvider);

    return serviciosAsync.when(
      data: (lista) {
        if (lista.isEmpty) {
          return const _Vacio('Aún no hay servicios disponibles.');
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: lista.length,
          itemBuilder: (_, i) {
            final s = lista[i];
            final seleccionado = estado.datos.idServicio == s.idServicio;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: seleccionado
                      ? AppColors.primary
                      : AppColors.accentGlow,
                  width: seleccionado ? 2 : 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () =>
                    ref.read(wizardNotifierProvider.notifier).setServicio(s.idServicio),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          ApiEndpoints.urlImagen(s.fotoUrl),
                          width: 80,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 70,
                            height: 70,
                            color: AppColors.accentGlow,
                            child: const Icon(Icons.content_cut,
                                color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            if (s.descripcion != null && s.descripcion!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  s.descripcion!,
                                  maxLines: 7,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.schedule,
                                    size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  '${s.duracionMinutos} min',
                                  style: const TextStyle(
                                      color: AppColors.textMuted, fontSize: 12),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${s.precio.toStringAsFixed(2)} €',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (seleccionado)
                        const Icon(Icons.check_circle,
                            color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const _Vacio('No se pudieron cargar los servicios.'),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio(this.mensaje);
  final String mensaje;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(mensaje,
            style: const TextStyle(color: AppColors.textMuted),
            textAlign: TextAlign.center),
      ),
    );
  }
}
