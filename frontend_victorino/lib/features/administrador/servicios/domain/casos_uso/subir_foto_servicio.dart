// ============================================================
// ARCHIVO: subir_foto_servicio.dart
// CAPA: Domain (Dominio) — en Clean Architecture
// ============================================================
//
// ¿QUÉ HACE ESTE ARCHIVO?
// ────────────────────────
// Es el Caso de Uso para SUBIR LA FOTO de un servicio.
// Cuando el admin elige una imagen del celular y la asigna
// a un servicio, este caso de uso coordina esa acción.
//
// Devuelve la URL donde quedó guardada la foto,
// para que luego pueda mostrarse en la pantalla.
//
// ============================================================
// DIAGRAMA — ¿QUÉ PASA CUANDO SE SUBE UNA FOTO?
// ============================================================
//
//  Admin toca "elegir foto" en Flutter
//         │
//         ▼
//  image_picker (librería) abre la galería/cámara
//         │
//         ▼
//  Devuelve un File (archivo de imagen del celular)
//         │
//         ▼
//  Provider llama: subirFotoServicio.ejecutar(id, archivo)
//         │
//         ▼
//  SubirFotoServicio.ejecutar(id, archivo)  ← ESTE ARCHIVO
//         │
//         ▼
//  repositorio.subirFoto(id, archivo)
//         │
//         ▼
//  HTTP POST multipart/form-data
//  /api/admin/servicios/{id}/foto  con JWT
//         │
//         ▼
//  Spring Boot recibe el archivo
//         │
//         ├──► Opción A: guarda en el servidor local
//         │              y devuelve una URL relativa
//         │
//         └──► Opción B: sube a Firebase Storage / S3 / Cloudinary
//                        y devuelve la URL pública
//         │
//         ▼
//  Responde: { "fotoUrl": "https://..." }
//         │
//         ▼
//  RepositorioImpl extrae el String de la URL
//         │
//         ▼
//  Provider guarda la URL → Flutter muestra la foto ✓
//
// ============================================================
// DIAGRAMA — RELACIÓN CON OTROS ARCHIVOS
// ============================================================
//
//  dart:io (File)
//    ↓ representa el archivo físico en el celular
//
//  SubirFotoServicio  (este archivo — Domain)
//    ↓ usa el contrato
//  ServicioAdminRepositorio  (contrato — Domain)
//    ↓ implementado por
//  ServicioAdminRepositorioImpl  (Data)
//    ↓ usa
//  Dio + FormData + MultipartFile
//    ↓ HTTP POST multipart
//  Spring Boot
//    ↓ guarda la imagen y responde con
//  fotoUrl: String  →  regresa por el mismo camino
//
// ============================================================
// ¿QUÉ ES dart:io y File?
// ============================================================
//
//  "dart:io" es una librería incluida en Dart que da acceso
//  al sistema de archivos del dispositivo.
//
//  "File" representa un archivo real en el celular.
//  Tiene propiedades como:
//    archivo.path          → "/storage/emulated/0/foto.jpg"
//    archivo.uri           → URI del archivo
//    archivo.readAsBytes() → lee los bytes del archivo
//
//  En Flutter normalmente usas "image_picker" para que
//  el usuario elija una foto, y esa librería te devuelve
//  un XFile que puedes convertir a File para usarlo aquí.
//
// ============================================================

// dart:io nos da la clase File que representa
// un archivo físico en el sistema del celular.
import 'dart:io';

// El contrato del repositorio. Solo usamos el contrato,
// no la implementación concreta. Así el dominio no
// sabe nada de Dio ni HTTP.
import '../repositorios/servicio_admin_repositorio.dart';
class SubirFotoServicio {
  SubirFotoServicio(this._repositorio);
  final ServicioAdminRepositorio _repositorio;

  // ──────────────────────────────────────────────────────
  // MÉTOoDO: ejecutar
  // ──────────────────────────────────────────────────────
  // Recibe:
  //   int id       → ID del servicio al que se asigna la foto
  //   File archivo → el archivo de imagen del celular
  //
  // Devuelve:
  //   Future<String> → la URL pública de la foto ya subida
  //                    Ej: "https://storage.../foto.jpg"
  //
  // "=>" es expression body (función de una línea).
  // Sin async porque solo pasa el Future del repositorio,
  // no hace nada propio con él.
  Future<String> ejecutar(int id, File archivo) =>
      _repositorio.subirFoto(id, archivo);
}



// ============================================================
// VERSIÓN CORREGIDA COMPLETA
// ============================================================
//
//  import 'dart:io';
//  import '../repositorios/servicio_admin_repositorio.dart';
//
//  class SubirFotoServicio {
//    SubirFotoServicio(this._repositorio);
//    final ServicioAdminRepositorio _repositorio;  // ← con _
//
//    Future<String> ejecutar(int id, File archivo) =>
//        _repositorio.subirFoto(id, archivo);      // ← con _
//  }
//
// ============================================================
// COMPARATIVA DE LOS 3 CASOS DE USO SIMPLES
// ============================================================
//
//              EditarServicio   SubirFoto      DarBaja
//  Recibe:     id + DatosServ   id + File      id
//  Devuelve:   Future<Servicio> Future<String> Future<void>
//  HTTP:       PUT              POST multipart DELETE
//  Valida:     No               No             No
//  Complejidad: Mínima          Mínima         Mínima
//
// Los 3 son "pass-through": delegan directo al repositorio.
// CrearServicio es el único con validación propia (por ahora).
//
// ============================================================
// FLUJO VISUAL COMPLETO EN LA PANTALLA DEL ADMIN
// ============================================================
//
//  ┌─────────────────────────────────────────┐
//  │  Pantalla: Editar Servicio              │
//  │                                         │
//  │  Nombre:    [Corte de cabello     ]     │
//  │  Precio:    [15.50               ]      │
//  │  Duración:  [30 min              ]      │
//  │                                         │
//  │  Foto actual: [imagen del servicio]     │
//  │  [📷 Cambiar foto]  ← llama a este      │
//  │                       caso de uso       │
//  │  [💾 Guardar]       ← llama a           │
//  │                       EditarServicio    │
//  └─────────────────────────────────────────┘
//
//  Al tocar "Cambiar foto":
//    1. image_picker abre galería del celular
//    2. Usuario elige foto → obtienes un File
//    3. SubirFotoServicio.ejecutar(id, archivo)
//    4. Sube al servidor, recibe URL
//    5. Guarda la URL en el estado del formulario
//    6. Al guardar el formulario, ya tiene la nueva fotoUrl
//
// ============================================================
// NOTA SOBRE FCM / FIREBASE
// ============================================================
//
//  En tu stack tienes Firebase para notificaciones (FCM).
//  Si el backend también usa Firebase Storage para guardar
//  las fotos, el flujo sería:
//
//  Flutter → Spring Boot (recibe el archivo)
//                │
//                └──► Firebase Storage (guarda la imagen)
//                          │
//                          └──► devuelve URL pública
//                                    │
//                          Spring Boot guarda esa URL en MySQL
//                          tabla servicios, columna foto_url
//                                    │
//                          responde a Flutter con { fotoUrl: ... }
//
//  Alternativamente, Flutter podría subir DIRECTO a
//  Firebase Storage sin pasar por Spring Boot, y solo
//  mandarle la URL resultante al backend. Ambas formas son válidas.
//
// ============================================================
// RESUMEN PARA NOVATOS
// ============================================================
//
//  Este archivo hace UNA cosa: coordinar la subida de una foto.
//  Es simple a propósito. En Clean Architecture, cada
//  responsabilidad vive en su propio lugar.
//  Mismo bug de _repositorio que los otros casos de uso.
//  La diferencia única: trabaja con File (archivo real)
//  en vez de con datos de un formulario.
// ============================================================