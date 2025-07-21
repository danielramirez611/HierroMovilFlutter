import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/api_service.dart';
import '../widgets/custom_bottom_nav.dart';

class HomeAdministradorScreen extends StatefulWidget {
  const HomeAdministradorScreen({super.key});

  @override
  State<HomeAdministradorScreen> createState() =>
      _HomeAdministradorScreenState();
}

class _HomeAdministradorScreenState extends State<HomeAdministradorScreen> {
  int totalUsuarios = 0;
  int totalVisitas = 0;
  int totalComunicados = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final resUsuarios = await http.get(
        Uri.parse('${ApiService.baseUrl}/Users'),
      );
      final resVisitas = await http.get(
        Uri.parse('${ApiService.baseUrl}/VisitaDomiciliaria'),
      );
      final resComunicados = await http.get(
        Uri.parse('${ApiService.baseUrl}/Comunicado'),
      );

      setState(() {
        totalUsuarios = jsonDecode(resUsuarios.body).length;
        totalVisitas = jsonDecode(resVisitas.body).length;
        totalComunicados = jsonDecode(resComunicados.body).length;
        loading = false;
      });
    } catch (e) {
      print('❌ Error al cargar datos de administrador: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child:
            loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    // ✅ Encabezado
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 28,
                      ),
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Niños de Hierro",
                            style: TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Bienvenido administrador 🧑‍💻",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ✅ Tarjetas en GridView
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio:
                                  constraints.maxHeight < 600 ? 0.9 : 1.1,
                              children: [
                                _buildDashboardCard(
                                  title: "Pacientes",
                                  count:
                                      0, // puedes cambiar esto si deseas contar pacientes
                                  icon: Icons.person_outline,
                                  color: Colors.purple,
                                  onTap:
                                      () => Navigator.pushNamed(
                                        context,
                                        '/pacientes',
                                      ),
                                ),
                                _buildDashboardCard(
                                  title: "Visitas",
                                  count: totalVisitas,
                                  icon: Icons.home,
                                  color: Colors.teal,
                                  onTap:
                                      () => Navigator.pushNamed(
                                        context,
                                        '/visitas',
                                      ),
                                ),
                                _buildDashboardCard(
                                  title: "Tambos",
                                  count:
                                      0, // puedes cambiar esto si deseas contar tambos
                                  icon: Icons.house,
                                  color: Colors.brown,
                                  onTap:
                                      () => Navigator.pushNamed(
                                        context,
                                        '/tambos',
                                      ),
                                ),
                                _buildDashboardCard(
                                  title: "Comunicados",
                                  count: totalComunicados,
                                  icon: Icons.announcement,
                                  color: Colors.orange,
                                  onTap:
                                      () => Navigator.pushNamed(
                                        context,
                                        '/comunicados',
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  CustomBottomNav(
                    currentIndex: 0,
                    rol: (ApiService.currentUser?['rol'] ?? 'administrador').toString().toLowerCase(),
                  ),
                  ],
                ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              "$count",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
