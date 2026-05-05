# Bitácora de errores — Victorino Style

> Cada incidente se registra aquí con: descripción, causa, solución, y código si aplica.
> Orden cronológico inverso: lo más reciente arriba.

---

## 2026-05-04 · Frontend — `LocaleDataException: Locale data has not been initialized`

**Síntoma**: la app crashea con pantalla roja al entrar al panel admin:
```
LocaleDataException: Locale data has not been initialized,
call initializeDateFormatting(<locale>).
```

**Causa**: las pantallas de agenda, métricas y festivos usan `DateFormat.yMMMd('es')` y `DateFormat.yMMMMEEEEd('es')`. La librería `intl` necesita que se carguen los datos de localización del idioma elegido **antes** de instanciar cualquier `DateFormat` con locale específico.

**Solución**: invocar `initializeDateFormatting('es_ES')` en `main.dart` ANTES de `runApp`. El método llega vía `package:intl/date_symbol_data_local.dart`.

**Diff**:
```dart
// ❌ Antes
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: VictorinoApp()));
}

// ✅ Después
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES');
  runApp(const ProviderScope(child: VictorinoApp()));
}
```

---

## 2026-05-04 · Frontend Riverpod 3 — `StateProvider` no está definido

**Síntoma**: `flutter analyze` reporta:
```
error - The function 'StateProvider' isn't defined - undefined_function
```

**Causa**: `flutter_riverpod 3.x` ha eliminado `StateProvider`. La API moderna apuesta por `Notifier`/`AsyncNotifier` con métodos explícitos en lugar del setter `.state =`.

**Solución**: convertir cada `StateProvider<T>` en un `NotifierProvider<MiNotifier, T>` con un método público que mute el estado.

**Diff**:
```dart
// ❌ Antes
final filtrosAgendaProvider = StateProvider<FiltrosAgenda>(
  (ref) => FiltrosAgenda(fecha: DateTime.now()),
);
// uso:
ref.read(filtrosAgendaProvider.notifier).state = nuevo;

// ✅ Después
class FiltrosAgendaNotifier extends Notifier<FiltrosAgenda> {
  @override
  FiltrosAgenda build() => FiltrosAgenda(fecha: DateTime.now());
  void establecer(FiltrosAgenda nuevo) => state = nuevo;
}

final filtrosAgendaProvider =
    NotifierProvider<FiltrosAgendaNotifier, FiltrosAgenda>(FiltrosAgendaNotifier.new);
// uso:
ref.read(filtrosAgendaProvider.notifier).establecer(nuevo);
```

---

## 2026-05-04 · Backend — Excepciones existentes como `class` vacías rompen Lombok en cascada

**Síntoma**: tras añadir handlers en `GlobalExceptionHandler` para `CitaSolapadaException` y `CitaNoModificableException`, **todo el módulo** dejó de compilar con errores en cascada del estilo:
```
error - cannot find symbol method setNombreEmpleado
error - cannot find symbol variable log
error - incompatible types: Class<CitaSolapadaException> cannot be converted to Class<? extends Throwable>
```

**Causa**: las dos excepciones existían en el repo como `class CitaSolapadaException {}` (vacías, sin extender `RuntimeException`). Al usarlas como handlers de `@ExceptionHandler`, el compilador rechaza la clase y **aborta el procesado de annotations**. Como Lombok genera setters/getters/loggers vía annotation processor, todo el código que dependía de Lombok dejó de tener esos métodos.

**Solución**: rellenar los stubs y hacer que extiendan `RuntimeException`. Lección general: **toda excepción del proyecto debe extender RuntimeException o una subclase**, nunca quedarse como `class` vacía.

**Diff**:
```java
// ❌ Antes
public class CitaSolapadaException {}

// ✅ Después
public class CitaSolapadaException extends RuntimeException {
    public CitaSolapadaException(String mensaje) { super(mensaje); }
    public CitaSolapadaException() { super("La franja horaria no está disponible."); }
}
```

**Cómo identificarlo rápido**: si Maven dice "cannot find symbol set/get…" en clases que SÍ tienen `@Getter @Setter`, no es un problema de Lombok. Mira **el primer error** del log: ahí está la causa real.

---

## 2026-05-04 · Frontend — Bottom navigation flotando en lugar de pegada al borde inferior

**Síntoma**: la barra de 5 pestañas del admin aparecía flotando con un margen de 12 px alrededor.

**Causa**: el primer borrador del `WidgetInferiorAdmin` heredaba un `SafeArea` con `margin: EdgeInsets.all(12)`, lo que la separaba del fondo del Scaffold.

**Solución**: quitar el `margin` y el `SafeArea` envolvente. El widget se pega al ancho completo y respeta el inset inferior con `MediaQuery.of(context).padding.bottom`. Las esquinas redondeadas se aplican solo arriba (`BorderRadius.vertical(top: Radius.circular(24))`) para que la barra "se enganche" al borde.

```dart
// ❌ Antes
return SafeArea(
  child: Container(
    margin: const EdgeInsets.all(12),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), ...),
    ...
  ),
);

// ✅ Después
final safeBottom = MediaQuery.of(context).padding.bottom;
return Container(
  padding: EdgeInsets.only(top: 8, bottom: 8 + safeBottom, left: 6, right: 6),
  decoration: BoxDecoration(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    ...
  ),
  ...
);
```

---

## 2026-05-04 · Backend — Tests de Mockito: `List.of(new Object[]{...})` no compila

**Síntoma**: `MetricaServiceTest.java` no compilaba con:
```
error - no suitable method found for thenReturn(List<Object>)
   inference variable E has incompatible bounds
       equality constraints: Object[]
       lower bounds: Object
```

**Causa**: en Java, al hacer `List.of(new Object[]{1L, "a"}, new Object[]{2L, "b"})` el compilador infiere `List<Object>` (mira el primer elemento como un `Object`, no como `Object[]`).

**Solución**: parametrizar explícitamente el tipo del `List.of`.

**Diff**:
```java
// ❌ Antes
when(citaRepository.rankingServicios(any(), any())).thenReturn(List.of(
    new Object[]{1L, "Corte clásico", 12L},
    new Object[]{2L, "Tinte", 5L}
));

// ✅ Después
when(citaRepository.rankingServicios(any(), any())).thenReturn(List.<Object[]>of(
    new Object[]{1L, "Corte clásico", 12L},
    new Object[]{2L, "Tinte", 5L}
));
```

---

## 2026-05-03 · Frontend Riverpod 3 — `AutoDisposeAsyncNotifier` no existe

**Síntoma**: `flutter analyze` falla con:
```
error - Classes can only extend other classes - extends_non_class
error - The function 'AutoDisposeAsyncNotifierProvider' isn't defined
```

**Causa**: en flutter_riverpod 3.3.1 las clases `AutoDisposeAsyncNotifier` y los providers `AutoDisposeAsyncNotifierProvider` se han fusionado. Ahora todos los providers se auto-disposan por defecto (o se controla con un parámetro).

**Solución**:
- `AutoDisposeAsyncNotifier<T>` → `AsyncNotifier<T>`.
- `AutoDisposeAsyncNotifierProvider<N, T>` → `AsyncNotifierProvider<N, T>`.

**Diff**:
```dart
// ❌ Antes
class LoginNotifier extends AutoDisposeAsyncNotifier<void> { ... }
final loginNotifierProvider =
    AutoDisposeAsyncNotifierProvider<LoginNotifier, void>(LoginNotifier.new);

// ✅ Después
class LoginNotifier extends AsyncNotifier<void> { ... }
final loginNotifierProvider =
    AsyncNotifierProvider<LoginNotifier, void>(LoginNotifier.new);
```

---

## 2026-05-03 · Frontend Riverpod 3 — `AsyncValue.valueOrNull` no existe

**Síntoma**: `error - The getter 'valueOrNull' isn't defined for the type 'AsyncValue<T>'`.

**Causa**: en Riverpod 3 se ha simplificado la API: `valueOrNull` se eliminó porque `value` ahora ya devuelve `T?`.

**Solución**: cambiar todas las llamadas `.valueOrNull` → `.value`.

```dart
// ❌ Antes
final sesion = ref.watch(sesionProvider).valueOrNull;

// ✅ Después
final sesion = ref.watch(sesionProvider).value;
```

---

## 2026-05-03 · Imports relativos mal contados en `registrar_cliente.dart`

**Síntoma**: `error - Target of URI doesn't exist: '../../../../core/errors/api_exception.dart'`.

**Causa**: el archivo está en `lib/features/cliente/registro/domain/casos_uso/`. Para llegar a `lib/core/` hay que subir **5 niveles** (`../../../../../`), no 4. Los imports a una feature hermana sí necesitan 4 niveles (hasta `lib/features/`).

**Solución**: contar bien los niveles:
- `casos_uso → domain → registro → cliente → features → lib` = 5 niveles para llegar a `lib/core/`.
- 4 niveles para llegar a `lib/features/<otra-feature>/`.

```dart
// ❌ Antes
import '../../../../core/errors/api_exception.dart';
import '../../../login_admin_empleado_cliente/domain/repositorios/auth_repositorio.dart';

// ✅ Después
import '../../../../../core/errors/api_exception.dart';
import '../../../../login_admin_empleado_cliente/domain/repositorios/auth_repositorio.dart';
```

---

## Plantilla para nuevos errores

```markdown
## YYYY-MM-DD · Componente — Título corto

**Síntoma**: qué falló (mensaje exacto si lo hay).

**Causa**: por qué fallaba realmente.

**Solución**: qué se cambió.

**Diff** (opcional):
\```dart
// ❌ Antes
...
// ✅ Después
...
\```
```
