import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/api_service.dart';
import '../widgets/custom_bottom_nav.dart';

class HomeGestorScreen extends StatefulWidget {
  const HomeGestorScreen({super.key});

  @override
  State<HomeGestorScreen> createState() => _HomeGestorScreenState();
}

class _HomeGestorScreenState extends State<HomeGestorScreen> {
  List tambos = [];
  List visitas = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDatos();
  }

  Future<void> fetchDatos() async {
    final userId = ApiService.currentUser?['id'];
    if (userId == null) return;

    final resVisitas = await http.get(Uri.parse('${ApiService.baseUrl}/VisitaDomiciliaria'));
    final resTambos = await http.get(Uri.parse('${ApiService.baseUrl}/Tambos'));

    setState(() {
      visitas = jsonDecode(resVisitas.body)
          .where((v) => v['gestor']?['id'] == userId)
          .toList();
      tambos = jsonDecode(resTambos.body);
      loading = false;
    });
  }

  Widget _buildEmptyMessage(String message) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(message, style: const TextStyle(color: Colors.grey)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Encabezado
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.blueGrey,
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
                          style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text("Bienvenido gestor 👨‍⚕️", style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Contenido
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          "Tus visitas registradas (${visitas.length})",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        if (visitas.isEmpty)
                          _buildEmptyMessage("No tienes visitas registradas aún.")
                        else
                          ...visitas.map((v) => Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text("Paciente: ${v['paciente']?['nombreCompleto'] ?? 'Desconocido'}"),
                                  subtitle: Text("Observación: ${v['observaciones'] ?? 'Sin observación'}"),
                                ),
                              )),
                      ],
                    ),
                  ),

CustomBottomNav(
  currentIndex: 0,
  rol: (ApiService.currentUser?['rol'] ?? 'gestor').toString().toLowerCase(),
),
                ],
              ),
      ),
    );
  }
}
