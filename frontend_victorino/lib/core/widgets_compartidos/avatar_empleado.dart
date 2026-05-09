import 'dart:io';
import 'package:flutter/material.dart';

import '../theme/app_colores.dart';
import '../api/api_endpoints.dart';

/*
Un Avatar Picker2. para EMPLEADO. pero aqui acepta Para fotos locales (pantalla de edición)
 Para fotos remotas (lista de empleados)
 funciona como un selector y recortador de fotos de perfil.
Es la herramienta que aparece cuando quieres cambiar tu imagen en una
aplicación y te permite ajustar qué parte de la foto se verá


/*
Widget AvatarEmpleado:
Muestra un avatar circular que puede provenir de:
 - Una foto local (File) cuando se edita el perfil.
 - Una foto remota (URL) cuando viene desde la API.
 - Un icono por defecto si no hay foto disponible.

Además:
 - Puede aplicar un filtro en escala de grises si el empleado está inactivo.
 - Puede mostrar un borde blanco opcional alrededor del avatar.
*/
 */



class AvatarEmpleado extends StatelessWidget {
  const AvatarEmpleado({
    super.key,
    this.file,          // Foto local (pantalla de edición)
    this.url,           // Foto remota (lista de empleados)
    this.size = 120,    // Tamaño del avatar
    this.activo = true, // Si es false, aplica filtro gris
    this.iconSize = 40, // Tamaño del icono fallback
    this.showBorder = true, // Mostrar borde blanco
  });

  final File? file;          // Para fotos locales (pantalla de edición)
  final String? url;         // Para fotos remotas (lista de empleados)
  final double size;         // Tamaño del avatar
  final bool activo;         // Para aplicar filtro gris
  final double iconSize;     // Tamaño del icono cuando no hay foto
  final bool showBorder;     // Mostrar borde blanco o no

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Recorta el contenido en forma circular
          ClipOval(
            child: ColorFiltered(
              // Si el empleado está inactivo, aplica filtro en escala de grises
              colorFilter: activo
                  ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                  : const ColorFilter.matrix(<double>[
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0,      0,      0,      1, 0,
              ]),
              child: _contenido(),
            ),
          ),

          // Dibuja un borde blanco circular si está habilitado
          if (showBorder)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Determina qué contenido mostrar dentro del avatar
  Widget _contenido() {
    // 1. Foto local (pantalla de edición)
    if (file != null) {
      return Image.file(
        file!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }

    // 2. Foto remota (lista de empleados). // Si hay URL remota, cargar imagen desde la API
    if (url != null && url!.isNotEmpty) {
      return Image.network(
        ApiEndpoints.urlImagen(url!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        // Si falla la carga, mostrar fallback
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    // 3. Fallback
    return _fallback();
  }


  // Widget mostrado cuando no hay foto disponible
  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      color: AppColors.accentGlow, // Fondo de color
      child: Icon(Icons.person, color: AppColors.primary, size: iconSize),
    );
  }
}
