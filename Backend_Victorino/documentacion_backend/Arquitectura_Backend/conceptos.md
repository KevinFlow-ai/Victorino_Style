1) Que es @bean
   @Bean en Spring significa “este método crea y devuelve un objeto que 
   Spring debe gestionar como un componente del contenedor”.

    ¿Qué es exactamente @Bean?
    @Bean es una anotación que le dice a Spring:
        “El objeto que devuelve este método debe ser creado, inicializado y gestionado por el contenedor de Spring”. 
    Es decir, Spring lo convierte en un bean, igual que los componentes anotados con @Service, @Repository, @Component, etc.

    ¿Para qué sirve en tu caso?
    En tu clase CorsConfig, el método anotado con @Bean devuelve un objeto CorsConfigurationSource.
    Ese bean será usado automáticamente por Spring Security cuando haces:
    http.cors()
    Sin ese @Bean, Spring Security no sabría qué configuración CORS usar.

    ¿Qué hace Spring con un @Bean?
    Spring:
   • Crea el objeto (instancia del tipo devuelto por el método).
   • Lo guarda en el ApplicationContext.
   • Lo inyecta donde sea necesario (por ejemplo, en SecurityConfig).
   • Lo mantiene como singleton por defecto (una única instancia para toda la app).

   Resumen en una frase
   @Bean convierte el resultado de un método en un objeto gestionado por Spring, para que 
    pueda ser usado e inyectado en cualquier parte de la aplicación.

2) @Getter y @Setter (Lombok)
   Generan automáticamente los getters y setters de los atributos.
   Evitan escribir código repetitivo.

3) ¿Qué es un DTO?
Un DTO (Data Transfer Object) es un objeto diseñado exclusivamente para transportar 
datos entre capas de una aplicación —por ejemplo, entre el cliente (Flutter) y tu 
backend (Spring Boot)— sin contener lógica de negocio.

   Qué es exactamente un DTO 
   Un DTO es una estructura simple, normalmente con atributos y validaciones, 
   cuyo propósito es recibir o enviar información a través de la API.
   No toma decisiones, no ejecuta lógica compleja, no accede a la base de datos. 
   Solo transporta datos.

    ¿Por qué existen los DTOs?
    Porque ayudan a:
    Separar la estructura interna de tu dominio de lo que expones públicamente. 
    Validar datos de entrada antes de que lleguen a la lógica de negocio. 
    Evitar fugas de información sensible. 
    Estandarizar cómo se envían y reciben datos en la API. 
    Reducir acoplamiento entre cliente y servidor. 
4) ¿Qué es un mapper?
   Un mapper es un componente que transforma datos entre dos modelos distintos:

    Entidad → DTO
    DTO → Entidad
    Modelo interno → Modelo externo
    Objeto complejo → Objeto simplificado
    Su función es aislar la lógica de transformación, evitando
    que los controladores o servicios tengan que estar armando manualmente los objetos.

   ¿Por qué existen los mappers?
   Porque en una aplicación real:

    Las entidades JPA representan la estructura de la base de datos.
    Los DTOs representan lo que quieres enviar al frontend.
    Y esos dos mundos no deberían mezclarse.
    
    Si no usas mappers, terminas con:
    Controladores llenos de lógica de conversión.
    Servicios devolviendo entidades completas (mala práctica).
    Acoplamiento entre la BD y el frontend.
    
    Los mappers solucionan eso.
   Resumen en una frase
   Un mapper es una clase que transforma objetos de un modelo
   a otro para mantener la arquitectura limpia y evitar mezclar 
   entidades internas con datos expuestos al frontend.

5. ¿Qué pasa cuando llamas a un endpoint?
    Cuando haces una petición a un endpoint como: GET /admin/horario
    el flujo es así: Controlador → Servicio → Repositorio → Base de datos

    1) El controlador recibe la petición
    Ejemplo: 

    @GetMapping("/horario")
    public HorarioPeluqueriaResponse obtenerHorario() {
    return configuracionService.obtenerHorario();
    } El controlador no toca la base de datos.  Solo llama al servicio.

    2) El servicio ejecuta la lógica
    En ConfiguracionService
    
       public HorarioPeluqueriaResponse obtenerHorario() {
       Horario horario = horarioRepository.findFirst();
       return mapper.toResponse(horario);
       } Aquí sí se llama al repositorio.
    
    3. El repositorio accede a la base de datos
    Ejemplo típico: public interface HorarioRepository extends JpaRepository<Horario, Long> {}
    Spring Data JPA genera automáticamente las consultas SQL necesarias.
    
    4. La base de datos devuelve los datos
    El repositorio devuelve entidades → el servicio las transforma → el controlador 
    las envía como JSON.
    
    5. Entonces, ¿qué hace cada tipo de endpoint?
       GET → Lee datos
       Pero no desde el controlador.
       El controlador llama al servicio, y el servicio al repositorio.

       POST → Crea un registro
       El servicio hace algo como: repository.save(entidad);

       PUT → Actualiza un registro
       El servicio suele: 
       Buscar el registro 
       Modificarlo
       Guardarlo con save()
6. ¿Qué es una clase inmutable?

   Una clase inmutable es una clase cuyos valores no pueden cambiar después de crear el objeto. 
   Una vez que se asignan los atributos, ya no se pueden modificar.
    
   Ventajas
   Evitan errores por cambios inesperados. 
  Son más seguras en entornos concurrentes.
    
   Son ideales para DTOs, Request, Response, configuraciones, etc.
    
   Ejemplo de clase inmutable con record:
      
   public record Persona(String nombre) {}
7. ¿Qué es un Request?

   Un Request es el objeto que representa los datos que el cliente envía al 
  servidor cuando hace una petición HTTP (POST, PUT, PATCH, etc.).
    
      Ejemplo de JSON enviado por el cliente:

      {
      "fecha": "2026-05-01",
      "descripcion": "Día del Trabajo",
      "tipo": "NACIONAL"
      }
      Ejemplo de Request en Java:

      public record FestivoRequest(LocalDate fecha, String descripcion, TipoFestivo tipo) {}
8.  ¿Qué es un Response?
    Un Response es el objeto que representa los datos que el servidor devuelve al cliente.
    
      Ejemplo de JSON devuelto:

      {
      "idFestivo": 1,
      "fecha": "2026-05-01",
      "descripcion": "Día del Trabajo",
      "tipo": "NACIONAL"
      }
      Ejemplo de Response en Java:
    
      java
      public record FestivoResponse(Long idFestivo, LocalDate fecha, String descripcion, TipoFestivo tipo) {}
      ¿Por qué separar Request y Response?
      Seguridad: no expones campos internos de la entidad.
    
      Flexibilidad: puedes devolver datos distintos a los que recibes.
    
      Control: puedes validar lo que entra y formatear lo que sale. 
9. ¿Qué es un record en Java?
   Un record es una forma moderna y compacta de crear clases inmutables en Java.
    
      Genera automáticamente:
    
      Constructor, Getters (component methods), equals(), hashCode(), toString()
10. ¿QUÉ ES UN LOCK PESIMISTA?
    Es un mecanismo de bloqueo a nivel de base de datos.
    Cuando una transacción ejecuta esta consulta con PESSIMISTIC_WRITE:
    → La BD BLOQUEA las filas seleccionadas.
    → Ninguna otra transacción puede leerlas para escribirlas.
    → Evita que dos procesos modifiquen la misma cita al mismo tiempo.

    Es decir: "si yo voy a modificar estas citas, NADIE más puede tocarlas
    hasta que yo termine". Es una forma de garantizar consistencia en
    operaciones críticas.

    ¿Por qué se usa aquí?
    Porque el servicio de CANCELACIÓN MASIVA podría ejecutarse en paralelo
    (por ejemplo, dos administradores cancelando citas del mismo empleado).

    Sin este lock:
    - Dos transacciones podrían leer las mismas citas.
    - Ambas intentarían cancelarlas.
    - Podrías tener inconsistencias o errores de concurrencia.

    Con el lock pesimista:
    - La primera transacción que entra BLOQUEA las citas.
    - La segunda debe esperar a que la primera termine.
    - Se evita cancelar dos veces la misma cita.
    - Es una estrategia de "mejor prevenir que curar".
    
    
    
    
