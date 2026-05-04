# Bitácora de errores — Victorino Style

> Cada incidente se registra aquí con: descripción, causa, solución, y código si aplica.
> Orden cronológico inverso: lo más reciente arriba.

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
