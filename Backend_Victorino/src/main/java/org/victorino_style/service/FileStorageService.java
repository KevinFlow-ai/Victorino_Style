package org.victorino_style.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.victorino_style.exception.FotoObligatoriaException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Set;
import java.util.UUID;

// Servicio compartido para subir y borrar fotos en el sistema de archivos del servidor.
// Lo usan los módulos de admin (empleados, servicios) y, en el futuro, el cliente.
//
// Estrategia: las fotos se guardan en `<base>/<carpeta>/<uuid>.<ext>` dentro del directorio
// de uploads que sirve Spring como recursos estáticos en /uploads/**.
// La BD persiste solo la URL relativa (ej. /uploads/empleados/abc.jpg).


//El archivo que muestras define un servicio de Spring Boot llamado FileStorageService.
// Su función es gestionar el guardado, validación y borrado de archivos de imagen que sube el usuario
@Slf4j
@Service
public class FileStorageService {

    // Carpeta raíz de uploads, configurable. Por defecto "uploads" (relativo al cwd).
    @Value("${victorino.uploads.directorio:uploads}")
    private String directorioUploads;

    // Extensiones de imagen aceptadas. Otras se rechazan con 400.
    private static final Set<String> EXTENSIONES_VALIDAS = Set.of("jpg", "jpeg", "png", "webp");

    // Tamaño máximo permitido (5 MiB). Evita subir bin de 100 MB por error.
    private static final long TAMANO_MAXIMO_BYTES = 5L * 1024 * 1024;

    // ------------------------------------------------------------------------
    // Guarda un MultipartFile en la carpeta indicada y devuelve la URL relativa.
    // Lanza FotoObligatoriaException si el archivo viene vacío o con extensión no válida.
    // ------------------------------------------------------------------------
    public String guardar(MultipartFile archivo, String subcarpeta) {
        // Validación 1: archivo no nulo y no vacío.
        if (archivo == null || archivo.isEmpty()) {
            throw new FotoObligatoriaException();
        }
        // Validación 2: tamaño dentro del límite.
        if (archivo.getSize() > TAMANO_MAXIMO_BYTES) {
            throw new FotoObligatoriaException("La foto supera el tamaño máximo permitido (5 MB).");
        }

        // Extrae la extensión original (en minúsculas) y valida que esté en la lista.
        String nombreOriginal = archivo.getOriginalFilename();
        String extension = extraerExtension(nombreOriginal);
        if (!EXTENSIONES_VALIDAS.contains(extension)) {
            throw new FotoObligatoriaException(
                    "Formato de imagen no soportado. Usa JPG, PNG o WEBP.");
        }

        try {
            // Asegura que la carpeta destino existe.
            Path carpetaDestino = Paths.get(directorioUploads, subcarpeta).toAbsolutePath().normalize();
            Files.createDirectories(carpetaDestino);

            // Genera un nombre único basado en UUID para evitar colisiones.
            String nombreFinal = UUID.randomUUID() + "." + extension;
            Path destino = carpetaDestino.resolve(nombreFinal);

            // Copia el contenido del MultipartFile al disco.
            archivo.transferTo(destino.toFile());

            // Devuelve la URL relativa lista para guardar en BD.
            String urlRelativa = "/uploads/" + subcarpeta + "/" + nombreFinal;
            log.debug("Foto guardada en {}", urlRelativa);
            return urlRelativa;
        } catch (IOException ex) {
            log.error("Error guardando la foto en disco", ex);
            throw new FotoObligatoriaException("No se pudo guardar la foto. Intenta de nuevo.");
        }
    }

    // ------------------------------------------------------------------------
    // Borra del disco la foto cuya URL relativa se pasa. Si no existe, no hace nada.
    // Se llama al sustituir la foto antigua por una nueva.
    // ------------------------------------------------------------------------
    public void borrarSiExiste(String urlRelativa) {
        if (urlRelativa == null || urlRelativa.isBlank()) return;
        if (!urlRelativa.startsWith("/uploads/")) return;
        try {
            // /uploads/empleados/abc.jpg → uploads/empleados/abc.jpg
            String ruta = urlRelativa.replaceFirst("^/", "");
            Path archivo = Paths.get(ruta).toAbsolutePath().normalize();
            Files.deleteIfExists(archivo);
        } catch (IOException ex) {
            log.warn("No se pudo borrar la foto antigua {}: {}", urlRelativa, ex.getMessage());
        }
    }

    // Extrae la extensión final del nombre del archivo, en minúsculas. Si no la tiene devuelve "".
    private String extraerExtension(String nombre) {
        if (nombre == null) return "";
        int idx = nombre.lastIndexOf('.');
        if (idx < 0 || idx == nombre.length() - 1) return "";
        return nombre.substring(idx + 1).toLowerCase();
    }

    // Reemplaza una foto: borra la antigua y guarda la nueva. Devuelve la nueva URL.
    public String reemplazar(MultipartFile nueva, String subcarpeta, String urlAntigua) {
        String urlNueva = guardar(nueva, subcarpeta);
        // Solo borra la antigua si la nueva se guardó correctamente.
        borrarSiExiste(urlAntigua);
        return urlNueva;
    }
}

// ============================================================================
// FileStorageService
// ----------------------------------------------------------------------------
// Servicio compartido encargado de subir, borrar y reemplazar las fotos del
// sistema. Lo usan tanto el módulo de empleados como el de servicios y, en el
// futuro, el módulo de cliente para la foto de perfil.
//
// FORMATOS ACEPTADOS:
// - JPG, JPEG, PNG y WEBP. Cualquier otro formato devuelve 400.
//
// LÍMITE DE TAMAÑO:
// - 5 MiB por archivo (4MB es el límite por defecto de Spring Multipart, 5 MB
//   se considera prudente para fotos sin mucha resolución).
//
// NOMBRES:
// - Cada archivo se guarda con un UUID aleatorio para evitar colisiones y
//   no exponer los nombres originales (privacidad).
//
// CARPETA RAÍZ:
// - Se lee de la propiedad `victorino.uploads.directorio` y por defecto es
//   `uploads/` (relativo al directorio de trabajo del proceso).
// - Spring sirve el contenido en /uploads/** ya configurado en
//   application.properties.
/*Qué es este archivo?
        Es un servicio de almacenamiento de archivos. Se encarga de:

        Validar que el archivo subido sea correcto.

        Guardarlo físicamente en una carpeta del servidor.

        Generar una URL relativa para guardarla en la base de datos.

        Borrar fotos antiguas cuando se reemplazan.

        Asegurar que solo se acepten imágenes válidas y de tamaño razonable.

 */

