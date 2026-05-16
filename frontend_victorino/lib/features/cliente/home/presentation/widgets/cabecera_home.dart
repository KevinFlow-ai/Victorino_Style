// Cabecera del Home: saludo + nombre + campana de notificaciones (con badge).
// Pulsar la campana abre el bottom_sheet_notificaciones.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colores.dart';
import '../../../../notificaciones/application/notificaciones_notifier.dart';
import '../../../perfil/application/perfil_providers.dart';
import 'bottom_sheet_notificaciones.dart';

class CabeceraHome extends ConsumerWidget {
  const CabeceraHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(perfilNotifierProvider);
    final bandejaAsync = ref.watch(notificacionesNotifierProvider);
    final noLeidas = bandejaAsync.value?.where((n) => !n.esLeida).length ?? 0;

    final nombre = perfilAsync.value?.nombre ?? '';
    final fotoUrl = perfilAsync.value?.fotoUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar pequeño (foto o iniciales).
          _AvatarCliente(fotoUrl: fotoUrl, nombre: nombre),
          const SizedBox(width: 12),
          // Saludo + nombre.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hola,',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                Text(
                  nombre.isEmpty ? 'Bienvenido/a' : nombre,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          // Icono de notificaciones con badge.
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, size: 28),
                tooltip: 'Notificaciones',
                onPressed: () => mostrarBottomSheetNotificaciones(context),
              ),
              if (noLeidas > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      noLeidas > 9 ? '9+' : '$noLeidas',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarCliente extends StatelessWidget {
  const _AvatarCliente({required this.fotoUrl, required this.nombre});

  final String? fotoUrl;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    final urlAbsoluta = ApiEndpoints.urlImagen(fotoUrl);
    if (urlAbsoluta.isEmpty) {
      // Fallback con iniciales.
      final iniciales = nombre.isEmpty
          ? '?'
          : nombre.trim().substring(0, 1).toUpperCase();
      return CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.accentGlow,
        child: Text(
          iniciales,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.accentGlow,
      backgroundImage: NetworkImage(urlAbsoluta),
    );
  }
}
