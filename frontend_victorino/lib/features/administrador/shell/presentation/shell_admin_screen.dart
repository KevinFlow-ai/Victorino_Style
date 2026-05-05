// ============================================================
// ARCHIVO: shell_admin_screen.dart
// CAPA: Presentación — en Clean Architecture
// ============================================================
//
// ¿QUÉ ES ESTE ARCHIVO?
// ─────────────────────
// Este archivo es el CONTENEDOR PRINCIPAL del panel de admin.
// Es la "carcasa" o "marco" que envuelve todas las pantallas
// del administrador.
//
// Piénsalo como una aplicación de WhatsApp:
//   - Abajo hay pestañas (Chats, Estados, Llamadas)
//   - Al cambiar de pestaña, no pierdes lo que tenías
//   - Cada pestaña tiene su propia "historia" de navegación
//
// Eso es exactamente lo que hace este archivo.
//
// ¿QUÉ VE EL USUARIO?
// ─────────────────────
//  ┌─────────────────────────────────┐
//  │                                 │
//  │   Contenido de la pestaña       │
//  │   activa (body)                 │
//  │                                 │
//  │                                 │
//  │                                 │
//  ├─────────────────────────────────┤
//  │  🏠    📋    👥    📊    ⚙️     │  ← BottomNavigationBar
//  │  Ini  Serv  Usu  Reporte Config │    (WidgetInferiorAdmin)
//  └─────────────────────────────────┘
//
// ============================================================
// DIAGRAMA — CÓMO ENCAJA CON EL RESTO DE LA APP
// ============================================================
//
//  GoRouter (enrutador principal)
//         │
//         ├── /login          → LoginScreen
//         ├── /cliente/...    → App del cliente
//         └── /admin/...      → ShellAdminScreen ◄── ESTE ARCHIVO
//                                      │
//                        StatefulShellRoute.indexedStack
//                                      │
//                 ┌────────┬───────────┼──────────┬────────┐
//                 ▼        ▼           ▼           ▼        ▼
//              Pestaña1 Pestaña2   Pestaña3    Pestaña4  Pestaña5
//              Inicio   Servicios  Usuarios    Reportes  Config
//
//  Cada pestaña tiene su PROPIA pila de navegación:
//
//  Pestaña "Servicios":
//    ListaServiciosScreen          ← pantalla actual
//    └── DetalleServicioScreen     ← si navegas adentro
//        └── EditarServicioScreen  ← si navegas más adentro
//
//  Si cambias a "Usuarios" y vuelves a "Servicios",
//  sigues donde estabas (en EditarServicioScreen).
//  No se resetea. Eso es el indexedStack.
//
// ============================================================
// DIAGRAMA — FLUJO DE NAVEGACIÓN ENTRE PESTAÑAS
// ============================================================
//
//  Usuario toca pestaña 2 (Servicios)
//         │
//         ▼
//  WidgetInferiorAdmin llama alSeleccionar(2)
//         │
//         ▼
//  navigationShell.goBranch(2, initialLocation: false)
//         │                              │
//         │                   ¿es la pestaña actual?
//         │                   NO → no resetea, va a donde estaba
//         │                   SÍ → initialLocation: true
//         │                        podría resetear (ver abajo)
//         ▼
//  Flutter muestra el body de la pestaña 2
//  (su pila de navegación guardada)
//
// ============================================================

// Material es la librería de widgets de Flutter.
// Scaffold, StatelessWidget, etc. vienen de aquí.
import 'package:flutter/material.dart';

// GoRouter es la librería de navegación que usamos.
// Maneja rutas como /admin/servicios, /admin/usuarios, etc.
// StatefulNavigationShell viene de aquí.
import 'package:go_router/go_router.dart';

// Los colores de tu app definidos en un solo lugar.
// AppColors.background es el color de fondo del panel admin.
import '../../../../core/theme/app_colores.dart';

// El widget de la barra de navegación inferior.
// Es un widget propio que envuelve NavigationBar o BottomNavigationBar.
import '../../../../core/widgets_compartidos/widget_inferior_admin.dart';

// ──────────────────────────────────────────────────────────
// CLASE: ShellAdminScreen
// ──────────────────────────────────────────────────────────
// "StatelessWidget" significa que este widget NO tiene estado
// propio que cambie. No necesita setState() ni nada parecido.
// El estado (qué pestaña está activa, la pila de cada una)
// lo maneja GoRouter internamente a través de navigationShell.
//
// "Shell" en inglés = carcasa, concha, envoltura.
// Es un nombre muy común en Flutter para los layouts
// que "envuelven" otras pantallas.
class ShellAdminScreen extends StatelessWidget {

  // Constructor. "super.key" pasa la key al padre (StatelessWidget).
  // La key ayuda a Flutter a identificar widgets únicos en el árbol.
  const ShellAdminScreen({super.key, required this.navigationShell});

  // ──────────────────────────────────────────────────────
  // navigationShell
  // ──────────────────────────────────────────────────────
  // Este objeto lo provee GoRouter automáticamente cuando
  // usa StatefulShellRoute. No lo creas tú, GoRouter te lo pasa.
  //
  // ¿Qué contiene?
  //   .currentIndex → número de la pestaña activa (0,1,2,3,4)
  //   .goBranch(i)  → cambia a la pestaña i
  //   Y el widget del contenido actual de cada pestaña
  //
  // "StatefulShellRoute" = ruta de GoRouter que mantiene
  // el estado (pila de navegación) de cada rama/pestaña.
  // "indexedStack" = técnica que mantiene todos los widgets
  // montados pero solo muestra uno a la vez (como un mazo de cartas).
  final StatefulNavigationShell navigationShell;

  // ──────────────────────────────────────────────────────
  // build()
  // ──────────────────────────────────────────────────────
  // En Flutter, "build" construye la interfaz visual.
  // Se llama cada vez que Flutter necesita redibujar el widget.
  // Devuelve un árbol de widgets que Flutter convierte en píxeles.
  @override
  Widget build(BuildContext context) {

    // Scaffold es la estructura básica de una pantalla en Flutter.
    // Da soporte para: body, appBar, bottomNavigationBar, drawer, etc.
    // Es como el "esqueleto" de la pantalla.
    return Scaffold(

      // Color de fondo del panel admin.
      // Definido en AppColors para no repetir el color en cada pantalla.
      backgroundColor: AppColors.background,

      // ── BODY ──────────────────────────────────────────
      // El "body" es el contenido principal (todoo menos la barra inferior).
      // Aquí ponemos directamente el navigationShell, que se encarga
      // de mostrar la pantalla correcta según la pestaña activa.
      //
      // navigationShell ES un widget: muestra el contenido
      // de la pestaña actual usando IndexedStack internamente.
      // IndexedStack mantiene TODOS los widgets en memoria
      // pero solo hace visible uno. Por eso no se pierden las pilas.
      body: navigationShell,

      // ── BOTTOM NAVIGATION BAR ─────────────────────────
      // La barra de pestañas de abajo.
      // Es un widget propio (WidgetInferiorAdmin) que probablemente
      // usa NavigationBar (Material 3) o BottomNavigationBar.
      bottomNavigationBar: WidgetInferiorAdmin(

        // Le decimos qué pestaña está activa ahora mismo.
        // navigationShell.currentIndex es 0, 1, 2, 3 o 4.
        // WidgetInferiorAdmin lo usa para resaltar el ícono correcto.
        indiceActual: navigationShell.currentIndex,

        // Callback: función que se llama cuando el usuario
        // toca una pestaña. "i" es el índice tocado (0-4).
        //
        // "=>" función flecha (arrow function), igual que en JS.
        // Es una función de una línea que llama a goBranch.
        alSeleccionar: (i) => navigationShell.goBranch(
          i,

          // ── TRUCO IMPORTANTE ──────────────────────────
          // initialLocation: i == navigationShell.currentIndex
          //
          // Esto evalúa a true o false:
          //   Si toco la pestaña que YA está activa → true
          //   Si toco una pestaña diferente          → false
          //
          // ¿Para qué sirve?
          // Comportamiento estándar en apps móviles:
          //   - Tocas una pestaña DIFERENTE → va donde estabas
          //   - Tocas la pestaña ACTUAL (la que ya estás) →
          //     algunos hacen scroll al tope o resetean
          //
          // Con initialLocation: true cuando es la misma pestaña,
          // GoRouter puede ir al inicio de esa rama si quieres.
          // (El comentario dice que NO resetea — comportamiento esperado)
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

// ============================================================
// DIAGRAMA COMPLETO DE ARCHIVOS RELACIONADOS
// ============================================================
//
//  go_router_config.dart  (configuración de rutas)
//  └── StatefulShellRoute.indexedStack
//      ├── monta ShellAdminScreen  ◄── ESTE ARCHIVO
//      └── define 5 ramas (branches):
//          ├── Branch 0: /admin/inicio
//          ├── Branch 1: /admin/servicios  ← Feature que estamos viendo
//          ├── Branch 2: /admin/usuarios
//          ├── Branch 3: /admin/reportes
//          └── Branch 4: /admin/config
//
//  ShellAdminScreen usa:
//  ├── WidgetInferiorAdmin  (la barra de pestañas visual)
//  │   ├── ícono 0: Inicio
//  │   ├── ícono 1: Servicios
//  │   ├── ícono 2: Usuarios
//  │   ├── ícono 3: Reportes
//  │   └── ícono 4: Configuración
//  │
//  └── navigationShell (el contenido de la pestaña activa)
//      └── body de la pantalla actual
//
// ============================================================
// CONCEPTOS NUEVOS EN ESTE ARCHIVO
// ============================================================
//
//  GoRouter          → Librería de navegación para Flutter.
//                      Maneja rutas con URLs como /admin/servicios.
//                      Alternativa al Navigator de Flutter puro.
//
//  StatefulShellRoute → Tipo de ruta de GoRouter que mantiene
//                       el estado de múltiples ramas/pestañas.
//
//  indexedStack      → Técnica: mantiene todos los widgets
//                       en memoria pero solo muestra uno.
//                       Como un mazo de cartas boca abajo.
//
//  StatelessWidget   → Widget sin estado propio. Solo recibe
//                       datos y los muestra. No cambia solo.
//
//  Scaffold          → Estructura base de una pantalla Flutter.
//                       Tiene body, appBar, bottomNavigationBar, etc.
//
//  build(context)    → Métodoo que Flutter llama para construir
//                       la UI. Devuelve widgets = pixeles en pantalla.
//
//  context           → Información sobre la posición del widget
//                       en el árbol de widgets. Se usa para temas,
//                       navegación, providers, etc.
//
//  goBranch(i)       → Métodoo de GoRouter para cambiar de pestaña
//                       sin perder el estado de ninguna.
//
// ============================================================
// RESUMEN PARA NOVATOS — ¿QUÉ HACE ESTE ARCHIVO?
// ============================================================
//
//  1. Es la "carcasa" del panel admin: una barra abajo + contenido arriba.
//  2. No sabe nada de servicios, usuarios, etc. Solo maneja pestañas.
//  3. Cada pestaña recuerda dónde estabas (gracias a indexedStack).
//  4. Es el primer widget que ve el admin al entrar al panel.
//  5. Es muy corto a propósito: cada pantalla vive en su propio archivo.
// ============================================================