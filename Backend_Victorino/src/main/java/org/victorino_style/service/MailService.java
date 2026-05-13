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


/*
    HTML PARA EL ENVIO DEL CODIGO EN EL CORREO. La vista de como se ve el codigo cuando llega al correo

    private String construirHtml(String codigo) {
        return """
                <div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;padding:32px;
                            border-radius:12px;background:#f9f9f9;border:1px solid #eee;">
                  <h2 style="color:#5C3DC5;text-align:center;">Victorino Style</h2>
                  <p style="color:#333;font-size:16px;text-align:center;">
                    Hemos recibido una solicitud para restablecer tu contraseña.<br>
                    Introduce el siguiente código en la app:
                  </p>
                  <div style="text-align:center;margin:32px 0;">
                    <span style="font-size:40px;font-weight:bold;letter-spacing:12px;
                                 color:#5C3DC5;background:#EDE9FF;padding:16px 24px;
                                 border-radius:8px;">%s</span>
                  </div>
                  <p style="color:#888;font-size:13px;text-align:center;">
                    Este código expira en <strong>15 minutos</strong>.<br>
                    Si no has solicitado este cambio, ignora este correo.
                  </p>
                  <hr style="border:none;border-top:1px solid #eee;margin:24px 0;">
                  <p style="color:#bbb;font-size:11px;text-align:center;">
                    © 2026 Victorino Style – Peluquería
                  </p>
                </div>
                """.formatted(codigo);
    }

 */