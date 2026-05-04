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

