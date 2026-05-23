// Helper compartido para seleccionar y recortar imágenes en TODA la app.
//
// Uso típico:
//
//   final foto = await SelectorImagen.elegirYRecortar(
//     context: context,
//     formaCircular: true,                      // empleados
//     // formaCircular: false,                  // servicios → permite varios aspect ratios
//   );
//   if (foto != null) setState(() => _foto = foto);
//
// Devuelve un File con la imagen YA recortada lista para subir, o null si el
// usuario cancela.
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colores.dart';

class SelectorImagen {
  // Constructor privado: solo se usa de forma estática.
  SelectorImagen._();

  // Punto de entrada principal. Abre un bottom sheet con dos opciones (Galería
  // y Cámara) y, tras elegir, abre el editor de recorte. Devuelve el File
  // recortado o null si el usuario cancela en cualquier paso.
  //
  // Parámetros:
  // - formaCircular: true para fotos de perfil (avatar redondo). false para
  //   imágenes rectangulares como las cards de servicios.
  // - aspectRatiosRectangulares: cuando formaCircular=false, lista de ratios
  //   que el usuario puede elegir desde el editor (1:1, 16:9, 4:3, etc.).
  static Future<File?> elegirYRecortar({
    required BuildContext context,
    bool formaCircular = false,
  }) async {
    // ─── Limitación conocida en Flutter Web ──────────────────────────────────
    // El paquete image_cropper NO soporta Flutter Web (solo Android, iOS,
    // macOS, Windows y Linux), y la clase File de dart:io tampoco funciona
    // en navegador. Por eso en web mostramos un aviso al usuario y abortamos
    // la subida sin intentar abrir nada. La app móvil sigue funcionando con
    // total normalidad.
    //
    // Para soportar subida de fotos también en web habría que: (1) sustituir
    // image_cropper por crop_your_image (sí soporta web), (2) cambiar la
    // firma de este métodoo para devolver XFile en lugar de File, y (3)
    // ajustar los repositorios para usar MultipartFile.fromBytes en web.
    // Pendiente para una versión futura.
    if (kIsWeb) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La subida de fotos solo está disponible desde la app móvil. '
              'Descarga el APK Android para cambiar tu foto.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
      return null;
    }

    // Paso 1: elegir origen (galería o cámara).
    final origen = await _mostrarBottomSheetOrigen(context);
    if (origen == null) return null;

    // Paso 2: usar image_picker para obtener la imagen original.
    final picker = ImagePicker();
    final XFile? archivoOriginal = await picker.pickImage(
      source: origen,
      imageQuality: 90, // compresión inicial; el cropper también comprime después
    );
    if (archivoOriginal == null) return null;

    // Paso 3: abrir el editor de recorte con la configuración correcta.
    final CroppedFile? recortado = await ImageCropper().cropImage(
      sourcePath: archivoOriginal.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: formaCircular ? 'Recortar foto de perfil' : 'Recortar foto',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.primary,
          backgroundColor: Colors.white,
          dimmedLayerColor: Colors.white.withOpacity(0.25), // ⭐ CLAVE
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: formaCircular,
          cropStyle: formaCircular ? CropStyle.circle : CropStyle.rectangle,
          aspectRatioPresets: formaCircular
              ? const [CropAspectRatioPreset.square]
              : const [
                  CropAspectRatioPreset.square,
                  CropAspectRatioPreset.ratio16x9,
                  CropAspectRatioPreset.ratio4x3,
                ],
        ),
        IOSUiSettings(
          title: formaCircular ? 'Recortar foto de perfil' : 'Recortar foto',
          aspectRatioLockEnabled: formaCircular,
          resetAspectRatioEnabled: !formaCircular,
          cropStyle: formaCircular ? CropStyle.circle : CropStyle.rectangle,
          aspectRatioPresets: formaCircular
              ? const [CropAspectRatioPreset.square]
              : const [
                  CropAspectRatioPreset.square,
                  CropAspectRatioPreset.ratio16x9,
                  CropAspectRatioPreset.ratio4x3,
                  CropAspectRatioPreset.ratio5x4,   // 5:4

                ],

          /*
          Ratio mas posibles
          aspectRatioPresets: formaCircular
            ? const [CropAspectRatioPreset.square]
            : const [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio16x9,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.ratio5x3,
                CropAspectRatioPreset.ratio5x4,
                CropAspectRatioPreset.ratio7x5,
                CropAspectRatioPreset.ratio9x16,
                CropAspectRatioPreset.ratio3x4,
                CropAspectRatioPreset.ratio2x3,
                CropAspectRatioPreset.ratio4x5,
                CropAspectRatioPreset.ratio5x7,
      ],


                  2º OPCION. vALIDOS-------------************-----------------------*
                     CropAspectRatioPreset.square,     // 1:1
                    CropAspectRatioPreset.ratio3x2,   // 3:2
                    CropAspectRatioPreset.ratio4x3,   // 4:3
                    CropAspectRatioPreset.ratio5x3,   // 5:3
                    CropAspectRatioPreset.ratio5x4,   // 5:4
                    CropAspectRatioPreset.ratio7x5,   // 7:5
                    CropAspectRatioPreset.ratio16x9,  // 16:9



           */
        ),
      ],
    );
    if (recortado == null) return null;

    // El cropper devuelve un CroppedFile; lo convertimos a File del SDK Dart.
    return File(recortado.path);
  }

  // Bottom sheet con las dos opciones. Devuelve la fuente elegida o null si
  // el usuario cancela tocando fuera.
  static Future<ImageSource?> _mostrarBottomSheetOrigen(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Elige la foto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
