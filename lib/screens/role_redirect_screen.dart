import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RoleRedirectScreen extends StatelessWidget {
  const RoleRedirectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ApiService.currentUser;
      debugPrint("🔍 Usuario actual: $user");

      if (user == null) {
        debugPrint("⚠️ No hay usuario logueado. Redirigiendo al inicio.");
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      final rol = (user['rol'] ?? user['role'])?.toString().toLowerCase();
      debugPrint("🎯 Rol detectado: $rol");

      String ruta = '/home';
      if (rol == 'niño') ruta = '/home_nino';
      else if (rol == 'gestante') ruta = '/home_gestante';
      else if (rol == 'gestor') ruta = '/home_gestor';
      else if (rol == 'administrador') ruta = '/home_administrador';

      Future.delayed(const Duration(milliseconds: 1200), () {
        Navigator.pushReplacementNamed(context, ruta);
      });
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/hierro.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.4)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logoH.png', // 👈 asegúrate de tener tu logo aquí
                  height: 100,
                ),
                const SizedBox(height: 30),
                const Text(
                  'Redirigiendo según tu perfil...',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                  ),
                ),
                const SizedBox(height: 30),
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
