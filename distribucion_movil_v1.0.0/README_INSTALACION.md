# VictorinoStyle — App Móvil v1.0.0
## 📱 Instalación en Android
### Archivo APK
- **Nombre:** `VictorinoStyle_v1.0.0.apk`
- **Tamaño:** ~74 MB
- **Versión:** 1.0.0 (build 1)
- **Android mínimo:** Android 5.0 (API 21) o superior
---
### Pasos para instalar en el móvil
#### Opción A — Desde el móvil directamente
1. Copia el archivo `VictorinoStyle_v1.0.0.apk` al móvil (por USB, WhatsApp, correo, Google Drive, etc.)
2. En el móvil, abre el gestor de archivos y localiza el APK
3. Pulsa sobre él para instalarlo
4. Si aparece el aviso **"Instalar aplicaciones de orígenes desconocidos"**, ve a:
   - `Ajustes → Aplicaciones → Instalar aplicaciones desconocidas`
   - Activa el permiso para la app desde la que estás instalando (p. ej. Gestor de archivos)
5. Pulsa **"Instalar"** y espera a que finalice
6. Pulsa **"Abrir"** para iniciar la aplicación
#### Opción B — Desde Android Studio (depuración)
```
adb install VictorinoStyle_v1.0.0.apk
```
---
### ☁️ Backend (Railway — Nube)
Esta versión conecta **directamente al backend en producción**:
- **URL:** `https://victorinostyle-production.up.railway.app/api/v1`
- **No necesitas** arrancar ningún servidor local
- **No necesitas** estar en la misma red WiFi que ningún PC
- Solo necesitas **conexión a internet** en el móvil
> ✅ Funciona desde cualquier red móvil, WiFi doméstica, etc.
---
### 🔔 Notificaciones push (Firebase)
- La app usa Firebase Cloud Messaging (FCM) para notificaciones de citas
- Las notificaciones funcionan aunque la app esté en segundo plano o cerrada
- Se requiere conexión a internet para recibirlas
---
### 📋 Notas técnicas
- Compilado con Flutter 3.x + Dart 3.x
- Firmado con clave de depuración (debug keystore) — válido para uso interno/demo
- Para publicar en Google Play se requiere firma con keystore de producción
---
### 📂 Contenido de esta carpeta
| Archivo | Descripción |
|---------|-------------|
| `VictorinoStyle_v1.0.0.apk` | APK instalable para Android |
| `README_INSTALACION.md` | Este documento de instrucciones |
---
*Generado el 25/05/2026 — TFG 2DAM — VictorinoStyle*
*Backend: Railway (https://victorinostyle-production.up.railway.app)*
