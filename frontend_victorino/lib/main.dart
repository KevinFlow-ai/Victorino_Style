import 'package:flutter/material.dart';
import 'core/theme/app_themes.dart';
import 'features/login_admin_empleado_cliente/login_share_admin_y_empleado.dart';
import 'features/cliente/registro/registro_cliente.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Victorino Style',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.victorinoTheme,
      home: const LoginShareAdminYEmpleado(),
    );
  }
}
