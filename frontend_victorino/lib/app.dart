// Widget raíz de la app. Configura MaterialApp.router con el tema y el router
// definidos en core/. Vive separado de main.dart para que main solo arranque.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/fcm_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_themes.dart';
// import 'core/preview/ageenda_admin.dart';

import 'features/notificaciones/application/notificaciones_notifier.dart';
import 'features/notificaciones/application/notificaciones_providers.dart';
import 'shared/providers/sesion_provider.dart';

class VictorinoApp extends ConsumerStatefulWidget {
  // ConsumerWidget permite leer providers de Riverpod dentro del build.
  const VictorinoApp({super.key});

  @override
  ConsumerState<VictorinoApp> createState() => _VictorinoAppState();
}

class _VictorinoAppState extends ConsumerState<VictorinoApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Callback de foreground: recarga la bandeja cuando llega un push
      // o cuando el usuario toca una notificación desde background.
      FcmService.onMensajeEntrante = () {
        ref.read(notificacionesNotifierProvider.notifier).recargar().ignore();
      };

      // Callback de rotación de token FCM (Bug fix):
      // Cuando Firebase rota el token (reinstalación, ciclo anual, revocación),
      // lo registramos en el backend para que los pushes sigan funcionando.
      FcmService.onTokenRefrescado = (nuevoToken) async {
        final sesion = ref.read(sesionProvider).value;
        if (sesion == null) return; // Sin sesión no podemos registrar el token.
        await ref.read(registrarDeviceTokenProvider).ejecutar(
          sesion.idUsuario,
          nuevoToken,
          esLoginExplicito: false, // Rotación silenciosa: sin notificación de bienvenida.
        );
      };

      // Si la app fue lanzada desde una notificación push (estaba cerrada),
      // recargamos la bandeja para que el usuario vea el nuevo mensaje.
      if (FcmService.consumirMensajeInicial()) {
        ref.read(notificacionesNotifierProvider.notifier).recargar().ignore();
      }
    });
  }

  @override
  void dispose() {
    FcmService.onMensajeEntrante = null;
    FcmService.onTokenRefrescado = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el router desde Riverpod.
    final router = ref.watch(appRouterProvider);
    // appRouterProvider devuelve un GoRouter configurado con todas las rutas.

    return MaterialApp.router(
      title: 'Victorino Style', // Título de la app.

      debugShowCheckedModeBanner: false, // Oculta la etiqueta de debug.

      theme: AppThemes.victorinoTheme, // Tema global de la app (colores, tipografías, estilos).

      routerConfig: router, // Configuración del router: navegación declarativa con GoRouter.
    );
  }
}

/*
    *****************************  PARA PROBAR CUALQUIER PANTALLA***********

    return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.victorinoTheme,
    home: const AgendaAdminPreview(), // 👈 poner la ruta de la pantalla a probar
    );



 */

    /*
    RESUMEN DEL ARCHIVO
    Este archivo define el widget raíz VictorinoApp, que es el punto central donde se configura:
    main.dart → VictorinoApp → MaterialApp.router → appRouterProvider → GoRouter

     1. El router global de la app
    • Se obtiene desde un provider de Riverpod (appRouterProvider).
    • Se pasa a MaterialApp.router.
    • Controla toda la navegación de la app.

     2. El tema global
    • Se aplica AppThemes.victorinoTheme.
    • Define colores, tipografías, estilos, etc.

     3. La integración con Riverpod
    VictorinoApp es un ConsumerWidget, lo que permite leer providers desde el widget raíz.

     4. Separación de responsabilidades
    • main.dart solo arranca la app.

    • Este archivo configura la app (tema + router).

     Este archivo es el “núcleo visual” de la app: define cómo se ve y cómo navega


    main.dart → VictorinoApp → MaterialApp.router → appRouterProvider → GoRouter

     */
