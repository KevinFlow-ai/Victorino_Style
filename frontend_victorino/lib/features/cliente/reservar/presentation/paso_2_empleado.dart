// Paso 2 del wizard: elegir PELUQUERO o "Cualquiera disponible".
// Grid de cards con foto, nombre. La opción "Cualquiera" siempre está la primera.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/theme/app_colores.dart';
import '../../shared/application/catalogo_provider.dart';
import '../application/wizard_notifier.dart';

class Paso2Empleado extends ConsumerWidget {
  const Paso2Empleado({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(wizardNotifierProvider);
    final empleadosAsync = ref.watch(empleadosCatalogoProvider);

    return empleadosAsync.when(
      data: (lista) {
        if (lista.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No hay peluqueros disponibles.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: lista.length + 1, // +1 por la opción "Cualquiera"
          itemBuilder: (_, i) {
            // 1ª tarjeta = Cualquiera disponible.
            if (i == 0) {
              final activo = estado.datos.cualquieraDisponible;
              return _CardSeleccionable(
                seleccionada: activo,
                onTap: () => ref.read(wizardNotifierProvider.notifier).setEmpleado(
                      idEmpleado: null,
                      cualquieraDisponible: true,
                    ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.accentGlow,
                      child: Icon(Icons.shuffle_rounded,
                          color: AppColors.primary, size: 32),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Cualquiera disponible',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Te asignamos peluquero',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              );
            }

            final emp = lista[i - 1];
            final activo = !estado.datos.cualquieraDisponible &&
                estado.datos.idEmpleado == emp.idEmpleado;

            return _CardSeleccionable(
              seleccionada: activo,
              onTap: () => ref.read(wizardNotifierProvider.notifier).setEmpleado(
                    idEmpleado: emp.idEmpleado,
                    cualquieraDisponible: false,
                  ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.accentGlow,
                    backgroundImage:
                        NetworkImage(ApiEndpoints.urlImagen(emp.fotoUrl)),
                    onBackgroundImageError: (_, _) {},
                  ),
                  const SizedBox(height: 10),
                  Text(
                    emp.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    emp.apellidos,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(
        child: Text('No se pudieron cargar los peluqueros.',
            style: TextStyle(color: AppColors.textMuted)),
      ),
    );
  }
}

class _CardSeleccionable extends StatelessWidget {
  const _CardSeleccionable({
    required this.seleccionada,
    required this.onTap,
    required this.child,
  });

  final bool seleccionada;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionada ? AppColors.primary : AppColors.accentGlow,
            width: seleccionada ? 2 : 1,
          ),
          boxShadow: seleccionada
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}
