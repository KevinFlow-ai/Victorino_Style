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
 * <p>Construye un {@link JavaMailSenderImpl} dinámicamente con los datos SMTP
 * guardados en la base de datos (tabla {@code peluqueria}).
 * Si aún no se han configurado, cae como fallback al
 * {@link JavaMailSender} auto-configurado desde {@code application.properties}.
 *
 * <p>Compatible con cualquier proveedor SMTP:
 * Gmail, Outlook/Hotmail, educaMadrid, Yahoo, servidores propios…
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailService {

    /** Sender fallback: auto-configurado desde application.properties. */
    private final JavaMailSender defaultMailSender;
    private final PeluqueriaRepository peluqueriaRepository;

    /** Dirección remitente por defecto (spring.mail.username en application.properties). */
    @Value("${spring.mail.username:}")
    private String defaultFromAddress;

    // ------------------------------------------------------------------------

    public void enviarCodigoRecuperacion(String destinatario, String codigo) {
        // Determinar sender y dirección "from" en un solo acceso a BD.
        final SenderInfo info = resolverSender();

        SimpleMailMessage mensaje = new SimpleMailMessage();
        mensaje.setFrom(info.from);   // OBLIGATORIO: sin "from" muchos servidores rechazan el email
        mensaje.setTo(destinatario);
        mensaje.setSubject("Recuperación de contraseña - Victorino Style");
        mensaje.setText("""
                Hola,

                Has solicitado recuperar tu contraseña en Victorino Style.

                Tu código de recuperación es:

                %s

                Este código caduca en 15 minutos.

                Si no has solicitado este cambio, puedes ignorar este correo.

                Victorino Style
                """.formatted(codigo));

        info.sender.send(mensaje);
    }

    /**
     * Envía un correo de prueba al administrador para verificar la configuración SMTP.
     * Lanza {@link org.springframework.mail.MailException} si el envío falla,
     * que el {@code GlobalExceptionHandler} convierte en HTTP 503 con el motivo exacto.
     */
    public void enviarCorreoPrueba(String destinatario) {
        final SenderInfo info = resolverSender();

        SimpleMailMessage mensaje = new SimpleMailMessage();
        mensaje.setFrom(info.from);
        mensaje.setTo(destinatario);
        mensaje.setSubject("✅ Prueba de correo - Victorino Style");
        mensaje.setText("""
                ¡Funciona correctamente!

                Este es un correo de prueba de Victorino Style.
                La configuración SMTP está activa y enviando correos sin problema.

                Servidor: %s
                Remitente: %s

                Victorino Style
                """.formatted(info.from, info.from));

        info.sender.send(mensaje);
        log.info("Correo de prueba enviado a {} desde {}", destinatario, info.from);
    }

    // ------------------------------------------------------------------------
    //  CONSTRUCCIÓN DINÁMICA DEL SENDER
    // ------------------------------------------------------------------------

    private record SenderInfo(JavaMailSender sender, String from) {}

    /**
     * Resuelve qué sender y qué dirección "from" usar.
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
