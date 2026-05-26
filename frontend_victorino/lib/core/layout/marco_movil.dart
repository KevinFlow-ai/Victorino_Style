/*

👉👉 DESCOMENTAR ESTE CÓDIGO, SI SE QUIRE ACTIVAR EL RESPONSIVE EN WEB

👉👉 ESTE Y EN EL APP.DART TAMBIÉN



import 'package:flutter/material.dart';

import '../theme/app_colores.dart';


// Marco "móvil" responsive para pantallas grandes (web, escritorio, tablet, TV).
//
// La app está pensada para móvil. En navegadores de escritorio o pantallas
// grandes la UI se estiraba ocupando todos los píxeles disponibles y quedaba
// fea. Este widget envuelve el árbol completo de la app y ajusta el ancho
// del marco por PORCENTAJES del viewport, según cuatro tramos:
//
//   - < 600 px (móvil real, vertical u horizontal)
//        → 100 % del ancho, SIN marco (cero overhead).
//   - 600-1024 px (tablet)
//        → 75 % del ancho.
//   - 1024-1600 px (portátil / monitor estándar)
//        → 55 % del ancho.
//   - >= 1600 px (monitor grande, TV)
//        → 40 % del ancho.
//
// Los porcentajes están centralizados en constantes al principio de la clase
// para poder afinarlos en un único sitio. Los laterales se rellenan con un
// gris muy oscuro coherente con AppColors.textMain.
//
// Se aplica en una sola línea, desde el parámetro `builder` de
// MaterialApp.router en app.dart. Ninguna pantalla individual se modifica.

class MarcoMovil extends StatelessWidget {
  // ---------------------------------------------------------------------------
  //  TRAMOS Y PORCENTAJES (ajustables en un único sitio)
  // ---------------------------------------------------------------------------

  /// Por debajo de este ancho la app ocupa toda la pantalla (sin marco).
  static const double breakpointMovil = 600;

  /// Entre breakpointMovil y este valor → porcentaje de tablet.
  static const double breakpointTablet = 1024;

  /// Entre breakpointTablet y este valor → porcentaje de escritorio.
  static const double breakpointEscritorio = 1600;

  /// Porcentaje del viewport que ocupa el marco en cada tramo (0.0 - 1.0).
  static const double porcentajeTablet     = 0.75; // 75 %
  static const double porcentajeEscritorio = 0.55; // 55 %
  static const double porcentajeUltraAncho = 0.40; // 40 %

  /// Color de relleno de los laterales (cuando hay marco activo).
  static Color colorLaterales = const Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------

  /// Hijo que se envuelve. Es el `Widget? child` que pasa MaterialApp.builder.
  final Widget child;

  const MarcoMovil({super.key, required this.child});

  /// Devuelve el porcentaje aplicable según el ancho de la ventana.
  /// Expuesto como `static` para poder probarlo con `flutter test` si hace falta.
  static double porcentajeParaAncho(double anchoVentana) {
    if (anchoVentana < breakpointMovil) return 1.0;
    if (anchoVentana < breakpointTablet) return porcentajeTablet;
    if (anchoVentana < breakpointEscritorio) return porcentajeEscritorio;
    return porcentajeUltraAncho;
  }

  @override
  Widget build(BuildContext context) {
    final anchoVentana = MediaQuery.sizeOf(context).width;

    // Móvil real: pasar el child sin envolver, sin coste extra.
    if (anchoVentana < breakpointMovil) {
      return child;
    }

    final double anchoMarco = anchoVentana * porcentajeParaAncho(anchoVentana);

    // Pantallas grandes: centrar la app dentro de un marco proporcional al
    // viewport, con los laterales en gris oscuro para que la UI no quede flotando.
    return ColoredBox(
      color: colorLaterales,
      child: Center(
        child: SizedBox(
          width: anchoMarco,
          // El Material es necesario porque el child puede contener widgets
          // que requieren un ancestro Material (InkWell, Scaffold, etc.).
          child: Material(
            color: AppColors.background,
            child: child,
          ),
        ),
      ),
    );
  }
}


 */