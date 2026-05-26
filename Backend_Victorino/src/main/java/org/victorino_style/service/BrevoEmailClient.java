package org.victorino_style.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.mail.MailSendException;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;

import java.util.List;
import java.util.Map;

/**
 * Cliente HTTP para la API transaccional de Brevo (antes Sendinblue).
 *
 *  usa cuando {@code victorino.mail.provider=brevo}, típicamente en
 * entornos cloud como Railway donde el SMTP saliente está bloqueado.
 * En local seguimos usando SMTP normal (Gmail, educaMadrid...).
 *
 * Documentación: https://developers.brevo.com/reference/sendtransacemail
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class BrevoEmailClient {

    private static final String BREVO_URL = "https://api.brevo.com/v3/smtp/email";

    private final RestClient.Builder restClientBuilder;

    @Value("${victorino.mail.brevo.api-key:}")
    private String apiKey;

    @Value("${victorino.mail.brevo.from-email:}")
    private String fromEmail;

    @Value("${victorino.mail.brevo.from-name:Victorino Style}")
    private String fromName;

    /**
     * Envía un correo de texto plano a través de la API HTTP de Brevo.
     * Lanza {@link MailSendException} si Brevo rechaza el envío o si hay
     * un fallo de red, para que el {@code GlobalExceptionHandler} responda 503.
     */
    public void enviarTexto(String destinatario, String asunto, String cuerpoTexto) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new MailSendException(
                    "Brevo activo pero falta 'victorino.mail.brevo.api-key' (variable VICTORINO_MAIL_BREVO_API_KEY).");
        }
        if (fromEmail == null || fromEmail.isBlank()) {
            throw new MailSendException(
                    "Brevo activo pero falta 'victorino.mail.brevo.from-email'. " +
                            "Debe ser un remitente verificado en el panel de Brevo.");
        }

        Map<String, Object> body = Map.of(
                "sender", Map.of("name", fromName, "email", fromEmail),
                "to", List.of(Map.of("email", destinatario)),
                "subject", asunto,
                "textContent", cuerpoTexto
        );

        try {
            RestClient client = restClientBuilder.build();
            ResponseEntity<String> resp = client.post()
                    .uri(BREVO_URL)
                    .header("api-key", apiKey)
                    .header("accept", "application/json")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .toEntity(String.class);
            log.info("Brevo OK ({}) destinatario={} from={}", resp.getStatusCode(), destinatario, fromEmail);
        } catch (RestClientResponseException e) {
            // Brevo devuelve JSON con {"code":"...","message":"..."} en errores 4xx.
            String body4xx = e.getResponseBodyAsString();
            log.error("Brevo HTTP {} -> {}", e.getStatusCode(), body4xx);
            throw new MailSendException(
                    "Brevo rechazo el envio (" + e.getStatusCode() + "): " + body4xx, e);
        } catch (RestClientException e) {
            log.error("Error de red enviando con Brevo", e);
            throw new MailSendException("Error de red enviando con Brevo: " + e.getMessage(), e);
        }
    }

    /** Direccion remitente configurada (para logs y correos de prueba). */
    public String getFromEmail() {
        return fromEmail;
    }
}
