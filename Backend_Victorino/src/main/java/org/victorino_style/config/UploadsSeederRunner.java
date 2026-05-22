package org.victorino_style.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.core.io.support.ResourcePatternResolver;
import org.springframework.stereotype.Component;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Siembra el directorio configurado en {@code victorino.uploads.directorio}
 * con las imagenes de ejemplo que viven en el classpath bajo
 * {@code src/main/resources/uploads-seed/}.
 *
 * Sirve dos escenarios:
 *  - En local: al arrancar el backend por primera vez tras clonar el repo,
 *    rellena {@code uploads/} con las imagenes que necesita el seed SQL
 *    (admin.png, fotos de servicios, etc.).
 *  - En produccion (Railway): el volumen persistente {@code /app/uploads}
 *    nace vacio en cada nuevo entorno. Este runner lo poblara la primera vez
 *    y, como solo copia los archivos que no existan, las imagenes subidas
 *    por usuarios posteriormente quedan intactas.
 *
 * El runner es <b>idempotente</b>: si la imagen ya esta en disco, se omite.
 * Si algo falla, se loguea pero no se aborta el arranque (las notificaciones
 * push y otras funcionalidades no dependen de esto).
 */
@Slf4j
@Component
public class UploadsSeederRunner implements CommandLineRunner {

    // Patron que cubre cualquier archivo dentro de uploads-seed/ con cualquier
    // nivel de subcarpetas. Usar classpath*: en lugar de classpath: permite
    // resolver recursos dentro de un fat JAR de Spring Boot.
    private static final String PATRON_SEED = "classpath*:uploads-seed/**/*";
    private static final String MARCADOR = "uploads-seed/";

    @Value("${victorino.uploads.directorio}")
    private String directorioDestino;

    private final ResourcePatternResolver resolver;

    public UploadsSeederRunner(ResourceLoader resourceLoader) {
        this.resolver = new PathMatchingResourcePatternResolver(resourceLoader);
    }

    @Override
    public void run(String... args) {
        try {
            Path destinoBase = Paths.get(directorioDestino).toAbsolutePath().normalize();
            Files.createDirectories(destinoBase);

            Resource[] recursos = resolver.getResources(PATRON_SEED);
            int copiados = 0;
            int existian = 0;

            for (Resource recurso : recursos) {
                String url = recurso.getURL().toString();
                // Descarta entradas que apunten a directorios (terminan en "/").
                if (url.endsWith("/")) {
                    continue;
                }
                // Calcula la ruta relativa respecto a uploads-seed/ para
                // replicarla en el destino (p.ej. empleados/admin.png).
                int idx = url.lastIndexOf(MARCADOR);
                if (idx < 0) {
                    continue;
                }
                String relativa = url.substring(idx + MARCADOR.length());
                if (relativa.isBlank()) {
                    continue;
                }

                Path destino = destinoBase.resolve(relativa).normalize();
                // Defensa en profundidad contra path traversal.
                if (!destino.startsWith(destinoBase)) {
                    log.warn("[SEED uploads] Ruta sospechosa omitida: {}", destino);
                    continue;
                }
                if (Files.exists(destino)) {
                    existian++;
                    continue;
                }

                Files.createDirectories(destino.getParent());
                try (InputStream in = recurso.getInputStream()) {
                    Files.copy(in, destino);
                    copiados++;
                    log.info("[SEED uploads] Copiado {} -> {}", relativa, destino);
                }
            }

            log.info("[SEED uploads] Listo. Copiados: {}, ya existian: {}, base: {}",
                    copiados, existian, destinoBase);
        } catch (Exception ex) {
            // No critico: la app puede arrancar aunque falten imagenes seed.
            log.error("[SEED uploads] Error sembrando uploads (no critico)", ex);
        }
    }
}
