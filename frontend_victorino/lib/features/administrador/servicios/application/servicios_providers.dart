// Providers del submódulo servicios.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/dio_provider.dart';
import '../data/repositorios/servicio_admin_repositorio_impl.dart';
import '../domain/casos_uso/crear_servicio.dart';
// ============================================================
// ARCHIVO: servicios_providers.dart
// ¿QUÉ ES ESTE ARCHIVO?
// ------------------------------------------------------------
// Este archivo es el "director de orquesta" de la feature
// "Servicios" (los servicios de la peluquería Victorino).
//
// Su trabajo es CONECTAR todas las piezas entre sí:
//   - El backend (Spring Boot + MySQL) se comunica via HTTP
//   - Flutter (frontend) necesita datos para mostrar en pantalla
//   - Este archivo es el PUENTE entre ambos mundos
//
// ANALOGÍA SIMPLE:
//   Imagina una pizzería:
//   - El CLIENTE (pantalla Flutter) pide una pizza (datos)
//   - El MESERO (Provider) toma el pedido
//   - La COCINA (Repositorio) prepara la pizza
//   - Los INGREDIENTES (API/MySQL) vienen del proveedor
//   Este archivo define quién es el mesero, quién es la cocina, etc.
//
// ============================================================
//
// DIAGRAMA GENERAL DE LA ARQUITECTURA (Clean Architecture):
//
//  ┌─────────────────────────────────────────────────────┐
//  │                  FLUTTER (UI)                        │
//  │         Pantallas, Widgets, Botones                  │
//  └────────────────────┬────────────────────────────────┘
//                       │  "Dame la lista de servicios"
//                       ▼
//  ┌─────────────────────────────────────────────────────┐
//  │              PROVIDERS (este archivo)                │
//  │   Son como enchufes eléctricos: conectan todo        │
//  └──────────┬──────────────────────────────────────────┘
//             │
//             ▼
//  ┌─────────────────────────────────────────────────────┐
//  │              CASOS DE USO (domain/)                  │
//  │   Reglas del negocio: ObtenerServicios,              │
//  │   CrearServicio, EditarServicio...                   │
//  │   Son los "verbos" de la app (qué PUEDE hacer)       │
//  └──────────┬──────────────────────────────────────────┘
//             │
//             ▼
//  ┌─────────────────────────────────────────────────────┐
//  │           REPOSITORIO (domain/repositorios/)         │
//  │   Contrato (interfaz): dice QUÉ operaciones          │
//  │   existen, pero no CÓMO se hacen                     │
//  └──────────┬──────────────────────────────────────────┘
//             │
//             ▼
//  ┌─────────────────────────────────────────────────────┐
//  │        REPOSITORIO IMPL (data/repositorios/)         │
//  │   La implementación REAL: usa Dio (HTTP) para        │
//  │   hablar con Spring Boot via JWT                     │
//  └──────────┬──────────────────────────────────────────┘
//             │  HTTP Request con JWT token en el header
//             ▼
//  ┌─────────────────────────────────────────────────────┐
//  │          BACKEND (Spring Boot + MySQL)               │
//  │   API REST → Controladores → Servicios → MySQL       │
//  └─────────────────────────────────────────────────────┘
//
// ============================================================

// ============================================================
// IMPORTS: Traemos herramientas y piezas que necesitamos
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
// ↑ Riverpod es la librería de GESTIÓN DE ESTADO de Flutter.
//   "Estado" = los datos que la app recuerda en un momento dado.
//   Ejemplo: la lista de servicios cargados, si está cargando, etc.
//   Riverpod es como una "pizarra compartida" que cualquier
//   widget de la app puede leer o escuchar.

import '../../../../shared/providers/dio_provider.dart';
// ↑ Dio es el cliente HTTP de Flutter (como el Postman pero en código).
//   Sirve para hacer peticiones al backend Spring Boot.
//   El dioProvider ya tiene configurado el token JWT automáticamente,
//   para que cada petición al backend vaya autenticada.
//   Está en "shared" porque lo usan TODAS las features, no solo servicios.

import '../data/repositorios/servicio_admin_repositorio_impl.dart';
// ↑ La implementación REAL del repositorio.
//   Esta clase sabe cómo hablar con el backend:
//   hace llamadas HTTP a endpoints como:
//     GET  /api/servicios
//     POST /api/servicios
//     PUT  /api/servicios/{id}
//     etc.

import '../domain/casos_uso/crear_servicio.dart';
import '../domain/casos_uso/dar_baja_servicio.dart';
import '../domain/casos_uso/editar_servicio.dart';
import '../domain/casos_uso/obtener_servicios.dart';
import '../domain/casos_uso/subir_foto_servicio.dart';
// ↑ Los CASOS DE USO son clases pequeñas con UNA sola responsabilidad.
//   Clean Architecture exige que la lógica de negocio viva aquí,
//   NO en la pantalla ni en el repositorio.
//
//   Cada uno hace UNA cosa:
//     ObtenerServicios  → GET  /api/servicios
//     CrearServicio     → POST /api/servicios
//     EditarServicio    → PUT  /api/servicios/{id}
//     DarBajaServicio   → DELETE o PATCH (baja lógica, no borrado físico)
//     SubirFotoServicio → POST /api/servicios/{id}/foto (multipart)

import '../domain/entidades/servicio.dart';
// ↑ La ENTIDAD Servicio es la clase que representa un servicio
//   de la peluquería en el mundo de Dart/Flutter.
//   Ejemplo de cómo luce:
//     class Servicio {
//       final int id;
//       final String nombre;      // "Corte de cabello"
//       final double precio;      // 15000.0
//       final String? fotoUrl;    // URL de imagen en servidor
//       final bool activo;        // true = activo, false = dado de baja
//     }
//   Es un objeto PURO de Dart, sin lógica de base de datos ni HTTP.

import '../domain/repositorios/servicio_admin_repositorio.dart';
// ↑ El CONTRATO (interfaz abstracta) del repositorio.
//   Define qué operaciones existen, pero no cómo se hacen.
//   Esto permite que mañana cambies el backend y solo
//   cambies la implementación, no toda la app.
//   Es como un contrato laboral: dice qué debe hacer el empleado,
//   pero no cómo exactamente.

// ============================================================
// PROVIDER 1: servicioRepositorioProvider
// ============================================================
//
// ¿QUÉ ES UN Provider?
//   Un Provider es una "caja registradora" de objetos.
//   Cuando alguien pide el objeto, Riverpod lo crea UNA VEZ
//   y lo reutiliza. Es como un Singleton pero manejado por Riverpod.
//
// Este provider crea la instancia del Repositorio real (impl).
//
// DIAGRAMA:
//
//   servicioRepositorioProvider
//          │
//          ├── necesita → dioProvider (cliente HTTP con JWT)
//          │
//          └── crea → ServicioAdminRepositorioImpl(dio)
//                        │
//                        └── puede hacer peticiones HTTP al backend
//
final servicioRepositorioProvider = Provider<ServicioAdminRepositorio>((ref) {
  // "ref" es la referencia al contenedor de Riverpod.
  // Con ref.read() leemos otro provider (sin escucharlo).
  // ref.read(dioProvider) nos da el cliente HTTP ya configurado con JWT.
  return ServicioAdminRepositorioImpl(dio: ref.read(dioProvider));
  // ↑ Creamos la implementación real del repositorio,
  //   inyectándole Dio para que pueda hacer llamadas HTTP.
  //   Esto es INYECCIÓN DE DEPENDENCIAS: en vez de que
  //   el repositorio cree su propio Dio, se lo damos desde afuera.
});

// ============================================================
// PROVIDERS 2-6: Providers de Casos de Uso
// ============================================================
//
// Cada caso de uso necesita el repositorio para funcionar.
// Estos providers crean los casos de uso inyectándoles el repositorio.
//
// ANALOGÍA:
//   El repositorio es como una "caja de herramientas".
//   Cada caso de uso es un "técnico especialista" que necesita esa caja.
//   El provider es quien le da la caja al técnico.
//
// DIAGRAMA DE DEPENDENCIAS:
//
//   obtenerServiciosProvider
//          └── depende de → servicioRepositorioProvider
//                                └── depende de → dioProvider
//
//   crearServicioProvider
//          └── depende de → servicioRepositorioProvider
//                                └── depende de → dioProvider
//   (y así con todos)
//

final obtenerServiciosProvider = Provider<ObtenerServicios>(
      (ref) => ObtenerServicios(ref.read(servicioRepositorioProvider)),
  // ↑ Crea el caso de uso ObtenerServicios pasándole el repositorio.
  //   Cuando se llame obtenerServicios.ejecutar(), internamente
  //   llamará al repositorio, que llamará al backend vía HTTP GET.
);

final crearServicioProvider = Provider<CrearServicio>(
      (ref) => CrearServicio(ref.read(servicioRepositorioProvider)),
  // ↑ Caso de uso para crear un nuevo servicio (POST al backend).
);

final editarServicioProvider = Provider<EditarServicio>(
      (ref) => EditarServicio(ref.read(servicioRepositorioProvider)),
  // ↑ Caso de uso para editar un servicio existente (PUT al backend).
);

final darBajaServicioProvider = Provider<DarBajaServicio>(
      (ref) => DarBajaServicio(ref.read(servicioRepositorioProvider)),
  // ↑ Caso de uso para dar de baja un servicio.
  //   IMPORTANTE: en peluquerías no se BORRA un servicio de la BD,
  //   se marca como "inactivo" (baja lógica). Así se conserva historial.
  //   Ejemplo: si un cliente tuvo ese servicio antes, aún aparece en su historial.
);
final subirFotoServicioProvider = Provider<SubirFotoServicio>(
      (ref) => SubirFotoServicio(ref.read(servicioRepositorioProvider)),
  // ↑ Caso de uso para subir una foto al servicio.
  //   Internamente hace un POST multipart/form-data al backend.
  //   El backend guarda la imagen y devuelve la URL pública.
  //   Esa URL se guarda en la BD MySQL y se puede usar en Flutter
  //   para mostrar la foto del servicio.
);


// ============================================================
// CLASE: ServiciosAdminNotifier
// ============================================================
//
// ¿QUÉ ES UN Notifier?
//   Un Notifier es una clase que:
//   1. GUARDA el estado actual (la lista de servicios)
//   2. NOTIFICA a la UI cuando el estado cambia
//   3. Tiene MÉTODOS para cambiar el estado
//
// ¿QUÉ ES AsyncNotifier?
//   El "Async" significa que el estado viene de una operación
//   asíncrona (como llamar al backend).
//
//   ¿QUÉ ES ASÍNCRONO?
//   Cuando haces algo que tarda tiempo (llamar al backend, leer un archivo),
//   no puedes bloquear toda la app esperando. "Async" = puedes esperar
//   sin congelar la pantalla.
//   Es como pedir comida a domicilio: pides (async), sigues con tu vida,
//   y cuando llega (await), la recibes.
//
// ¿QUÉ ES Future?
//   Future<List<Servicio>> es una PROMESA de que en el futuro
//   habrá una List<Servicio>.
//   Hoy dices "prometo que cuando el backend responda, tendrás la lista".
//
// DIAGRAMA DE ESTADOS DEL Notifier:
//
//   ┌──────────────┐    build()     ┌──────────────┐
//   │   INICIAL    │ ─────────────▶ │  CARGANDO    │
//   │  (no existe) │                │ AsyncLoading │
//   └──────────────┘                └──────┬───────┘
//                                          │
//                          Backend responde│
//                                   ┌──────┴───────┐
//                          ✅ OK ───▶│    DATOS     │
//                                   │  AsyncData   │
//                                   │ [Servicio1,  │
//                                   │  Servicio2]  │
//                                   └──────────────┘
//                          ❌ Error─▶┌──────────────┐
//                                   │    ERROR     │
//                                   │  AsyncError  │
//                                   └──────────────┘
//
// En la UI de Flutter puedes hacer:
//   ref.watch(serviciosAdminNotifierProvider).when(
//     loading: () => CircularProgressIndicator(),
//     data: (servicios) => ListView(...),
//     error: (e, st) => Text('Error: $e'),
//   )
//

class ServiciosAdminNotifier extends AsyncNotifier<List<Servicio>> {
  // ↑ AsyncNotifier<List<Servicio>> significa:
  //   "Soy un notifier que maneja un estado asíncrono de tipo List<Servicio>"
  bool _incluirInactivos = false;
  bool get incluirInactivos => _incluirInactivos;


  // ============================================================
  // MÉTODDO: build()
  // ============================================================
  //
  // build() es el métoddo que Riverpod llama AUTOMÁTICAMENTE cuando
  // alguien usa este provider por primera vez.
  // Es como el "constructor" del estado: carga los datos iniciales.
  //
  // FLUJO:
  //   1. La pantalla se abre y consume este provider
  //   2. Riverpod llama a build() automáticamente
  //   3. build() llama al caso de uso ObtenerServicios
  //   4. ObtenerServicios llama al repositorio
  //   5. El repositorio hace GET /api/servicios al backend Spring Boot
  //   6. Spring Boot consulta MySQL y devuelve JSON
  //   7. El JSON se convierte a List<Servicio>
  //   8. La UI se actualiza automáticamente con los datos
  @override
  Future<List<Servicio>> build() =>
      ref.read(obtenerServiciosProvider).ejecutar(incluirInactivos: _incluirInactivos);

  Future<void> recargar() async {
    state = const AsyncLoading();
    // ↑ Ponemos el estado en "cargando" INMEDIATAMENTE.
    //   Esto hace que la UI muestre un spinner/loading indicator.
    //   "state" es la variable especial del AsyncNotifier que
    //   Riverpod observa para notificar a la UI.

    state = await AsyncValue.guard(() =>
        ref.read(obtenerServiciosProvider).ejecutar(incluirInactivos: incluirInactivos));
    // ↑ AsyncValue.guard() es un helper de Riverpod que:
    //   - Ejecuta la función async que le pasamos
    //   - Si sale bien → state = AsyncData(lista)   → UI muestra datos
    //   - Si hay error → state = AsyncError(error)  → UI muestra error
    //   Sin guard(), tendrías que escribir try/catch tú mismo.
    //
    //   "await" significa: espera a que el backend responda
    //   antes de continuar. Mientras espera, la UI ya está mostrando
    //   el loading (puesto en la línea anterior).
  }


  // ============================================================
  // MÉTODOO: alternarInactivos()
  // ============================================================
  //
  // Cambia el filtro de "mostrar solo activos" vs "mostrar todos".
  // Se llamaría desde un Switch/Toggle en la pantalla de admin.
  //
  // FLUJO EN LA UI:
  //   [Toggle: Mostrar inactivos] ←→ llama alternarInactivos(true/false)
  //                                         ↓
  //                              cambia _incluirInactivos
  //                                         ↓
  //                              llama recargar()
  //                                         ↓
  //                              nueva petición al backend con nuevo filtro
  //                                         ↓
  //                              UI se actualiza automáticamente
  //
  Future<void> alternarInactivos(bool valor) async {
    _incluirInactivos = valor;
    await recargar();
  }
}


// ============================================================
// PROVIDER FINAL: serviciosAdminNotifierProvider
// ============================================================
//
// Este es el provider que LA PANTALLA (UI) va a escuchar/consumir.
// Es el "enchufe" al que se conecta la pantalla para obtener
// la lista de servicios y reaccionar a sus cambios.
//
// ¿Por qué AsyncNotifierProvider y no Provider simple?
//   Porque los datos vienen del backend (operación async).
//   AsyncNotifierProvider maneja los 3 estados automáticamente:
//     - Cargando (mientras espera al backend)
//     - Con datos (cuando el backend responde OK)
//     - Con error (si hay falla de red, 401 JWT expirado, etc.)
//
// CÓMO SE USA EN LA PANTALLA (ejemplo):
//
//   class ServiciosScreen extends ConsumerWidget {
//     @override
//     Widget build(BuildContext context, WidgetRef ref) {
//       // watch = escucha cambios. Si cambia, el widget se redibuja.
//       final serviciosAsync = ref.watch(serviciosAdminNotifierProvider);
//
//       return serviciosAsync.when(
//         loading: () => CircularProgressIndicator(),
//         error: (e, st) => Text('Algo salió mal: $e'),
//         data: (servicios) => ListView.builder(
//           itemCount: servicios.length,
//           itemBuilder: (ctx, i) => ListTile(title: Text(servicios[i].nombre)),
//         ),
//       );
//     }
//   }
//
// CÓMO SE LLAMAN LOS MÉTODOS (ejemplo desde un botón):
//
//   // Recargar la lista:
//   ref.read(serviciosAdminNotifierProvider.notifier).recargar();
//
//   // Mostrar/ocultar inactivos:
//   ref.read(serviciosAdminNotifierProvider.notifier).alternarInactivos(true);
//
final serviciosAdminNotifierProvider =
AsyncNotifierProvider<ServiciosAdminNotifier, List<Servicio>>(ServiciosAdminNotifier.new);
//                                                                  ↑
//   ServiciosAdminNotifier.new es la referencia al constructor de la clase.
//   Es equivalente a escribir: () => ServiciosAdminNotifier()
//   Riverpod llama a esto cuando alguien usa el provider por primera vez.

// ============================================================
// RESUMEN: ¿Cómo se relaciona con el backend Spring Boot?
// ============================================================
//
//  Flutter (UI)
//      │  ref.watch(serviciosAdminNotifierProvider)
//      ▼
//  ServiciosAdminNotifier (este archivo)
//      │  ref.read(obtenerServiciosProvider).ejecutar(...)
//      ▼
//  ObtenerServicios (caso de uso)
//      │  repositorio.obtenerServicios(incluirInactivos)
//      ▼
//  ServicioAdminRepositorioImpl
//      │  dio.get('/api/servicios', queryParameters: {...})
//      │  Header: Authorization: Bearer <JWT_TOKEN>
//      ▼
//  Spring Boot Controller (@GetMapping("/api/servicios"))
//      │  @PreAuthorize("hasRole('ADMIN')")  ← verifica JWT
//      ▼
//  Spring Boot Service
//      │  servicioRepository.findByActivoTrue()
//      ▼
//  MySQL (tabla: servicios)
//      │
//      └── Devuelve JSON → se mapea a List<Servicio> en Flutter
//
// SOBRE JWT (JSON Web Token):
//   Cuando el admin inicia sesión, Spring Boot le da un "token JWT".
//   Es como una pulsera de acceso VIP en un evento.
//   Cada petición al backend incluye esa pulsera en el header.
//   Spring Boot la verifica antes de responder.
//   Si el token expira → error 401 → la app redirige al login.
//
// SOBRE FCM (Firebase Cloud Messaging):
//   Las notificaciones push (ej: "tu cita fue confirmada") se envían
//   desde Spring Boot a Firebase, y Firebase las entrega al celular.
//   Este archivo de providers no las maneja directamente,
//   pero otros providers del proyecto sí lo hacen.
// ============================================================