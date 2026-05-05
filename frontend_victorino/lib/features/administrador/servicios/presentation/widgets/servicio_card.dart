// Card grande de servicio inspirada en `gestion_de_servicios_admin.jpeg`.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colores.dart';
import '../../domain/entidades/servicio.dart';

class ServicioCard extends StatelessWidget {
  const ServicioCard({
    super.key,
    required this.servicio,
    required this.alEditar,
    required this.alDarBaja,
  });

  final Servicio servicio;
  final VoidCallback alEditar;
  final VoidCallback alDarBaja;

  @override
  Widget build(BuildContext context) {
    final formatoEur = NumberFormat.currency(locale: 'es_ES', symbol: '€', decimalDigits: 0);
    final activo = servicio.activo;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: _foto(servicio.fotoUrl),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        servicio.nombre,
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Editar',
                      onPressed: alEditar,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                    IconButton(
                      tooltip: 'Dar de baja',
                      onPressed: activo ? alDarBaja : null,
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      formatoEur.format(servicio.precio),
                      style: GoogleFonts.poppins(
                          fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.schedule, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('${servicio.duracionMinutos} min',
                        style: const TextStyle(color: AppColors.textMuted)),
                    const Spacer(),
                    if (!activo)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('BAJA',
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.error)),
                      ),
                  ],
                ),
                if (servicio.descripcion != null && servicio.descripcion!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(servicio.descripcion!,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _foto(String url) {
    if (url.isEmpty) {
      return Container(
        color: AppColors.accentGlow,
        child: const Icon(Icons.image, size: 48, color: AppColors.primary),
      );
    }
    final completa = '${ApiEndpoints.baseUrl.replaceAll("/api/v1", "")}$url';
    return Image.network(
      completa,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: AppColors.accentGlow,
        child: const Icon(Icons.broken_image, size: 48, color: AppColors.primary),
      ),
    );
  }
}
