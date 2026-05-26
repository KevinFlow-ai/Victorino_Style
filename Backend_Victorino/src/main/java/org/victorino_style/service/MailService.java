package org.victorino_style.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.JavaMailSenderImpl;
import org.springframework.stereotype.Service;
import org.victorino_style.entity.Peluqueria;
import org.victorino_style.repository.PeluqueriaRepository;

import java.util.Properties;

/**
 * Servicio de envío de correo.
 *
 * <p>Dos modos de envío según {@code victorino.mail.provider}:
 * <ul>
 *   <li>{@code smtp} (por defecto): usa el SMTP de BD si está configurado,
 *       en caso contrario el de {@code application.properties}.
 *       Funciona en local (Gmail, educaMadrid, Outlook...).</li>
 *   <li>{@code brevo}: usa la API HTTP de Brevo a través de {@link BrevoEmailClient}.
 *       Imprescindible en Railway u otros PaaS que bloquean SMTP saliente.</li>
 * </ul>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailService {

    /** Sender fallback: auto-configurado desde application.properties. */
    private final JavaMailSender defaultMailSender;
    private final PeluqueriaRepository peluqueriaRepository;
    private final BrevoEmailClient brevoEmailClient;

    /** Dirección remitente por defecto (spring.mail.username en application.properties). */
    @Value("${spring.mail.username:}")
    private String defaultFromAddress;

    /** Proveedor activo: "smtp" (defecto) o "brevo". */
    @Value("${victorino.mail.provider:smtp}")
    private String provider;

    // ------------------------------------------------------------------------

    public void enviarCodigoRecuperacion(String destinatario, String codigo) {
        String asunto = "Recuperación de contraseña - Victorino Style";
        String cuerpo = """
                Hola,

                Has solicitado recuperar tu contraseña en Victorino Style.

                Tu código de recuperación es:

                %s

                Este código caduca en 15 minutos.

                Si no has solicitado este cambio, puedes ignorar este correo.

                Victorino Style
                """.formatted(codigo);

        enviar(destinatario, asunto, cuerpo);
    }

    /**
     * Envía un correo de prueba al administrador para verificar la configuración.
     * Lanza {@link org.springframework.mail.MailException} si el envío falla,
     * que el {@code GlobalExceptionHandler} convierte en HTTP 503 con el motivo exacto.
     */
    public void enviarCorreoPrueba(String destinatario) {
        String from = isBrevo() ? brevoEmailClient.getFromEmail() : resolverSender().from;
        String asunto = "Prueba de correo - Victorino Style";
        String cuerpo = """
                ¡Funciona correctamente!

                Este es un correo de prueba de Victorino Style.
                La configuración de envío está activa.

                Proveedor: %s
                Remitente: %s

                Victorino Style
                """.formatted(provider, from);

        enviar(destinatario, asunto, cuerpo);
        log.info("Correo de prueba enviado a {} (provider={})", destinatario, provider);
    }

    // ------------------------------------------------------------------------
    //  ENRUTAMIENTO INTERNO
    // ------------------------------------------------------------------------

    private boolean isBrevo() {
        return "brevo".equalsIgnoreCase(provider);
    }

    private void enviar(String destinatario, String asunto, String cuerpo) {
        if (isBrevo()) {
            brevoEmailClient.enviarTexto(destinatario, asunto, cuerpo);
            return;
        }

        // Camino SMTP clásico (local y servidores que permiten 587/465).
        final SenderInfo info = resolverSender();
        SimpleMailMessage mensaje = new SimpleMailMessage();
        mensaje.setFrom(info.from);
        mensaje.setTo(destinatario);
        mensaje.setSubject(asunto);
        mensaje.setText(cuerpo);
        info.sender.send(mensaje);
        log.info("Correo de prueba enviado a {} desde {}", destinatario, info.from);
    }

    // ------------------------------------------------------------------------
    //  CONSTRUCCIÓN DINÁMICA DEL SENDER
    // ------------------------------------------------------------------------

    private record SenderInfo(JavaMailSender sender, String from) {}

    /**
     * Resuelve qué sender SMTP y qué dirección "from" usar:
     * <ul>
     *   <li>Si la peluquería tiene SMTP configurado en BD → lo usa.</li>
     *   <li>Si no → fallback a application.properties.</li>
     * </ul>
     * Cualquier error al construir el sender desde BD (NPE, BD caída…)
     * se captura y se cae al fallback para que nunca salga una excepción
     * no-MailException del método que llevaría al handler 500 genérico.
     */
    private SenderInfo resolverSender() {
        try {
            return peluqueriaRepository.findFirstByOrderByIdAsc()
                    .filter(p -> p.getSmtpHost() != null && !p.getSmtpHost().isBlank()
                            && p.getSmtpPort() != null
                            && p.getSmtpUser() != null && !p.getSmtpUser().isBlank()
                            && p.getSmtpPassword() != null && !p.getSmtpPassword().isBlank())
                    .map(p -> new SenderInfo(buildSenderFromEntity(p), p.getSmtpUser()))
                    .orElseGet(() -> {
                        log.debug("Sin SMTP en BD; usando sender de application.properties (from={})",
                                defaultFromAddress);
                        return new SenderInfo(defaultMailSender, defaultFromAddress);
                    });
        } catch (Exception e) {
            // Si falla leer la BD o construir el sender, usar el fallback de app.properties.
            // Así la excepción que llega al controlador siempre es MailException, nunca NPE/500.
            log.warn("Error resolviendo sender SMTP desde BD, usando fallback: {}", e.getMessage());
            return new SenderInfo(defaultMailSender, defaultFromAddress);
        }
    }

    private JavaMailSenderImpl buildSenderFromEntity(Peluqueria p) {
        JavaMailSenderImpl impl = new JavaMailSenderImpl();
        impl.setHost(p.getSmtpHost().trim());
        impl.setPort(p.getSmtpPort());
        impl.setUsername(p.getSmtpUser().trim());
        impl.setPassword(p.getSmtpPassword());
        impl.setDefaultEncoding("UTF-8");

        Properties props = impl.getJavaMailProperties();
        props.put("mail.transport.protocol", "smtp");
        props.put("mail.smtp.auth", "true");
        // "*" confía en el certificado de CUALQUIER servidor SMTP.
        // Elimina el SSLHandshakeException de JDK 21 (Microsoft) con Gmail, Outlook, educaMadrid…
        props.put("mail.smtp.ssl.trust", "*");

        if (p.isSmtpSsl()) {
            // SSL directo — puerto 465
            props.put("mail.smtp.ssl.enable", "true");
            props.put("mail.smtp.socketFactory.port", String.valueOf(p.getSmtpPort()));
            props.put("mail.smtp.socketFactory.class", "javax.net.ssl.SSLSocketFactory");
            props.put("mail.smtp.socketFactory.fallback", "false");
        } else {
            // STARTTLS — puerto 587 (Gmail, Outlook, educaMadrid, Yahoo…)
            props.put("mail.smtp.starttls.enable", "true");
            props.put("mail.smtp.starttls.required", "true");
        }

        log.debug("Sender SMTP dinámico listo: {}:{} ssl={} from={}", p.getSmtpHost(), p.getSmtpPort(), p.isSmtpSsl(), p.getSmtpUser());
        return impl;
    }
}
