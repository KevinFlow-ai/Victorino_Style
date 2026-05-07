package org.victorino_style.service;

import lombok.RequiredArgsConstructor;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class MailService {

    private final JavaMailSender mailSender;

    public void enviarCodigoRecuperacion(String destinatario, String codigo) {
        SimpleMailMessage mensaje = new SimpleMailMessage();
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

        mailSender.send(mensaje);
    }
}