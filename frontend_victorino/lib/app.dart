// Widget raíz de la app. Configura MaterialApp.router con el tema y el router
// definidos en core/. Vive separado de main.dart para que main solo arranque.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_themes.dart';

class VictorinoApp extends ConsumerWidget {
  // ConsumerWidget permite leer providers de Riverpod dentro del build.
  const VictorinoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
RESUMEN DEL ARCHIVO
Este archivo define el widget raíz VictorinoApp, que es el punto central donde se configura:

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