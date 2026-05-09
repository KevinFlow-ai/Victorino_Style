// Tarjeta de empleado para la lista.
import 'package:flutter/material.dart';

import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colores.dart';
import '../../domain/entidades/empleado.dart';

class EmpleadoCard extends StatelessWidget {
  const EmpleadoCard({
    super.key,
    required this.empleado,
    required this.alEditar,
    required this.alDarBaja,
  });

  final Empleado empleado;
  final VoidCallback alEditar;
  final VoidCallback alDarBaja;

  @override
  Widget build(BuildContext context) {
    final activo = empleado.activo;
    final esAdmin = empleado.esAdministrador;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Foto circular grande, gris si está dado de baja.

          /*

          REMPLAZAR EL ClipOval, POR ESO, PARA QUE LA FOTO DE PERFIL
          SEA IGUAL QUE LA DE NUEVO EMPLEADO, AL CREAR EL EMPLEADO

          SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipOval(
                    child: ColorFiltered(
                      colorFilter: activo
                          ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                          : const ColorFilter.matrix(<double>[
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0,      0,      0,      1, 0,
                            ]),
                      child: empleado.fotoUrl.isEmpty
                          ? Container(
                              width: 56,
                              height: 56,
                              color: AppColors.accentGlow,
                              child: const Icon(Icons.person,
                                  color: AppColors.primary, size: 32),
                            )
                          : Image.network(
                              ApiEndpoints.urlImagen(empleado.fotoUrl),
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
                                color: AppColors.accentGlow,
                                child: const Icon(Icons.person,
                                    color: AppColors.primary, size: 32),
                              ),
                            ),
                    ),
                  ),

                  // Borde opcional (igual que en la pantalla de edición)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

           */



          ClipOval(
            child: ColorFiltered(
              colorFilter: activo
                  ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                  : const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0,      0,      0,      1, 0,
                    ]),
              child: _foto(empleado.fotoUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(empleado.nombreCompleto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(empleado.correo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                // Wrap con runSpacing 0 y badges un poco más compactos para que
                // dos badges quepan sin envolver dentro de la altura de la card.
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Badge(
                      texto: activo ? 'ACTIVO' : 'BAJA',
                      color: activo ? Colors.green : AppColors.error,
                    ),
                    if (esAdmin) const _Badge(texto: 'ADMIN', color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar',
            onPressed: alEditar,
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
          IconButton(
            tooltip: esAdmin ? 'No puedes dar de baja al admin' : 'Dar de baja',
            // Auto-protección visual: el admin no se puede dar de baja desde aquí.
            onPressed: esAdmin || !activo ? null : alDarBaja,
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _foto(String fotoUrl) {
    if (fotoUrl.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        color: AppColors.accentGlow,
        child: const Icon(Icons.person, color: AppColors.primary, size: 32),
      );
    }
    final url = ApiEndpoints.urlImagen(fotoUrl);
    return Image.network(
      url,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        width: 60,
        height: 60,
        color: AppColors.accentGlow,
        child: const Icon(Icons.person, color: AppColors.primary, size: 32),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.texto, required this.color});
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
