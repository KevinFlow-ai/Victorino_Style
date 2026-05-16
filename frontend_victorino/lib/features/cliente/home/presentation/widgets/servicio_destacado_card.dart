// Card de un servicio destacado del Home (vertical, ancho completo).
//
// La imagen se renderiza con el widget compartido `FotoServicio`, que detecta
// dinámicamente el aspect ratio real subido por el admin (1:1, 16:9, 4:3…).
// Si el admin cambia el recorte de la foto en su panel, esta card lo reflejará
// automáticamente la próxima vez que se recargue el catálogo: no hay que tocar
// nada en el código del cliente.
//
// IMPORTANTE: solo el HOME usa esta card. El wizard de reserva mantiene su
// propia mini-imagen cuadrada porque las cards del wizard son más compactas.

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colores.dart';
import '../../../../../core/widgets_compartidos/foto_servicio.dart';
import '../../../shared/domain/entidades/servicio_publico.dart';

class ServicioDestacadoCard extends StatelessWidget {
  const ServicioDestacadoCard({
    super.key,
    required this.servicio,
    required this.onTap,
  });

  final ServicioPublico servicio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del servicio respetando el aspect ratio real del admin.
            // borderRadius coordinado con el de la propia card (solo arriba).
            _FotoConBordesSuperiores(url: servicio.fotoUrl),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre + precio en una fila.
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          servicio.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${servicio.precio.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Duración + CTA implícito.
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${servicio.duracionMinutos} min',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right,
                          color: AppColors.primary, size: 22),
                    ],
                  ),
                  // Descripción opcional.
                  if (servicio.descripcion != null &&
                      servicio.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      servicio.descripcion!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Wrapper que aplica el redondeo SOLO arriba (para que encaje con la card que
// la contiene). `FotoServicio` por defecto redondea las 4 esquinas; aquí lo
// envolvemos con un `ClipRRect` selectivo para tapar las inferiores.
class _FotoConBordesSuperiores extends StatelessWidget {
  const _FotoConBordesSuperiores({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      // borderRadius: 0 dentro del propio FotoServicio para que NO redondee de nuevo:
      // así el recorte exterior gana y las esquinas inferiores quedan rectas
      // (rectas porque la card las redondea con su Column).
      child: FotoServicio(url: url, borderRadius: 0),
    );
  }
}
