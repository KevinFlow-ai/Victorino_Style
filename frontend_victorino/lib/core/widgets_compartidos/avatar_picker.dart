import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_colores.dart';


/*

  Un Avatar Picker para foto de perfil del empleado, en
   funciona como un selector y recortador de fotos de perfil.
  Es la herramienta que aparece cuando quieres cambiar tu imagen en una
  aplicación y te permite ajustar qué parte de la foto se verá



  // Un widget que muestra un avatar circular utilizado para seleccionar
/// o cambiar la foto de perfil de un empleado.
///
/// Este widget:
/// - Muestra una foto local (`File`) si ya fue seleccionada.
/// - Muestra un icono de cámara si no hay foto.
/// - Es táctil, permitiendo abrir un selector de imágenes mediante `onTap`.
/// - Incluye un borde circular decorativo.
/// - Recorta la imagen en forma de círculo.
///
/// Ideal para pantallas de edición de perfil o formularios donde el usuario
/// debe elegir o actualizar su foto.

 */
class AvatarPicker extends StatelessWidget {
  final File? foto;              // Foto local seleccionada por el usuario
  final VoidCallback? onTap;     // Acción al tocar el avatar (abrir selector)
  final double size;             // Tamaño del avatar
  final double iconSize;         // Tamaño del icono cuando no hay foto
  final Color borderColor;       // Color del borde circular
  final double borderWidth;      // Grosor del borde

  const AvatarPicker({
    super.key,
    required this.foto,
    required this.onTap,
    this.size = 120,
    this.iconSize = 50,
    this.borderColor = Colors.white,
    this.borderWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Detecta el toque para abrir el selector de imágenes
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipOval(
              child: foto == null
              // Recorta el contenido en forma circular
                  ? Container(
                width: size,
                height: size,
                color: AppColors.accentGlow,
                child: Icon(
                  Icons.camera_alt,
                  color: AppColors.primary,
                  size: iconSize,
                ),
              )
                  : Image.file(  // Si hay foto, la muestra ocupando todoO el círculo
                foto!,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),

            // Borde circular
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: borderWidth,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



/*

    Perfecto, vamos a mejorar tu AvatarPicker para que soporte File, URL (NetworkImage) y AssetImage, manteniendo EXACTAMENTE el mismo diseño que te gusta:
círculo perfecto, icono grande cuando no hay foto, borde elegante, centrado, sin ovalarse.

******************** 2 OPCION*********************************

import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_colores.dart';

class AvatarPicker extends StatelessWidget {
  final File? fotoFile;
  final String? fotoUrl;
  final String? assetImage;
  final VoidCallback? onTap;

  final double size;
  final double iconSize;
  final Color borderColor;
  final double borderWidth;

  const AvatarPicker({
    super.key,
    this.fotoFile,
    this.fotoUrl,
    this.assetImage,
    required this.onTap,
    this.size = 120,
    this.iconSize = 50,
    this.borderColor = Colors.white,
    this.borderWidth = 3,
  });

  ImageProvider? _resolverImagen() {
    if (fotoFile != null) return FileImage(fotoFile!);
    if (fotoUrl != null && fotoUrl!.isNotEmpty) return NetworkImage(fotoUrl!);
    if (assetImage != null && assetImage!.isNotEmpty) return AssetImage(assetImage!);
    return null; // No hay imagen → mostrar icono
  }

  @override
  Widget build(BuildContext context) {
    final imagen = _resolverImagen();

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipOval(
              child: imagen == null
                  ? Container(
                      width: size,
                      height: size,
                      color: AppColors.accentGlow,
                      child: Icon(
                        Icons.camera_alt,
                        color: AppColors.primary,
                        size: iconSize,
                      ),
                    )
                  : Image(
                      image: imagen,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                    ),
            ),

            // Borde circular
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: borderWidth,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

        ******************** 3 OPCION*********************************
        un placeholder animado?

        un loader mientras carga la imagen de red?

        un efecto de sombra alrededor del avatar?

        un icono de editar flotante tipo Instagram?

        import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_colores.dart';

class AvatarPicker extends StatelessWidget {
  final File? fotoFile;
  final String? fotoUrl;
  final String? assetImage;
  final String? base64Image;

  final VoidCallback? onTap;

  final double size;
  final double iconSize;

  final Color borderColor;
  final double borderWidth;

  final bool showEditIcon;
  final bool showShadow;

  const AvatarPicker({
    super.key,
    this.fotoFile,
    this.fotoUrl,
    this.assetImage,
    this.base64Image,
    required this.onTap,
    this.size = 120,
    this.iconSize = 50,
    this.borderColor = Colors.white,
    this.borderWidth = 3,
    this.showEditIcon = true,
    this.showShadow = true,
  });

  ImageProvider? _resolverImagen() {
    if (fotoFile != null) return FileImage(fotoFile!);
    if (fotoUrl != null && fotoUrl!.isNotEmpty) return NetworkImage(fotoUrl!);
    if (assetImage != null && assetImage!.isNotEmpty) return AssetImage(assetImage!);
    if (base64Image != null && base64Image!.isNotEmpty) {
      final bytes = base64Decode(base64Image!);
      return MemoryImage(bytes);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final imagen = _resolverImagen();

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Sombra suave
            if (showShadow)
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),

            // Imagen o placeholder
            ClipOval(
              child: imagen == null
                  ? _placeholderAnimado()
                  : _imagenConLoader(imagen),
            ),

            // Borde circular
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: borderWidth,
                  ),
                ),
              ),
            ),

            // Icono flotante de editar
            if (showEditIcon)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Placeholder animado
  Widget _placeholderAnimado() {
    return Container(
      width: size,
      height: size,
      color: AppColors.accentGlow,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.1),
        duration: Duration(seconds: 1),
        curve: Curves.easeInOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        onEnd: () {},
        child: Icon(
          Icons.camera_alt,
          color: AppColors.primary,
          size: iconSize,
        ),
      ),
    );
  }

  // Loader mientras carga imagen de red
  Widget _imagenConLoader(ImageProvider imagen) {
    return Image(
      image: imagen,
      width: size,
      height: size,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loading) {
        if (loading == null) return child;
        return Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        );
      },
      errorBuilder: (context, error, stack) {
        return _placeholderAnimado();
      },
    );
  }
}

 */