package org.victorino_style.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Path;
import java.nio.file.Paths;

// Registra explícitamente el handler para servir las fotos subidas a /uploads/.
//
// Aunque Spring Boot tiene `spring.web.resources.static-locations=file:uploads/`
// + `spring.mvc.static-path-pattern=/uploads/**`, el orden y el classpath pueden
// hacer que en algunos arranques no se sirvan correctamente. Con este config
// somos explícitos y robustos: la URL pública es siempre
// http://<host>/api/v1/uploads/<carpeta>/<archivo>
// (porque el context-path /api/v1 se aplica a todas las rutas, incluida ésta).
@Configuration
public class UploadsConfig implements WebMvcConfigurer {

    // Carpeta raíz de uploads, configurable. Por defecto "uploads" relativo al cwd.
    @Value("${victorino.uploads.directorio:uploads}")
    private String directorioUploads;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // Path absoluto de la carpeta de uploads en disco.
        Path absoluto = Paths.get(directorioUploads).toAbsolutePath().normalize();
        // file:/.../uploads/  (con barra final OBLIGATORIA para que funcione el handler)
        String location = absoluto.toUri().toString();
        if (!location.endsWith("/")) {
            location = location + "/";
        }
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations(location);
    }
}

// ============================================================================
// UploadsConfig
// ----------------------------------------------------------------------------
// Sirve los archivos subidos por FileStorageService como recursos estáticos.
//
// IMPORTANTE:
// - La carpeta de uploads vive en el directorio de trabajo del proceso Java
//   (cwd). Si arrancas con `./mvnw spring-boot:run` desde Backend_Victorino,
//   la carpeta efectiva es Backend_Victorino/uploads/.
// - El barra final en `addResourceLocations` es CRÍTICO. Sin ella, Spring no
//   resuelve el handler.
// - El context-path `/api/v1` se concatena automáticamente: la URL real
//   es http://localhost:8080/api/v1/uploads/<carpeta>/<archivo>.
// ============================================================================
