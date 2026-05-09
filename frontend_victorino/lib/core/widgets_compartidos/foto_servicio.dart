import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colores.dart';
import '../api/api_endpoints.dart';


/// Widget que muestra una imagen de un servicio, ya sea:
/// - Una foto local (`File`) cuando se está editando.
/// - Una foto remota (`URL`) cuando proviene de la API.
/// - Un placeholder cuando no existe imagen.
///
/// Este widget calcula dinámicamente el **aspect ratio** de la imagen
/// para evitar saltos visuales y mantener proporciones correctas.
///
/// También aplica bordes redondeados mediante `borderRadius`.
///
class FotoServicio extends StatelessWidget {
  const FotoServicio({
    super.key,
    this.file,
    this.url,
    this.borderRadius = 16,
    this.placeholderHeight = 200,
  });

  final File? file;          // Foto local (pantalla de edición)
  final String? url;         // Foto remota (lista de servicios)
  final double borderRadius; // Bordes redondeados
  final double placeholderHeight;

  @override
  Widget build(BuildContext context) {
    // 1. Foto local (edición)
    if (file != null) {
      return FutureBuilder<double>(
        future: _aspectRatioFromFile(file!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _placeholder();
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: AspectRatio(
              aspectRatio: snapshot.data!,
              child: Image.file(
                file!,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      );
    }

    // 2. Foto remota (lista)
    if (url != null && url!.isNotEmpty) {
      final completa = ApiEndpoints.urlImagen(url!);

      return FutureBuilder<double>(
        future: _aspectRatioFromNetwork(completa),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _placeholder();
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: AspectRatio(
              aspectRatio: snapshot.data!,
              child: Image.network(
                completa,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              ),
            ),
          );
        },
      );
    }

    // 3. Sin foto
    return _placeholder();
  }

  // ⭐ Placeholder cuando no hay foto
  Widget _placeholder() {
    return Container(
      height: placeholderHeight,
      decoration: BoxDecoration(
        color: AppColors.accentGlow,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(
        child: Icon(Icons.image, size: 48, color: AppColors.primary),
      ),
    );
  }

  // ⭐ Aspect ratio desde archivo local
  /// Obtiene el aspect ratio de una imagen local (`File`).
  ///
  /// Esto permite mostrar la imagen con sus proporciones reales.
  Future<double> _aspectRatioFromFile(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    return image.width / image.height;
  }

  // ⭐ Aspect ratio desde imagen remota
  /// Obtiene el aspect ratio de una imagen remota (`URL`).
  ///
  /// Se resuelve cargando la imagen en memoria y leyendo sus dimensiones
  ///
  Future<double> _aspectRatioFromNetwork(String url) async {
    final completer = Completer<ImageInfo>();

    final image = Image.network(url);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((info, _) {
        completer.complete(info);
      }),
    );

    final info = await completer.future;
    return info.image.width / info.image.height;
  }
}
