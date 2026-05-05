package org.victorino_style.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.victorino_style.dto.admin.MetricasResumenResponse;
import org.victorino_style.service.MetricaService;

import java.time.LocalDate;

// Controlador REST del panel de métricas del administrador.
// Su función es exponer endpoints para obtener datos estadísticos (KPIs, gráficas, totales, etc.)
// que el frontend usará para mostrar el panel de métricas.
//
// Este controlador:
// - Expone endpoints bajo la ruta base /admin/metricas
// - Está protegido: solo usuarios con rol ADMINISTRADOR pueden acceder
// - No contiene lógica de negocio: delega toddo en MetricaService
// - Ofrece un endpoint principal que devuelve un resumen completo de métricas
//   entre dos fechas (fechaInicio y fechaFin)

@RestController // Indica que esta clase es un controlador REST. Combina @Controller + @ResponseBody.
// Todos los métodos devuelven datos directamente en formato JSON.

@RequestMapping("/admin/metricas") // Define la ruta base para todos los endpoints de este controlador.
// Ejemplo: /admin/metricas/resumen

@PreAuthorize("hasRole('ADMINISTRADOR')") // Restringe el acceso: solo usuarios con rol ADMINISTRADOR
// pueden llamar a cualquiera de los métodos de este controlador.

@RequiredArgsConstructor // Genera un constructor con los campos final.
// Spring lo usa para inyectar MetricaService automáticamente.
public class MetricaController {

    private final MetricaService metricaService; // Servicio que contiene la lógica de negocio
    // para calcular métricas, KPIs y estadísticas.

    // ---- RESUMEN DE MÉTRICAS ----
    @GetMapping("/resumen") // Métodoo HTTP: GET. Ruta completa: GET /admin/metricas/resumen
    public MetricasResumenResponse resumen(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fechaInicio,
            // @RequestParam: parámetro enviado en la URL, por ejemplo:
            // /admin/metricas/resumen?fechaInicio=2025-01-01&fechaFin=2025-01-31
            // @DateTimeFormat: indica que se espera un formato de fecha ISO (YYYY-MM-DD)

            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fechaFin) {

        return metricaService.resumen(fechaInicio, fechaFin);

        /*
        Qué hace este endpoint:
        Devuelve un objeto MetricasResumenResponse que contiene:
        - KPIs generales (total de citas, ingresos, cancelaciones, etc.)
        - Datos para gráficas (por ejemplo: citas por día, ingresos por mes)
        - Cualquier otra métrica que el panel necesite

        Flujo:
        1. Spring recibe los parámetros fechaInicio y fechaFin desde la URL.
        2. Los convierte a LocalDate gracias a @DateTimeFormat.
        3. Llama a metricaService.resumen(fechaInicio, fechaFin).
        4. El servicio calcula todas las métricas consultando la base de datos.
        5. El controlador devuelve el resumen completo como JSON.

        Este endpoint está pensado para que el frontend haga una sola llamada
        y obtenga todos los datos necesarios para pintar el panel de métricas.
        */
    }
}

