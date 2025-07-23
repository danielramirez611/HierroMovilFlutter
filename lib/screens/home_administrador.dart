import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../widgets/custom_bottom_nav.dart';

import '../screens/administrador/PacientesPage.dart';
import '../screens/administrador/TambosPage.dart';
import '../screens/administrador/AsignacionTamboPage.dart';
import '../screens/administrador/VisitasPage.dart';
import '../screens/administrador/AgendarVisitaPage.dart';
import '../screens/PerfilUsuarioScreen.dart';

class HomeAdministradorScreen extends StatefulWidget {
  const HomeAdministradorScreen({super.key});

  @override
  State<HomeAdministradorScreen> createState() => _HomeAdministradorScreenState();
}

class _HomeAdministradorScreenState extends State<HomeAdministradorScreen> {
  int currentIndex = 2;

  int totalUsuarios = 0;
  int totalVisitas = 0;
    int agendasVisitas = 0;

  int totalComunicados = 0;
  bool loading = true;

  Timer? _internetTimer;
  bool _isOfflineBannerShown = false;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
    startInternetChecker();
  }

  Future<void> loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final resUsuarios = await http.get(Uri.parse('${ApiService.baseUrl}/Users'));
      final resVisitas = await http.get(Uri.parse('${ApiService.baseUrl}/VisitaDomiciliaria'));
      final resVisitasAgendadas = await http.get(Uri.parse('${ApiService.baseUrl}/VisitaDomiciliaria/agendadas'));
      final resComunicados = await http.get(Uri.parse('${ApiService.baseUrl}/Comunicado'));

      final usuarios = jsonDecode(resUsuarios.body);
      final visitas = jsonDecode(resVisitas.body);
      final visitasAgendadas = jsonDecode(resVisitasAgendadas.body);
      final comunicados = jsonDecode(resComunicados.body);

      // Guarda en caché
      await prefs.setString('cachedUsuarios', jsonEncode(usuarios));
      await prefs.setString('cachedVisitas', jsonEncode(visitas));
      await prefs.setString('cachedVisitasAgendadas', jsonEncode(visitasAgendadas));
      await prefs.setString('cachedComunicados', jsonEncode(comunicados));

      if (mounted) {
        setState(() {
          totalUsuarios = usuarios.length;
          totalVisitas = visitas.length;
          agendasVisitas = visitasAgendadas.length;
          totalComunicados = comunicados.length;
          loading = false;
        });
      }
    } catch (e) {
      print('🌐 Sin conexión. Usando caché en Dashboard.');

      final cachedUsuarios = prefs.getString('cachedUsuarios');
      final cachedVisitas = prefs.getString('cachedVisitas');
      final cachedVisitasAgendadas = prefs.getString('cachedVisitasAgendadas');
      final cachedComunicados = prefs.getString('cachedComunicados');

      setState(() {
        totalUsuarios = cachedUsuarios != null ? jsonDecode(cachedUsuarios).length : 0;
        totalVisitas = cachedVisitas != null ? jsonDecode(cachedVisitas).length : 0;
        agendasVisitas = cachedVisitasAgendadas != null ? jsonDecode(cachedVisitasAgendadas).length : 0;
        totalComunicados = cachedComunicados != null ? jsonDecode(cachedComunicados).length : 0;
        loading = false;
      });
    }
  }

  void startInternetChecker() {
    _internetTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final connected = await hasInternetConnection();
      if (connected) {
        hideBanner();
        await loadDashboardData();
      } else {
        showOfflineBanner();
      }
    });
  }

  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void showOfflineBanner() {
    if (_isOfflineBannerShown) return;
    _isOfflineBannerShown = true;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠ Sin conexión. Mostrando datos cacheados.'),
        duration: Duration(days: 1),
      ),
    );
  }

  void hideBanner() {
    if (_isOfflineBannerShown) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _isOfflineBannerShown = false;
    }
  }

  @override
  void dispose() {
    _internetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      PacientesPage(),           // index 0
      TambosPage(),              // index 1
      _buildDashboard(),         // index 2
      VisitasPage(),  
            AgendarVisitaPage(),
           // index 3
      PerfilUsuarioScreen(),     // index 4
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : _screens[currentIndex],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: currentIndex,
        rol: (ApiService.currentUser?['rol'] ?? 'administrador').toString().toLowerCase(),
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildDashboard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: constraints.maxHeight < 600 ? 0.9 : 1.1,
                  children: [
                    _buildDashboardCard(
                      title: "Pacientes",
                      count: totalUsuarios,
                      icon: Icons.person_outline,
                      color: Colors.purple,
                      onTap: () => setState(() => currentIndex = 0),
                    ),
                    _buildDashboardCard(
                      title: "Tambos",
                      count: 0,
                      icon: Icons.house,
                      color: Colors.brown,
                      onTap: () => setState(() => currentIndex = 1),
                    ),
                    _buildDashboardCard(
                      title: "Asignación",
                      count: 0,
                      icon: Icons.assignment_outlined,
                      color: Colors.blue,
                      onTap: () => setState(() => currentIndex = 2),
                    ),
                    _buildDashboardCard(
                      title: "Registrar Visitas",
                      count: totalVisitas,
                      icon: Icons.home,
                      color: Colors.teal,
                      onTap: () => setState(() => currentIndex = 3),
                    ),
                     _buildDashboardCard(
                      title: "Agendar Visitas",
                      count: agendasVisitas,
                      icon: Icons.calendar_month,
                      color: const Color.fromARGB(255, 97, 150, 0),
                      onTap: () => setState(() => currentIndex = 4),
                    ),
                    _buildDashboardCard(
                      title: "Comunicados",
                      count: totalComunicados,
                      icon: Icons.announcement,
                      color: Colors.orange,
                      onTap: () => Navigator.pushNamed(context, '/comunicados'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
