import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class PerfilUsuarioScreen extends StatefulWidget {
  const PerfilUsuarioScreen({super.key});

  @override
  State<PerfilUsuarioScreen> createState() => _PerfilUsuarioScreenState();
}

class _PerfilUsuarioScreenState extends State<PerfilUsuarioScreen> with SingleTickerProviderStateMixin {
  double opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Inicia animación después de pequeño delay
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        opacity = 1.0;
      });
    });
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUser');
    ApiService.currentUser = null;
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("No hay usuario logueado")),
      );
    }

    final nombre = user['firstName'] ?? '';
    final apellido = user['lastNameP'] ?? '';
    final iniciales = '${nombre.isNotEmpty ? nombre[0] : ''}${apellido.isNotEmpty ? apellido[0] : ''}';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 600),
          opacity: opacity,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 🔷 Encabezado degradado
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 200,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "Mi Perfiles",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ),
                    ),
                    // 🧑 Avatar
                    Positioned(
                      bottom: -50,
                      left: 0,
                      right: 0,
                      child: Hero(
                        tag: 'perfil_avatar',
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.indigo,
                            child: Text(
                              iniciales.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 70),

                // 👤 Nombre y rol
                Text(
                  "$nombre $apellido".trim(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  (user['rol'] ?? user['role'] ?? '').toString().toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),

                // 📋 Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildAnimatedInfoCard(Icons.phone_android, "Número de celular", user['phone'] ?? ApiService.phone),
                      _buildAnimatedInfoCard(Icons.email_outlined, "Correo electrónico", user['email']),
                      _buildAnimatedInfoCard(Icons.security, "Rol de usuario", user['rol'] ?? user['role']),
                      _buildAnimatedInfoCard(Icons.verified_outlined, "Estado de cuenta", user['estado'] ?? 'Activo'),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 🔴 Cerrar sesión
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text("Cerrar sesión"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedInfoCard(IconData icon, String title, dynamic value) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.indigo),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          value?.toString() ?? '-',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
