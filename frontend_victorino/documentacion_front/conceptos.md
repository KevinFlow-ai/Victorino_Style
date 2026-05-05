DTO (Data Transfer Object)
Un DTO es un objeto usado para transportar datos entre capas o entre la app y el backend.

Para qué sirve
Representa exactamente lo que envía o recibe tu API.
No contiene lógica, solo datos.
Evita mezclar modelos internos con estructuras del backend.

En tu proyecto
AuthResponseDto es un DTO:


AuthResponseDto.fromJson(resp. Data!)
El backend devuelve JSON → tú lo conviertes en un DTO → luego lo transformas en modelos internos (SesionUsuario).

El DTO es el mensajero entre tu API y tu app.



🧩 Provider de Riverpod
Un Provider es una forma de Riverpod de crear y compartir instancias entre capas de la app.

Para qué sirve
    Inyectar dependencias (repositorios, casos de uso, Dio…)
    Mantener una arquitectura limpia sin singletons globales.
    Permitir testear fácilmente.

Ejemplo tuyo

authRepositorioProvider = Provider<AuthRepositorio>((ref) {
final dio = ref.read(dioProvider);
return AuthRepositorioImpl(dio: dio);
});
Aquí Riverpod:

• Crea el repositorio.
• Le inyecta Dio.
• Lo deja disponible para cualquier parte de la app.

 Un Provider es una fábrica controlada por Riverpod.

🧩 Notifier (AsyncNotifier, StateNotifier, etc.)
Un Notifier es una clase que maneja estado + lógica para la UI.

Para qué sirve
• Gestionar estados de carga, éxito y error.
• Ejecutar casos de uso.
• Notificar a la UI cuando algo cambia.

Ejemplo tuyo

class RegistroNotifier extends AsyncNotifier<void> {

Este Notifier:
• Llama al caso de uso RegistrarCliente.
• Cambia el estado a AsyncLoading, AsyncData o AsyncError.
• La UI se actualiza automáticamente.

Un Notifier es el cerebro que conecta la UI con la lógica de negocio.



🧼 Clean Architecture en Flutter
La Clean Architecture es una forma de estructurar proyectos para que el código sea mantenible, escalable y fácil de testear.
Divide la app en capas con responsabilidades claras y evita dependencias innecesarias.

La idea principal es:

Las capas internas no dependen de las externas, pero las externas sí pueden depender de las internas.

🏗️ Estructura de Carpetas
A continuación, la estructura más común en Flutter usando Clean Architecture:
lib/
├── core/
├── features/
│    └── nombre_feature/
│          ├── domain/
│          ├── data/
│          └── presentation/
└── main.dart

Explicación de cada carpeta
📌 core/
Contiene elementos compartidos entre todas las features:

- utils (helpers, funciones comunes)
- errors (excepciones, manejo de fallos)
- usecases (casos de uso genéricos)
- theme (colores, estilos)
- widgets reutilizables


features/
Cada feature de la app tiene su propio módulo independiente.
Ejemplos: auth, users, products, home, etc.

    Dentro de cada feature se divide en 3 capas:
    
    🧠 1. domain/ (Reglas de negocio)
    Es la capa más pura. No depende de Flutter ni de paquetes externos.

    Contiene:
    
    entities/  
    Modelos puros que representan objetos del dominio.
    
    repositories/  
    Definen interfaces (abstract classes) que la capa data implementará.
    
    usecases/  
    Casos de uso que representan acciones del negocio.
    Ejemplo: LoginUser, GetProducts, UpdateProfile.
---------------------------------------------------------------------------------
    data/ (Fuentes de datos)
    Implementa lo que define domain.
    
    Contiene:
    
    models/  
    Versiones serializables de las entidades (con fromJson, toJson).
    
    datasources/  
    Acceso a datos: API, base de datos local, cache, etc.
    
    repositories_impl/  
    Implementación concreta de los repositorios definidos en domain.
    
    Esta capa sí puede usar paquetes externos (Dio, SharedPreferences, etc.).

------------------------------------------------------------------------------------
    Presentation/ (UI)
    Todo lo relacionado con la interfaz:
    
    pages/  
    Pantallas de la app.
    
    widgets/  
    Componentes visuales.
    
    state management/  
    Puede ser Bloc, Provider, Riverpod, MobX, etc.
    
    controllers / blocs / cubits  
    Manejan el estado y llaman a los casos de uso.

    🔄 Flujo de datos
    UI (presentation)
    ↓
    Controller / Bloc
    ↓
    UseCase (domain)
    ↓
    Repository (domain)
    ↓
    RepositoryImpl (data)
    ↓
    DataSource (data)






🧩 Capa de dominio (Casos de uso)
La capa de dominio contiene la lógica de negocio pura.
Aquí no hay HTTP, ni Riverpod, ni Flutter.

Para qué sirve
• Encapsular reglas de negocio.
• Ser independiente de frameworks.
• Ser testeable sin dependencias externas.

Ejemplo tuyo

class IniciarSesion {
Future<ResultadoAuth> ejecutar(Credenciales credenciales) async {
return _repositorio.iniciarSesion(credenciales);
}
}

El caso de uso:
• Recibe datos.
• Aplica validaciones si hace falta.
• Llama al repositorio.
• Devuelve un resultado.

El dominio es el corazón de tu app: reglas, no detalles técnicos.



🧩 Cómo encajan todos juntos (tu arquitectura limpia)
Aquí tienes tu flujo completo:

UI (pantalla)
↓
Notifier (maneja estado)
↓
Caso de uso (dominio)
↓
Repositorio (infraestructura)
↓
Dio (HTTP)
↓
Backend

Ejemplo real de tu app
• La UI llama a registroNotifierProvider.notifier.ejecutar().
• El Notifier llama al caso de uso RegistrarCliente.
• El caso de uso llama al repositorio AuthRepositorioImpl.
• El repositorio usa Dio para hacer la petición HTTP.
• El backend responde.
• El repositorio convierte el DTO en modelos internos.
• El Notifier actualiza el estado.
• La UI se actualiza.


// ============================================================
// GLOSARIO RÁPIDO
// ============================================================
//
//  async/await  → Esperar respuestas sin bloquear la app.
//                 La app sigue funcionando mientras espera.
//
//  Future<T>    → "Promesa" de que vas a recibir un valor T
//                 en algún momento futuro (ej: List<Servicio>).
//
//  try/catch    → "Intenta esto, y si hay error, haz esto otro."
//                 Evita que la app crashee por errores.
//
//  override     → "Estoy implementando este métoodo del contrato."
//
//  Dio          → Librería HTTP para Flutter. Hace GET, POST,
//                 PUT, DELETE al backend Spring Boot.
//
//  JWT          → Token de seguridad. Como un "pase" que Spring
//                 Boot revisa antes de darte los datos.
//                 Se manda en el header de cada petición HTTP.
//
//  FormData     → Formato especial para enviar archivos (fotos)
//                 por HTTP. Como un formulario con archivo adjunto.
//
//  Inyección    → Recibir dependencias (Dio) desde afuera en vez
//  de Depend.     de crearlas adentro. Facilita los tests.
//
//  Soft Delete  → "Borrar" sin borrar de verdad. Solo pone
//                 activo=false en MySQL. El dato sigue en la BD.
// ============================================================