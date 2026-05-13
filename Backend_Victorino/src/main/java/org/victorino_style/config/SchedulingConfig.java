package org.victorino_style.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

// Habilita el procesamiento de @Scheduled en toda la aplicacion.
// Sin esta anotacion, los schedulers (RecordatorioScheduler, CompletadaScheduler, etc.)
// son beans de Spring pero sus metodos @Scheduled nunca se ejecutan.
//
// @EnableAsync habilita el procesamiento de @Async en toda la aplicacion.
// Permite que FirebaseService.enviarPushAsync() se ejecute en un hilo separado,
// liberando el hilo HTTP del backend inmediatamente sin esperar el ACK de Firebase.
// Esto reduce el tiempo de respuesta de ~1s a ~50ms en notificaciones push.
@Configuration
@EnableScheduling
@EnableAsync
public class SchedulingConfig {
}

