import 'dart:io'; // ✅ Necesario para HttpOverrides
import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/dni_screen.dart';
import 'screens/code_verification_screen.dart';
import 'screens/password_screen.dart';
import 'screens/success_dialog.dart';
import 'widgets/custom_button.dart';
import 'widgets/custom_input.dart';
import 'services/api_service.dart';
import 'http_override.dart'; // ✅ Clase que acepta certificados autofirmados

void main() {
  HttpOverrides.global = MyHttpOverrides(); // ✅ Permitir certificados no válidos (solo en desarrollo)
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Niños de Hierro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Arial'),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/dni': (context) => const DniScreen(),
        '/code': (context) => const CodeVerificationScreen(),
        '/password': (context) => const PasswordScreen(),
      },
    );
  }
}
