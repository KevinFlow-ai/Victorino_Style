# Notificaciones — Guía completa para el subsistema

> Esta guía está pensada para ti, que llegas al proyecto sin haberlo tocado antes. Vas a encargarte del **subsistema completo de notificaciones** (push + bandeja in-app), tanto en el backend como en el cliente Flutter. No necesitas saber qué es Firebase ni FCM: aquí lo explicamos desde cero.
>
> Si en algún punto algo no encaja con la realidad del repo, gana el código. Avisa y actualizamos el doc.

## Índice

1. [Bienvenida y contexto](#1-bienvenida-y-contexto)
2. [Conceptos básicos](#2-conceptos-básicos)
3. [Arquitectura completa](#3-arquitectura-completa)
4. [Los 7 tipos de notificación](#4-los-7-tipos-de-notificación)
5. [Tus tareas (resumen ejecutivo)](#5-tus-tareas-resumen-ejecutivo)
6. [Configuración de Firebase paso a paso](#6-configuración-de-firebase-paso-a-paso)
7. [Backend — implementación detallada](#7-backend--implementación-detallada)
8. [Frontend Flutter — implementación detallada](#8-frontend-flutter--implementación-detallada)
9. [Reglas de negocio](#9-reglas-de-negocio)
10. [Diagramas de secuencia](#10-diagramas-de-secuencia)
11. [Verificación / smoke tests](#11-verificación--smoke-tests)
12. [Errores frecuentes esperados](#12-errores-frecuentes-esperados)

---

## 1 · Bienvenida y contexto

**Victorino Style** es una app de gestión de citas para una peluquería ficticia. Tres roles: cliente, empleado, administrador. Tres frentes: backend Spring Boot 4 + MySQL 8, cliente Flutter 3.41, panel admin web/móvil. Lee primero `documentacion/administrador/admin.md` si quieres el panorama general (5 minutos).

**Por qué importan las notificaciones**: el negocio gira en torno a citas. Si un cliente no recibe el recordatorio 24h antes y no aparece, perdemos dinero. Si la peluquería cancela y no se entera, cliente perdido. La notificación NO es decoración: es parte central del flujo.

### Lo que YA está hecho (no toques esto)

```
Backend_Victorino/src/main/java/org/victorino_style/
├── entity/
│   ├── Notificacion.java                ✅ entidad mapeada a `notificacion`
│   ├── DeviceTokenFcm.java              ✅ entidad mapeada a `device_token_fcm`
│   └── enums/TipoNotificacion.java      ✅ los 7 tipos
├── service/
│   └── NotificacionService.java         ✅ inserta in-app + delega push
├── repository/
│   ├── NotificacionRepository.java      ✅ findByIdDestinatario...
│   └── DeviceTokenFcmRepository.java    ✅ findByIdUsuario_Id

Backend_Victorino/src/main/resources/
└── db/schema.sql                        ✅ tablas notificacion y device_token_fcm

frontend_victorino/lib/
└── (lib/core/notifications/* ya existen pero VACÍOS)
```

### Lo que tienes que hacer (sí toca esto)

```
Backend_Victorino/src/main/java/org/victorino_style/
├── config/FirebaseConfig.java           🆕 inicializar Firebase Admin
├── service/FirebaseService.java         ✏️  reemplazar el stub TODO por código real
├── controller/NotificacionController.java 📝 actualmente vacío, hay que rellenarlo
├── scheduler/RecordatorioScheduler.java   📝 actualmente vacío, @Scheduled cada 15 min
├── dto/NotificacionResponse.java         🆕
└── dto/RegistrarDeviceTokenRequest.java  🆕

frontend_victorino/lib/
├── core/notifications/fcm_service.dart           📝 vacío, rellenar
├── core/notifications/local_notifications.dart   📝 vacío, rellenar
├── features/notificaciones/                       🆕 árbol completo
└── (modificar pubspec.yaml, main.dart, sesion_provider.dart)
```

---

## 2 · Conceptos básicos

### 2.1 Qué es FCM (Firebase Cloud Messaging)

Es el servicio de Google para enviar **notificaciones push** a dispositivos móviles y navegadores. Lo usan WhatsApp, Twitter, casi todas las apps.

**Analogía postal:**
- Tu backend = remitente.
- FCM = oficina de correos.
- Device token = dirección postal del dispositivo.
- Push = la carta que llega al móvil.

### 2.2 Qué es un device token

Una cadena de ~150 caracteres que identifica de forma única **una instalación de la app en un dispositivo**.

```
ej: dG7yKpQX3Lk:APA91bH8YcEXAMPLE-token-largo-aqui
```

- Cada vez que la app se instala/reinstala en un móvil, FCM le da un token nuevo.
- Un mismo usuario puede tener varios tokens (móvil + tablet + web).
- Se guarda en la tabla `device_token_fcm` con su `id_usuario` y `plataforma`.

### 2.3 Notificación in-app vs push

| | In-app | Push |
|---|---|---|
| **Dónde aparece** | Bandeja dentro de la app | Bandeja del sistema operativo |
| **App tiene que estar abierta** | Sí (la app la consulta) | No (FCM la entrega aunque esté cerrada) |
| **Cómo se construye** | Fila en la tabla `notificacion` (BD) | Mensaje a través de FCM |
| **Quién decide si se ve** | El usuario al abrir la bandeja | El sistema operativo según permisos |

En este proyecto: **siempre** se inserta in-app (en BD); el push es opcional según preferencias del destinatario.

### 2.4 Foreground vs background

- **Foreground**: el usuario tiene la app abierta, mirándola. FCM entrega el mensaje pero **no muestra notificación automáticamente**: la lógica Flutter decide qué hacer (lo normal: mostrar una `flutter_local_notifications`).
- **Background**: la app está cerrada o minimizada. FCM la muestra automáticamente en la bandeja del sistema. Cuando el usuario toca la notificación, abre la app.

### 2.5 Payload `data` vs `notification` en FCM

Un mensaje FCM puede llevar dos bloques:

```json
{
  "notification": { "title": "Tu cita ha sido confirmada", "body": "Mañana a las 10:00" },
  "data":         { "tipo": "CONFIRMACION_RESERVA", "idCita": "42" }
}
```

- `notification` → lo lee el sistema operativo y lo muestra automáticamente en background.
- `data` → lo lee tu código Flutter para tomar decisiones (navegar a una pantalla, refrescar la bandeja, etc.).

**Recomendación**: enviar **siempre los dos**. Así funciona en foreground y background.

### 2.6 Glosario rápido

| Término | Significado |
|---|---|
| **FCM** | Firebase Cloud Messaging — el servicio push de Google |
| **APNs** | Apple Push Notification service — el equivalente para iOS (FCM lo usa por debajo) |
| **Service Account** | Credenciales JSON que el backend usa para autenticarse contra Firebase |
| **Topic** | Canal al que los dispositivos se suscriben (no lo usamos en este proyecto, mandamos a tokens directos) |
| **Multicast** | Enviar el mismo mensaje a varios tokens en una sola llamada |

---

## 3 · Arquitectura completa

```
   Acción de negocio (Cliente reserva, admin cancela, scheduler 24h, etc.)
                                  │
                                  ▼
                ┌──────────────────────────────────┐
                │     NotificacionService          │
                │     .crearNotificacion(...)      │
                └──────────────────────────────────┘
                  │                              │
                  │ siempre                      │ si destinatario lo permite
                  ▼                              ▼
        ┌────────────────────┐       ┌──────────────────────────┐
        │   Tabla BD         │       │   FirebaseService        │
        │   `notificacion`   │       │   .enviarPush(tokens)    │
        │   (in-app)         │       └──────────┬───────────────┘
        └────────────────────┘                  │
                  │                             ▼
                  │                  ┌──────────────────────┐
                  │                  │   FCM (Firebase)     │
                  │                  └──────────┬───────────┘
                  │                             │
                  │                             ▼
                  │                  ┌──────────────────────┐
                  │                  │   Dispositivos del   │
                  │                  │   usuario (n tokens) │
                  │                  └──────────┬───────────┘
                  │                             │
                  ▼                             ▼
   ┌──────────────────────────┐    Foreground: flutter_local_notifications
   │  GET /notificaciones      │    Background: la bandeja del SO
   │  (bandeja in-app Flutter) │
   └──────────────────────────┘
```

### Componentes del sistema

| Capa | Componente | Estado | Tarea |
|---|---|---|---|
| Persistencia | tablas `notificacion`, `device_token_fcm` | ✅ creadas | nada |
| Backend service | `NotificacionService` | ✅ implementado | nada |
| Backend service | `FirebaseService` | 🟡 stub TODO | conectar SDK real |
| Backend scheduler | `RecordatorioScheduler` | 🔴 vacío | implementar |
| Backend REST | `NotificacionController` | 🔴 vacío | 3 endpoints |
| Frontend core | `fcm_service.dart`, `local_notifications.dart` | 🔴 vacíos | implementar |
| Frontend feature | `lib/features/notificaciones/` | 🔴 no existe | crear árbol completo |
| Configuración | Firebase + assets | 🔴 nada | desde cero |

---

## 4 · Los 7 tipos de notificación

| Tipo (enum) | Quién lo dispara | Destinatario | Cuándo se envía | Push? |
|---|---|---|---|---|
| `CONFIRMACION_RESERVA` | `CitaService.reservar` (cliente reserva) | Cliente | Inmediato tras crear cita | sí, si `cliente.push_activa_cliente=true` |
| `RECORDATORIO_24H` | `RecordatorioScheduler` cada 15 min | Cliente | Cuando faltan ~24h para la cita | sí, mismas reglas que arriba |
| `CANCELACION_CLIENTE` | `CitaService.cancelarPorCliente` | Empleado dueño de la cita | Inmediato | sí, si empleado fuera del rango de silencio |
| `CANCELACION_PELUQUERIA` | `CancelacionMasivaService` (admin) | Cliente | Inmediato (una por cita cancelada) | sí |
| `NUEVA_CITA_EMPLEADO` | `CitaService.crearWalkIn` (admin/empleado) | Empleado | Inmediato | sí, si empleado fuera de silencio |
| `AVISO_GENERAL` | Admin manualmente | Cualquier rol | Manual | configurable |

> Algunos disparadores aún no existen (ej. `CitaService.reservar` lo hará el módulo cliente cuando se implemente). Tú **NO los tienes que crear**: solo asegúrate de que `NotificacionService.crearNotificacion(...)` y `FirebaseService.enviarPush(...)` funcionan, y los demás módulos los irán llamando.

---

## 5 · Tus tareas (resumen ejecutivo)

### Backend — 4 tareas

1. **Configurar Firebase**: crear proyecto en consola, descargar service account, añadir dependencias a `pom.xml`, configurar `application.properties`, escribir `FirebaseConfig.java`.
2. **Conectar `FirebaseService.enviarPush(...)`**: hoy es un stub que loggea. Reemplazarlo por código real con Firebase Admin SDK (`MulticastMessage` + `sendEachForMulticast`).
3. **3 endpoints REST** en `NotificacionController.java`:
   - `GET /api/v1/notificaciones` → bandeja del usuario actual.
   - `POST /api/v1/notificaciones/{id}/leer` → marcar como leída.
   - `POST /api/v1/device-tokens` → registrar token FCM del dispositivo.
4. **`RecordatorioScheduler`**: `@Scheduled(fixedRate = 15min)`. Busca citas en ventana 24h ± 15min con estado CONFIRMADA y dispara `RECORDATORIO_24H`.

### Frontend Flutter — 5 tareas

5. **Añadir paquetes** a `pubspec.yaml`: `firebase_core`, `firebase_messaging`, `flutter_local_notifications`.
6. **Inicializar Firebase** en `main.dart` ANTES de `runApp` (con `flutterfire configure`).
7. **Registrar token FCM** al hacer login y enviarlo al backend (`POST /device-tokens`). Hook en `SesionNotifier.establecerSesion`.
8. **Manejar push en foreground** mostrando `flutter_local_notifications` (en background el SO lo hace solo).
9. **Construir bandeja in-app**: feature nueva `lib/features/notificaciones/` con Clean Architecture (data + domain + application + presentation).

---

## 6 · Configuración de Firebase paso a paso

### 6.1 Crear el proyecto en consola Firebase

1. Ir a <https://console.firebase.google.com>.
2. Click en **"Crear un proyecto"** → nombre `Victorino-Style`.
3. Desactivar Google Analytics (no lo necesitamos en v1) → **Crear**.
4. Esperar 30s.
5. En el panel izquierdo: **Build** → **Cloud Messaging** → activar.

### 6.2 Service Account Key (backend Java)

1. En consola Firebase → ⚙ icono engranaje (arriba izquierda) → **Project settings** → pestaña **Service accounts**.
2. Click en **"Generate new private key"** → confirmar → se descarga un JSON (~2 KB).
3. Renombrarlo a `victorino-firebase-key.json`.
4. Crear carpeta `Backend_Victorino/src/main/resources/firebase/` y meterlo dentro.
5. **Añadir a `.gitignore` (CRÍTICO)**:
   ```gitignore
   # Firebase service account — nunca subir
   Backend_Victorino/src/main/resources/firebase/*.json
   !Backend_Victorino/src/main/resources/firebase/.gitkeep
   ```
   Crea el `.gitkeep` vacío para que la carpeta exista en el repo.

### 6.3 Spring Boot — `pom.xml` + properties + config

**`pom.xml`** — añadir dependencia (la versión ya está en el stack del CLAUDE.md):
```xml
<dependency>
    <groupId>com.google.firebase</groupId>
    <artifactId>firebase-admin</artifactId>
    <version>9.8.0</version>
</dependency>
```

**`application.properties`** — añadir:
```properties
# ============================================================
#  FIREBASE CLOUD MESSAGING
# ============================================================
victorino.firebase.credentials-path=classpath:firebase/victorino-firebase-key.json
victorino.firebase.project-id=victorino-style
```

**`config/FirebaseConfig.java`** (crear nuevo):
```java
package org.victorino_style.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;

import jakarta.annotation.PostConstruct;
import java.io.InputStream;

// Inicializa Firebase Admin SDK al arrancar la app.
// Si las credenciales no existen, loggea pero no rompe la app: NotificacionService
// seguirá funcionando para in-app aunque el push falle.
@Slf4j
@Configuration
public class FirebaseConfig {

    @Value("${victorino.firebase.credentials-path}")
    private String credentialsPath;

    private final ResourceLoader resourceLoader;

    public FirebaseConfig(ResourceLoader resourceLoader) {
        this.resourceLoader = resourceLoader;
    }

    @PostConstruct
    public void inicializar() {
        try {
            Resource res = resourceLoader.getResource(credentialsPath);
            if (!res.exists()) {
                log.warn("[FCM] Credenciales no encontradas en {} — push deshabilitado", credentialsPath);
                return;
            }
            try (InputStream in = res.getInputStream()) {
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(in))
                        .build();
                if (FirebaseApp.getApps().isEmpty()) {
                    FirebaseApp.initializeApp(options);
                    log.info("[FCM] FirebaseApp inicializado correctamente.");
                }
            }
        } catch (Exception ex) {
            log.error("[FCM] Error al inicializar Firebase. Push deshabilitado.", ex);
        }
    }

    @Bean
    public FirebaseMessaging firebaseMessaging() {
        return FirebaseApp.getApps().isEmpty()
                ? null
                : FirebaseMessaging.getInstance();
    }
}
```

### 6.4 Android (Flutter)

1. Consola Firebase → ⚙ → **Add app** → icono Android.
2. **Android package name**: lo encuentras en `frontend_victorino/android/app/build.gradle.kts` → `applicationId`. Probablemente sea `com.example.frontend_victorino` (cámbialo a `com.victorinostyle.app` si quieres algo más limpio).
3. App nickname: `Victorino Android`. **Register app**.
4. Descargar `google-services.json` → ubicarlo en `frontend_victorino/android/app/google-services.json`.
5. Modificar `frontend_victorino/android/build.gradle.kts` (proyecto):
   ```kotlin
   plugins {
       // ya están los de Flutter
       id("com.google.gms.google-services") version "4.4.2" apply false
   }
   ```
6. Modificar `frontend_victorino/android/app/build.gradle.kts` (módulo):
   ```kotlin
   plugins {
       id("com.android.application")
       id("kotlin-android")
       id("dev.flutter.flutter-gradle-plugin")
       id("com.google.gms.google-services")  // ← añadir esta
   }
   ```
7. Verificar `minSdk` ≥ 23 (recomendado para `firebase_messaging`).

### 6.5 iOS (Flutter)

1. Consola Firebase → **Add app** → icono iOS.
2. **iOS bundle ID**: en `frontend_victorino/ios/Runner.xcodeproj/project.pbxproj` busca `PRODUCT_BUNDLE_IDENTIFIER`. Pon `com.victorinostyle.app`.
3. Descargar `GoogleService-Info.plist` → arrastrar dentro de `Runner/` en Xcode (no copiar manualmente; usar Xcode para que lo añada al target).
4. **APNs Auth Key (para push real en iOS)**:
   - En cuenta de Apple Developer → **Keys** → crear key con APNs activado → descargar `.p8`.
   - En Firebase consola → ⚙ → **Cloud Messaging** → tab **iOS app configuration** → subir el `.p8`, indicar Key ID y Team ID.
5. En Xcode: Runner → **Signing & Capabilities** → añadir **Push Notifications** y **Background Modes** (marcar "Remote notifications").

### 6.6 Web (Flutter web — opcional v1)

Si la app web va a recibir push también:

1. Consola Firebase → **Add app** → icono Web.
2. Copiar el objeto `firebaseConfig` que aparece.
3. Crear `frontend_victorino/web/firebase-messaging-sw.js`:
   ```javascript
   importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
   importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

   firebase.initializeApp({ /* el config copiado */ });
   firebase.messaging();
   ```
4. Generar VAPID key en consola Firebase → Cloud Messaging → tab Web Configuration.
5. Pasarla al inicializar `FirebaseMessaging` en Flutter (lo veremos en §8.3).

### 6.7 Generar `firebase_options.dart` con FlutterFire CLI

Para no copiar manualmente las claves de cada plataforma, FlutterFire tiene un CLI que lo genera automáticamente:

```bash
# Una sola vez, instalación global
dart pub global activate flutterfire_cli

# Dentro del proyecto Flutter
cd frontend_victorino
flutterfire configure --project=victorino-style
# ↑ pregunta qué plataformas quieres y genera lib/firebase_options.dart
```

Eso te permite usar `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` en `main.dart`.

---

## 7 · Backend — implementación detallada

### 7.1 Tarea 1: `FirebaseConfig.java`

Ya está el snippet completo en §6.3. Repaso:
- `@PostConstruct` carga las credenciales al arrancar.
- Si fallan, loggea pero la app sigue arrancando (push deshabilitado, in-app sigue funcionando).
- Bean `FirebaseMessaging` para inyectar en `FirebaseService`.

### 7.2 Tarea 2: conectar `FirebaseService.enviarPush(...)` real

Sustituir el stub actual:

```java
package org.victorino_style.service;

import com.google.firebase.messaging.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.victorino_style.entity.enums.TipoNotificacion;
import org.victorino_style.repository.DeviceTokenFcmRepository;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class FirebaseService {

    // FirebaseMessaging puede ser null si Firebase no se inicializó. Lo manejamos.
    @Autowired(required = false)
    private FirebaseMessaging firebaseMessaging;

    private final DeviceTokenFcmRepository deviceTokenFcmRepository;

    public boolean enviarPush(List<String> tokensFcm,
                              String titulo,
                              String cuerpo,
                              TipoNotificacion tipo) {

        if (firebaseMessaging == null) {
            log.warn("[FCM] Firebase no inicializado. Saltando push.");
            return false;
        }
        if (tokensFcm == null || tokensFcm.isEmpty()) {
            return false;
        }

        // Construye el mensaje multicast (un solo envío para varios tokens).
        MulticastMessage mensaje = MulticastMessage.builder()
                .setNotification(Notification.builder()
                        .setTitle(titulo)
                        .setBody(cuerpo)
                        .build())
                .putData("tipo", tipo.name())
                .addAllTokens(tokensFcm)
                .build();

        try {
            BatchResponse resp = firebaseMessaging.sendEachForMulticast(mensaje);
            log.info("[FCM] Enviado: éxito={}, fallo={}", resp.getSuccessCount(), resp.getFailureCount());

            // Limpia tokens muertos (NotRegistered, InvalidArgument).
            List<SendResponse> respuestas = resp.getResponses();
            for (int i = 0; i < respuestas.size(); i++) {
                SendResponse r = respuestas.get(i);
                if (!r.isSuccessful()) {
                    MessagingErrorCode code = r.getException().getMessagingErrorCode();
                    if (code == MessagingErrorCode.UNREGISTERED || code == MessagingErrorCode.INVALID_ARGUMENT) {
                        deviceTokenFcmRepository.deleteByTokenFcm(tokensFcm.get(i));
                        log.info("[FCM] Token muerto eliminado: {}", tokensFcm.get(i));
                    }
                }
            }
            return resp.getSuccessCount() > 0;

        } catch (FirebaseMessagingException ex) {
            log.error("[FCM] Error al enviar push", ex);
            return false;
        }
    }
}
```

**Ojo**: necesitas añadir `deleteByTokenFcm` a `DeviceTokenFcmRepository.java`:
```java
@Modifying
@Transactional
void deleteByTokenFcm(String tokenFcm);
```

### 7.3 Tarea 3: tres endpoints REST

**DTO `NotificacionResponse.java`** (dto/admin o dto/notificaciones):
```java
package org.victorino_style.dto;

import org.victorino_style.entity.enums.TipoNotificacion;
import java.time.Instant;

public record NotificacionResponse(
        Long idNotificacion,
        TipoNotificacion tipo,
        String titulo,
        String cuerpo,
        Long idCitaRelacionada,   // puede ser null
        Instant fechaCreacion,
        Instant fechaLectura,     // null si no leída
        boolean enviadaPush
) {}
```

**DTO `RegistrarDeviceTokenRequest.java`**:
```java
package org.victorino_style.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.victorino_style.entity.enums.PlataformaFcm;

public record RegistrarDeviceTokenRequest(
        @NotBlank String token,
        @NotNull  PlataformaFcm plataforma
) {}
```

**Controller** `controller/NotificacionController.java`:
```java
package org.victorino_style.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.victorino_style.dto.NotificacionResponse;
import org.victorino_style.dto.RegistrarDeviceTokenRequest;
import org.victorino_style.service.NotificacionService;

import java.util.List;

// Endpoints transversales: cualquier usuario autenticado puede consultarlos.
// El filtro JWT ya pone el correo en el SecurityContext.
@RestController
@RequestMapping("/notificaciones")  // y para device-tokens hace falta otro mapping (ver abajo)
@RequiredArgsConstructor
public class NotificacionController {

    private final NotificacionService notificacionService;

    @GetMapping
    public List<NotificacionResponse> bandeja() {
        return notificacionService.bandejaUsuarioActual();
    }

    @PostMapping("/{id}/leer")
    public ResponseEntity<Void> marcarLeida(@PathVariable Long id) {
        notificacionService.marcarLeida(id);
        return ResponseEntity.noContent().build();
    }
}
```

**Controller** `controller/DeviceTokenController.java` (separado por claridad):
```java
@RestController
@RequestMapping("/device-tokens")
@RequiredArgsConstructor
public class DeviceTokenController {
    private final DeviceTokenService deviceTokenService;

    @PostMapping
    public ResponseEntity<Void> registrar(@Valid @RequestBody RegistrarDeviceTokenRequest req) {
        deviceTokenService.registrar(req.token(), req.plataforma());
        return ResponseEntity.noContent().build();
    }
}
```

Tendrás que crear también `DeviceTokenService` con `registrar(token, plataforma)`. Lógica:
- Resolver el `Usuario` actual desde `SecurityContextHolder`.
- Si el token ya existe: ignorar (UNIQUE en BD).
- Si no: insertar fila en `device_token_fcm`.

**Añadir métodos a `NotificacionService`** (que hoy solo tiene `crearNotificacion`):

```java
// Devuelve la bandeja del usuario que llamó.
public List<NotificacionResponse> bandejaUsuarioActual() {
    Usuario u = obtenerUsuarioActual();
    return notificacionRepository
            .findByIdDestinatarioNotificacion_IdOrderByFechaCreacionNotificacionDesc(u.getId())
            .stream()
            .map(this::aRespuesta)
            .toList();
}

@Transactional
public void marcarLeida(Long idNotificacion) {
    Usuario u = obtenerUsuarioActual();
    Notificacion n = notificacionRepository.findById(idNotificacion)
            .orElseThrow(() -> new RecursoNoEncontradoException("Notificación no encontrada"));
    if (!n.getIdDestinatarioNotificacion().getId().equals(u.getId())) {
        throw new AccessDeniedException("No es tuya");
    }
    n.setFechaLecturaNotificacion(Instant.now());
    notificacionRepository.save(n);
}
```

### 7.4 Tarea 4: `RecordatorioScheduler`

```java
package org.victorino_style.scheduler;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.victorino_style.entity.Cita;
import org.victorino_style.entity.enums.EstadoCita;
import org.victorino_style.entity.enums.TipoNotificacion;
import org.victorino_style.repository.CitaRepository;
import org.victorino_style.service.NotificacionService;

import java.time.LocalDateTime;
import java.util.List;

// Ejecuta cada 15 minutos. Busca citas en la ventana [ahora+24h, ahora+24h+15min)
// con estado CONFIRMADA y dispara RECORDATORIO_24H.
@Slf4j
@Component
@RequiredArgsConstructor
public class RecordatorioScheduler {

    private final CitaRepository citaRepository;
    private final NotificacionService notificacionService;

    // 15 minutos = 900_000 ms. Inicio diferido tras arrancar la app.
    @Scheduled(fixedRate = 15 * 60 * 1000, initialDelay = 60 * 1000)
    public void disparar() {
        LocalDateTime desde = LocalDateTime.now().plusHours(24);
        LocalDateTime hasta = desde.plusMinutes(15);

        List<Cita> citas = citaRepository.findCitasEnVentana(desde, hasta, EstadoCita.CONFIRMADA);
        log.info("[RecordatorioScheduler] Citas en ventana 24h: {}", citas.size());

        for (Cita c : citas) {
            // Solo notificamos a clientes registrados (no walk-in).
            if (c.getIdCliente() == null) continue;

            try {
                notificacionService.crearNotificacion(
                        c.getIdCliente().getUsuario(),
                        c,
                        TipoNotificacion.RECORDATORIO_24H,
                        "Recordatorio: tu cita es mañana",
                        "Te esperamos el " + c.getFechaCita() + " a las " + c.getHoraInicioCita()
                );
            } catch (Exception ex) {
                log.warn("Recordatorio falló para cita id={}", c.getId(), ex);
            }
        }
    }
}
```

**`@EnableScheduling`**: si no está ya en `BackendVictorinoApplication.java`, añádelo:
```java
@SpringBootApplication
@EnableScheduling   // ← este
public class BackendVictorinoApplication { ... }
```

**Query en `CitaRepository`** (añadir):
```java
@Query("""
       SELECT c FROM Cita c
       WHERE c.estadoCita = :estado
         AND CONCAT(c.fechaCita, 'T', c.horaInicioCita) BETWEEN :desde AND :hasta
       """)
List<Cita> findCitasEnVentana(@Param("desde") LocalDateTime desde,
                              @Param("hasta") LocalDateTime hasta,
                              @Param("estado") EstadoCita estado);
```

> Nota: la query con CONCAT puede no ser óptima en MySQL. Si ves problemas de rendimiento, sustituye por una columna calculada `fecha_hora_inicio` en BD.

### 7.5 Tarea 5: limpieza de tokens muertos

Ya cubierto en §7.2: `deleteByTokenFcm` se llama desde `FirebaseService` cuando FCM responde `UNREGISTERED` o `INVALID_ARGUMENT`. Garantiza que la tabla no se llena de tokens obsoletos.

---

## 8 · Frontend Flutter — implementación detallada

### 8.1 `pubspec.yaml`

```yaml
dependencies:
  # ya están: flutter_riverpod, go_router, dio, etc.
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^17.2.3
```

Tras añadirlas: `flutter pub get`.

### 8.2 `main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: VictorinoApp()));
}
```

### 8.3 `core/notifications/fcm_service.dart`

```dart
// Encapsula toda la interacción con Firebase Messaging.
// Rol: obtener tokens, suscribirse a eventos, pero NO sabe nada de la BD ni del dominio.
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  final FirebaseMessaging _fm = FirebaseMessaging.instance;

  // Pide permisos de notificaciones (iOS/macOS) y devuelve el estado.
  Future<NotificationSettings> pedirPermisos() async {
    return _fm.requestPermission(alert: true, badge: true, sound: true);
  }

  // Devuelve el token FCM actual del dispositivo. null si todavía no está disponible.
  // En web hace falta pasar la VAPID key:
  //   _fm.getToken(vapidKey: '<TU_VAPID_KEY>')
  Future<String?> obtenerToken() async {
    if (kIsWeb) {
      return _fm.getToken(vapidKey: const String.fromEnvironment('FCM_VAPID_KEY'));
    }
    return _fm.getToken();
  }

  // Se llama cuando FCM rota el token (raro pero pasa).
  Stream<String> alCambiarToken() => _fm.onTokenRefresh;

  // Mensaje recibido con la app abierta (foreground).
  Stream<RemoteMessage> alRecibirEnForeground() => FirebaseMessaging.onMessage;

  // Mensaje que abrió la app (el usuario tocó la notificación).
  Stream<RemoteMessage> alAbrirApp() => FirebaseMessaging.onMessageOpenedApp;
}
```

### 8.4 `core/notifications/local_notifications.dart`

Solo se usa para mostrar la notificación cuando llega en **foreground** (en background lo hace el SO solo).

```dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotifications {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _inicializado = false;

  Future<void> inicializar() async {
    if (_inicializado) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    _inicializado = true;
  }

  Future<void> mostrar({required String titulo, required String cuerpo, String? payload}) async {
    if (!_inicializado) await inicializar();
    const detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        'victorino_default',
        'Notificaciones',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, titulo, cuerpo, detalles, payload: payload);
  }
}
```

### 8.5 Submódulo `lib/features/notificaciones/`

Estructura Clean Architecture (igual que el resto del proyecto):

```
notificaciones/
├── data/
│   ├── modelos/notificacion_dto.dart
│   └── repositorios/notificaciones_repositorio_impl.dart
├── domain/
│   ├── entidades/notificacion.dart
│   ├── repositorios/notificaciones_repositorio.dart
│   └── casos_uso/
│       ├── obtener_bandeja.dart
│       ├── marcar_leida.dart
│       └── registrar_device_token.dart
├── application/
│   ├── notificaciones_providers.dart
│   └── notificaciones_notifier.dart        // AsyncNotifier<List<Notificacion>>
└── presentation/
    ├── bandeja_notificaciones_screen.dart
    └── widgets/notificacion_card.dart
```

**Patrones a seguir** (mira `features/administrador/empleados/` como referencia):
- DTO con `fromJson` y `aEntidad`.
- Repositorio impl con Dio + ErrorMapper.
- Casos de uso one-liners con validación mínima.
- AsyncNotifier para la bandeja, con `recargar()`.

### 8.6 Hooks en `SesionNotifier`

Tras login, registrar el token. Tras logout, idealmente invalidarlo (futuro endpoint).

En `lib/shared/providers/sesion_provider.dart`:

```dart
Future<void> establecerSesion(SesionUsuario sesion, String refreshToken) async {
  // ... lo que ya hace ...

  // NUEVO: registrar device token FCM en el backend.
  try {
    final fcmService = ref.read(fcmServiceProvider);
    await fcmService.pedirPermisos();
    final token = await fcmService.obtenerToken();
    if (token != null) {
      await ref.read(registrarDeviceTokenProvider).ejecutar(
            token: token,
            plataforma: _plataformaActual(),
          );
    }
  } catch (e) {
    // Push opcional: si falla, la app sigue funcionando con in-app.
    debugPrint('No se pudo registrar token FCM: $e');
  }
}
```

### 8.7 Manejar push en foreground

En `app.dart` (después de inicializar Firebase):

```dart
// Listener global para foreground.
FirebaseMessaging.onMessage.listen((msg) {
  final notif = msg.notification;
  if (notif != null) {
    ref.read(localNotificationsProvider).mostrar(
      titulo: notif.title ?? 'Notificación',
      cuerpo: notif.body ?? '',
      payload: msg.data['tipo'],
    );
  }
  // También podrías refrescar la bandeja in-app aquí:
  ref.read(notificacionesNotifierProvider.notifier).recargar();
});
```

---

## 9 · Reglas de negocio

### 9.1 In-app SIEMPRE
Por cada acción que dispare notificación, **debe existir una fila** en `notificacion`. Aunque el push falle (Firebase caído, sin tokens, lo que sea), la fila se inserta. La fuente de verdad es la tabla, no el push.

### 9.2 Push según preferencias

**Cliente**:
```
push_activa_cliente == true  →  enviar push
push_activa_cliente == false →  solo in-app
```

**Empleado/Administrador**:
```
no_molestar_empleado == true                 →  solo in-app
hora_actual ∈ [silencio_inicio, silencio_fin] → solo in-app
en cualquier otro caso                       → enviar push
```

Esta lógica YA está implementada en `NotificacionService.deboEnviarPush(...)`. No la toques.

### 9.3 Walk-in invitados

Los `cliente_invitado` no tienen `Usuario`, por tanto **no se les notifica**. La cita walk-in solo notifica al **empleado** que la atiende (`NUEVA_CITA_EMPLEADO`).

### 9.4 Tokens múltiples por usuario

Un usuario puede tener varios `device_token_fcm` (móvil + tablet + web). Push se envía a TODOS sus tokens en una sola llamada multicast.

### 9.5 Upsert en `POST /device-tokens`

Si el mismo token llega dos veces (ej. usuario reinstala la app), el `UNIQUE` en `device_token_fcm.token_fcm` rechaza el insert. **No es un error**: tu endpoint debe interpretarlo como "ya está registrado, todo OK".

```java
public void registrar(String token, PlataformaFcm plataforma) {
    Usuario u = obtenerUsuarioActual();
    if (deviceTokenFcmRepository.existsByTokenFcm(token)) {
        return; // ya registrado, idempotente
    }
    DeviceTokenFcm fila = new DeviceTokenFcm();
    fila.setIdUsuario(u);
    fila.setTokenFcm(token);
    fila.setPlataformaFcm(plataforma);
    fila.setFechaAltaFcm(Instant.now());
    deviceTokenFcmRepository.save(fila);
}
```

---

## 10 · Diagramas de secuencia

### 10.1 Cliente reserva una cita → CONFIRMACION_RESERVA

```
Cliente         CitaService      NotificacionService    BD `notificacion`    FirebaseService    FCM      Móvil cliente
   │                │                    │                      │                    │             │              │
   │ POST /citas    │                    │                      │                    │             │              │
   ├───────────────►│                    │                      │                    │             │              │
   │                │ crearNotificacion  │                      │                    │             │              │
   │                │   (CONFIRMACION_RESERVA)                  │                    │             │              │
   │                ├───────────────────►│                      │                    │             │              │
   │                │                    │ INSERT notificacion  │                    │             │              │
   │                │                    ├─────────────────────►│                    │             │              │
   │                │                    │ ¿push? sí (push_activa_cliente=true)      │             │              │
   │                │                    │ tokens = SELECT device_token_fcm WHERE id_usuario = ?  │             │              │
   │                │                    │ enviarPush(tokens, "Cita confirmada", ...)             │             │              │
   │                │                    ├─────────────────────────────────────────►│             │              │
   │                │                    │                      │                    │ multicast   │              │
   │                │                    │                      │                    ├────────────►│              │
   │                │                    │                      │                    │             │ entrega push │
   │                │                    │                      │                    │             ├─────────────►│
   │                │                    │ UPDATE notificacion SET enviada_push=true               │              │
   │                │                    ├─────────────────────►│                    │             │              │
```

### 10.2 RecordatorioScheduler cada 15 min

```
@Scheduled(fixedRate=15min)
        │
        ▼
RecordatorioScheduler.disparar()
        │
        ▼
CitaRepository.findCitasEnVentana(ahora+24h, ahora+24h+15min, CONFIRMADA)
        │
        ▼
for each cita (con cliente registrado):
        │
        ▼
NotificacionService.crearNotificacion(cliente.usuario, cita, RECORDATORIO_24H, ...)
        │
        ├── INSERT notificacion (in-app)
        └── FirebaseService.enviarPush(tokens) → FCM → móvil
```

### 10.3 Cancelación masiva (referencia cruzada)

Esto lo dispara el admin. Cada cita cancelada llama internamente a `NotificacionService.crearNotificacion(...)` con `CANCELACION_PELUQUERIA`. Para el flujo completo (lock pesimista, REQUIRES_NEW por cita, deduplicación de clientes notificados), mira [admin.md §3](admin.md#3-diagrama-de-secuencia-cancelación-masiva-de-citas).

---

## 11 · Verificación / smoke tests

### 11.1 Sin Firebase configurado todavía
- La app debe seguir arrancando sin errores fatales (gracias al try/catch en `FirebaseConfig.@PostConstruct`).
- Acción de negocio (ej. crear cita) → fila en `notificacion` aparece en BD.
- Log esperado: `[FCM] Firebase no inicializado. Saltando push.`

### 11.2 Test con Postman (backend solo)
1. Login admin → `victorino@admin.com` / `Admin1234!` → guarda accessToken.
2. Crear walk-in con admin → `POST /admin/citas/walk-in` → debe responder 201.
3. `SELECT * FROM notificacion ORDER BY id_notificacion DESC LIMIT 1` → fila tipo NUEVA_CITA_EMPLEADO.
4. Login con el empleado → `GET /api/v1/notificaciones` → debe devolver la notificación.
5. `POST /api/v1/notificaciones/{id}/leer` → 204. Volver a llamar GET → la `fechaLectura` ya no es null.

### 11.3 Test push real en Android Emulator
- Necesitas un emulador con **Google APIs / Play Services** (al crear AVD en Android Studio, elegir imagen "Google APIs", NO "Android Open Source").
- Tras login, en logs de Flutter debes ver el token FCM.
- `SELECT * FROM device_token_fcm WHERE id_usuario = ?` → fila.
- Disparar acción → push llega a la barra de notificaciones del emulador.

### 11.4 Test de tokens muertos
- Apaga el emulador y dispara una acción que envíe push. Firebase responderá `UNREGISTERED`.
- `SELECT * FROM device_token_fcm` → la fila debe haberse borrado.

---

## 12 · Errores frecuentes esperados

| Síntoma | Causa | Fix |
|---|---|---|
| `MissingPluginException` `firebase_messaging` | Falta `flutterfire configure` o `pub get` | `dart pub global activate flutterfire_cli && flutterfire configure` |
| Push no llega en iOS | Falta APNs Auth Key en consola Firebase | Subir `.p8` en Firebase consola → Cloud Messaging |
| Push no llega en Android Emulator | Imagen sin Google Play Services | Crear AVD con imagen "Google APIs" |
| `FirebaseApp not initialized` | `Firebase.initializeApp` después de `runApp` | Llamar antes de `runApp` en `main.dart` |
| Spring no encuentra credenciales | Path mal en `application.properties` | Usar `classpath:firebase/...` y verificar que el archivo existe |
| Token duplicado en BD (UNIQUE violation) | Usuario reinstaló la app | Implementar idempotencia con `existsByTokenFcm` antes del save |
| `MessagingErrorCode.UNREGISTERED` ignorado | No limpiamos tokens muertos | Implementar `deleteByTokenFcm` (§7.2) |
| `LocaleDataException` al usar fechas | `intl` sin inicializar | Ya está en `main.dart` con `initializeDateFormatting('es_ES')` |
| Recordatorio se dispara dos veces | Falta de control de "ya enviado" | Añadir flag `recordatorio_24h_enviado` a `cita` o a `notificacion` (futuro) |
| `firebase-messaging-sw.js` no se ejecuta en web | El service worker no está en `web/` | Verificar ubicación y registro |

---

## Apéndice A · Referencias cruzadas

- `admin.md` — Panorama del módulo administrador. La sección §3 detalla la cancelación masiva (uno de los principales disparadores de notificaciones).
- `api_admin.md` — Contratos REST. Tu nuevo `NotificacionController` debe seguir el mismo formato.
- `guia_junior_admin.md` — Convenciones del proyecto (paquetes, naming, estructura Clean Arch en frontend).
- `errores.md` — Bitácora general. Añade ahí cualquier error nuevo que descubras durante la integración Firebase (será de oro para los siguientes).

## Apéndice B · Checklist de entrega

Cuando termines, verifica que **todo lo siguiente funciona**:

### Backend
- [ ] La app arranca con y sin `victorino-firebase-key.json`.
- [ ] `GET /api/v1/notificaciones` devuelve la bandeja del usuario logueado (no la de otros).
- [ ] `POST /api/v1/notificaciones/{id}/leer` marca la fecha y devuelve 204.
- [ ] `POST /api/v1/device-tokens` es idempotente (no falla con duplicados).
- [ ] `RecordatorioScheduler` se ejecuta y deja log cada 15 min.
- [ ] Tokens muertos se borran de BD automáticamente.

### Frontend
- [ ] `flutter run` arranca sin errores en Android, iOS y web.
- [ ] Tras login: aparece log con el token FCM y `SELECT` en BD lo confirma.
- [ ] Push en foreground muestra `flutter_local_notifications`.
- [ ] Push en background muestra notificación del SO.
- [ ] Tap en notificación abre la app en la pantalla de bandeja (extra).
- [ ] Pantalla bandeja lista las notificaciones, las marca como leídas y refresca.

### Cualidades transversales
- [ ] El admin puede dar de baja a un empleado y los clientes afectados ven la notificación in-app inmediatamente.
- [ ] `flutter analyze` y `./mvnw test` pasan sin errores.
- [ ] El JSON de Service Account NO está en Git.

---

> Cualquier duda de contexto, escríbeme. Cualquier duda de Firebase, su [documentación oficial](https://firebase.google.com/docs/cloud-messaging) está bien escrita pero es enorme — esta guía cubre el 80% que vas a usar realmente.
