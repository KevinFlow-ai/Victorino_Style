// Card de un servicio destacado del Home (vertical, ancho completo).

/ La imagen se renderiza con el widget compartido `FotoServicio`, que detecta
// dinámicamente el aspect ratio real subido por el admin (1:1, 16:9, 4:3…).
// Si el admin cambia el recorte de la foto en su panel, esta card lo reflejará
// automáticamente la próxima vez que se recargue el catálogo: no hay que tocar
// nada en el código del cliente.
//
// IMPORTANTE: solo el HOME usa esta card. El wizard de reserva mantiene su
// propia mini-imagen cuadrada porque las cards del wizard son más compactas.





// Diseño: imagen con gradiente oscuro superpuesto. El nombre del servicio
// aparece en blanco sobre el degradado. Precio y duración como chips flotantes.
// La descripción se muestra en una franja limpia debajo de la imagen.
//
// La foto sigue usando `FotoServicio` para respetar el aspect ratio real del admin.
// IMPORTANTE: solo el HOME usa esta card.

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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.09),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Imagen + overlays ──────────────────────────────
              Stack(
                children: [
                  // Foto del servicio (aspect ratio dinámico del admin).
                  FotoServicio(url: servicio.fotoUrl, borderRadius: 0),

                  // Gradiente oscuro en la mitad inferior.
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.30, 1.0],
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.72),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Chip de duración — esquina superior izquierda.
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Transform.scale(
                      scale: 1.2, // aumenta todoo el chip
                      child: _ChipOscuro(
                        icono: Icons.schedule_rounded,
                        texto: '${servicio.duracionMinutos} min',
                      ),
                    ),
                  )
                  ,

                  // Badge de precio — esquina superior derecha.
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${servicio.precio.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                  // Nombre del servicio sobre el gradiente.
                  Positioned(
                    bottom: 14,
                    left: 14,
                    right: 14,
                    child: Text(
                      servicio.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Descripción + CTA ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        (servicio.descripcion != null &&
                                servicio.descripcion!.isNotEmpty)
                            ? servicio.descripcion!
                            : 'Toca para ver los detalles y reservar.',
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: (servicio.descripcion != null &&
                                  servicio.descripcion!.isNotEmpty)
                              ? AppColors.textMuted
                              : AppColors.textMuted.withValues(alpha: 0.7),
                          fontSize: 13,
                          height: 1.5,
                          fontStyle: (servicio.descripcion == null ||
                                  servicio.descripcion!.isEmpty)
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Chip semitransparente oscuro para superponer sobre la imagen.
class _ChipOscuro extends StatelessWidget {
  const _ChipOscuro({required this.icono, required this.texto});
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
