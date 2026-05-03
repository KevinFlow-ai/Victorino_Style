// Punto de entrada de la app. Solo se encarga de:
// 1. Inicializar Flutter.
// 2. Envolver la app en un ProviderScope para que Riverpod funcione.
// 3. Lanzar el widget raíz definido en app.dart.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Asegura que Flutter está completamente inicializado.
  // Necesario si usas plugins o inicializaciones antes de runApp().




  runApp(const ProviderScope(child: VictorinoApp()));
  // ProviderScope es el contenedor raíz de Riverpod.
  // Sin él, ningún provider funcionaría.
  //
  // VictorinoApp es el widget raíz que configura:
  // - MaterialApp.router
  // - Tema global
  // - Router (GoRouter)
}


/*
RESUMEN DEL ARCHIVO
Este archivo (main.dart) cumple tres responsabilidades esenciales:

 1. Inicializar Flutter
WidgetsFlutterBinding.ensureInitialized() garantiza que Flutter esté
completamente listo antes de ejecutar cualquier código que necesite binding
(por ejemplo, inicializar plugins).

 2. Envolver la app en un ProviderScope
Esto es obligatorio para que Riverpod funcione.
ProviderScope es el contenedor raíz donde viven todos los providers.

Sin esto, ningún provider funcionaría.

 3. Lanzar el widget raíz VictorinoApp
Ese widget (definido en app.dart) configura:

• El router global
• El tema
• El MaterialApp.router

En otras palabras:
 main.dart solo arranca la app; toda la configuración vive en VictorinoApp.

 */