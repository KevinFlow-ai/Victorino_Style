<div align="center">

<img src="frontend_victorino/assets/logos_app/logo_app1.3.png" width="180" alt="Victorino Style"/>


# Victorino Style

### Reserva tu cita en menos tiempo del que tardas en pedir un café. ☕

![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-4.0-6DB33F?style=for-the-badge&logo=spring&logoColor=white)
![Java](https://img.shields.io/badge/Java-21-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FCM-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)

<!--
  IMAGEN H2 (hero / mockup principal)
  Sugerencia: un único mockup tipo "iPhone / Pixel" mostrando el Home del cliente
  con la card de "Tu próxima cita" visible (la del gradiente púrpura-cian).
  Idealmente exportado desde el emulador o desde Figma.
  Coloca el archivo en: documentacion/imagenes_readme/hero_mockup.png
  y descomenta la línea siguiente:
-->
<!-- <img src="documentacion/imagenes_readme/hero_mockup.png" width="320" alt="App en acción"/> -->

</div>

---

> **Tu peluquería, abierta 24/7.**
> Reserva, modifica o cancela tu cita desde el sofá. Sin llamadas. Sin esperas. Sin esfuerzo.

---

## ✨ ¿Qué es Victorino Style?

Una app multiplataforma — **Android, iOS, Linux, Windows y web** — que digitaliza por completo la experiencia de una peluquería: desde que el cliente reserva hasta que el peluquero confirma que ha terminado el servicio.

No es solo "una app de citas". Es el **sistema operativo completo del negocio**: catálogo de servicios, plantilla, agenda en tiempo real, métricas, notificaciones y todo lo necesario para que la peluquería deje de gestionarse a mano.

Cuenta con 3 roles: Administrador, Empleado y Cliente.

<div align="center">

<img src="frontend_victorino/assets/imagenes/local.png" width="640" alt="El local"/>

</div>

Landing del proyecto: https://landing-victorino-style.up.railway.app/
---

## 🎯 El problema → 💡 La solución

| Antes | Con Victorino Style |
|---|---|
| 📞 Llamar y rezar para que cojan el teléfono | 📱 Reserva en 30 segundos desde el móvil |
| ❓ Sin saber qué huecos hay disponibles | 📅 Calendario en tiempo real, siempre actualizado |
| 😬 Olvidarte de la cita y faltar | 🔔 Recordatorio automático 24 horas antes |
| 🧾 La peluquería gestionando todo a papel | 📊 Dashboard con métricas en tiempo real |

---

## 📱 Tres apps, una sola solución

<table>
<tr>
<td align="center" width="33%">

### 👤 Cliente
**Reserva sin fricción**

Wizard de 4 pasos guiados, próxima cita siempre visible, historial completo y notificaciones inteligentes.

<!--
  IMAGEN H5a (mockup del cliente)
  Sugerencia: captura del Home del cliente con la card "Mi próxima cita" visible.
-->
<img src="frontend_victorino/prototipo_de_interfaces/cliente/home_cliente_con_cita.png" width="220" alt="Home del cliente"/>

</td>
<td align="center" width="33%">

### ✂️ Empleado
**Su agenda al día**

Citas del día con estado en tiempo real, walk-ins instantáneos para clientes presenciales y perfil personalizable.

<img src="frontend_victorino/prototipo_de_interfaces/empleado/agenda_empleado.png" width="220" alt="Agenda del empleado"/>

</td>
<td align="center" width="33%">

### ⚙️ Administrador
**El control total**

Catálogo, plantilla, horarios, festivos y métricas: todo lo que el dueño necesita para tomar decisiones.

<img src="frontend_victorino/prototipo_de_interfaces/admin/estadisticas1.png" width="220" alt="Métricas admin"/>

</td>
</tr>
</table>

---

## 🚀 Funcionalidades estrella

<table>
<tr>
<td width="33%">

###  ✨ Wizard 4 pasos
Servicio · Peluquero · Día y hora · Confirmar. Reserva en menos de 30 segundos.

</td>
<td width="33%">

### 🔔 Notificaciones inteligentes
Confirmación al instante, recordatorio 24 h antes, bandeja in-app + push opcional.

</td>
<td width="33%">

### 📅 Calendario consciente
Festivos, cierre anual y descansos. Si está cerrada, no te deja reservar.

</td>
</tr>
<tr>
<td width="33%">

### 🛡️ Roles con permisos
Cliente, empleado y administrador con vistas y acciones específicas, controlados por JWT.

</td>
<td width="33%">

### 📊 Métricas en tiempo real
Asistencia, servicio más solicitado, empleado más reservado, franja horaria estrella.

</td>
<td width="33%">

### 🔒 RGPD by design
Anonimización al borrar cuenta, contraseñas BCrypt, tokens firmados, datos cifrados.

</td>
</tr>
</table>

---

## 🏗️ Cómo funciona por dentro

<div align="center">

<img src="frontend_victorino/prototipo_de_interfaces/fotos_compartidas/Arquitectura.jpeg" width="780" alt="Arquitectura del sistema"/>

</div>

**Arquitectura cliente-servidor de 3 capas** + Firebase para notificaciones.
Frontend-Flutter consume la API REST del backend Java; el backend persiste en MySQL y dispara push vía Firebase cuando hay novedades.

---

## 🛠️ Stack técnico

| Capa | Tecnologías |
|---|---|
| **Móvil / Web** | Flutter 3.41 · Dart 3.11 · Riverpod · GoRouter · Dio |
| **Backend** | Spring Boot 4 · JDK 21 · Spring Data JPA · Spring Security · jjwt |
| **Base de datos** | MySQL 8 · 15 tablas · InnoDB · Locks pesimistas + optimistas |
| **Notificaciones** | Firebase Cloud Messaging |
| **Diseño** | Material 3 · Poppins (titulares) + Roboto (cuerpo) · Púrpura `#7C4DFF` |
| **Testing** | JUnit 5 · Mockito · Flutter Test |

---

## 📸 Wizard del cliente: paso a paso para reservar una cita

> Reservar una cita es **literalmente** desplazar el dedo cuatro veces.

<div align="center">

<img src="frontend_victorino/prototipo_de_interfaces/cliente/wizar_paso1_servicio.png" width="200" alt="Paso 1 — Servicio"/>
<img src="frontend_victorino/prototipo_de_interfaces/cliente/wizar_paso2_elegir_peluquero.png" width="200" alt="Paso 2 — Peluquero"/>
<img src="frontend_victorino/prototipo_de_interfaces/cliente/wizar_paso3_elegir_fecha_hora.png" width="200" alt="Paso 3 — Día y hora"/>
<img src="frontend_victorino/prototipo_de_interfaces/cliente/wizar_paso4_resumen_cita.png" width="200" alt="Paso 4 — Confirmar"/>

</div>

---

## 🧑‍💼 Para los profesionales

<div align="center">

<table>
<tr>
<td align="center">
  <img src="frontend_victorino/prototipo_de_interfaces/admin/agenda_global.png" width="280" alt="Agenda global"/>
  <br><sub><b>Agenda global del admin</b></sub>
</td>
<td align="center">
  <img src="frontend_victorino/prototipo_de_interfaces/admin/gestion_empleado.png" width="280" alt="Gestión de empleados"/>
  <br><sub><b>Gestión de la plantilla de empleados</b></sub>
</td>
<td align="center">
  <img src="frontend_victorino/prototipo_de_interfaces/admin/estadisticas2.png" width="280" alt="Dashboard de métricas"/>
  <br><sub><b>Dashboard de métricas</b></sub>
</td>

</tr>
</table>

</div>

---

## 🌟 Roadmap

- ☑ MVP con los 3 módulos (cliente, empleado, administrador).
- ☑ Wizard de reserva en 4 pasos guiados.
- ☑ Notificaciones push (Firebase Cloud Messaging) + recordatorio 24 h.
- ☑ Métricas en tiempo real del negocio.
- ☑ Cumplimiento RGPD con anonimización por soft-delete.
- ☐ Pagos integrados (Stripe / Redsys).
- ☐ Programa de fidelización por puntos.
- ☐ Sugerencia de corte con IA a partir de selfie.
- ☐ Multi-tenant: una sola instancia para varias peluquerías.
- ☐ Intercambio de turnos entre empleados.
- ☐ Envío de notificaciones por correo electrónico.
- ☐ Sistema de reseñas para que los clientes valoren su experiencia.
- ☐ Gestión de inventario con métricas detalladas de ingresos y gastos.
- ☐ Modo oscuro y selector de idioma para personalizar la interfaz.







---
## 👨‍💻 Sobre mí

Soy un desarrollador con enfoque en **resolver problemas reales a través de la tecnología**.

¡Conectemos!

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Kevin_Flores-blue?style=for-the-badge&logo=linkedin)](https://www.linkedin.com/in/kevin-flores-full-stack-developer)


---

> *"La tecnología no sirve de nada si no ahorra tiempo y esfuerzo a las personas que la utilizan."*

<div align="center">

### Hecho con ♥ para que reservar una cita sea tan simple como un swipe. 
<br>Tu mejor versión empieza aquí con Victorino Style.

<img src="frontend_victorino/assets/logos_app/logo_app1.3.png" width="80" alt="Victorino Style"/>

</div>
