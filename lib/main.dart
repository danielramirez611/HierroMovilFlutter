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
import 'screens/home_screen.dart'; // Importa tu nueva pantalla
import 'screens/home_nino.dart'; // Importa tu nueva pantalla
import 'screens/home_gestante.dart'; // Importa tu nueva pantalla
import 'screens/home_gestor.dart'; // Importa tu nueva pantalla
import 'screens/home_administrador.dart'; // Importa tu nueva pantalla
import 'screens/role_redirect_screen.dart'; // ✅ Importa la nueva pantalla
import 'utils/verification_helper.dart';
import 'screens/administrador/PacientesPage.dart'; // ✅ Importa PACIENTES
import 'screens/administrador/TambosPage.dart'; // ✅ Importa PACIENTES
import 'screens/administrador/AsignacionTamboPage.dart'; // ✅ Importa PACIENTES
import 'screens/administrador/VisitasPage.dart'; // ✅ Importa PACIENTES
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'screens/PerfilUsuarioScreen.dart';
import 'http_override.dart'; // ✅ Clase que acepta certificados autofirmados

Future<void> verificarYSolicitarPermisos() async {
  final status = await Permission.location.status;
  if (status.isDenied || status.isPermanentlyDenied) {
    await Permission.location.request();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 👈 Necesario para await antes de runApp
  HttpOverrides.global = MyHttpOverrides(); // ✅ Aceptar certificados no válidos (modo desarrollo)
  await ApiService.loadUserSession(); // ✅ Cargar sesión guardada si existe
  await verificarYSolicitarPermisos(); // ✅ Verificar permisos de ubicación
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
      initialRoute: ApiService.currentUser != null ? '/home' : '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/dni': (context) => const DniScreen(),
        '/code': (context) => const CodeVerificationScreen(),
        '/password': (context) => const PasswordScreen(),
        '/home': (context) => const RoleRedirectScreen(), // ✅ Redirección automática por rol
        '/home_nino': (context) => const HomeNinoScreen(),
        '/home_gestante': (context) => const HomeGestanteScreen(),
        '/home_gestor': (context) => const HomeGestorScreen(),
        '/home_administrador': (context) => const HomeAdministradorScreen(),
        // Nuevas rutas
        '/pacientes': (context) => const PacientesPage(),
        '/tambos': (context) => const TambosPage(),
        '/asignacion': (context) => const AsignacionTamboPage(),
        '/visitas': (context) => const VisitasPage(),
        '/perfil': (context) => const PerfilUsuarioScreen(),

       //  '/visitas': (context) => const VisitasPage(),
      },
    );
  }
}
