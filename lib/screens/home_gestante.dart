import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/api_service.dart';
import '../widgets/custom_bottom_nav.dart';

class HomeGestanteScreen extends StatefulWidget {
  const HomeGestanteScreen({super.key});

  @override
  State<HomeGestanteScreen> createState() => _HomeGestanteScreenState();
}

class _HomeGestanteScreenState extends State<HomeGestanteScreen> {
  Map<String, dynamic>? paciente;
  List alertas = [];
  List comunicados = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDatos();
  }

  Future<void> fetchDatos() async {
    final userId = ApiService.currentUser?['id'];
    if (userId == null) return;

    final resPacientes = await http.get(Uri.parse('${ApiService.baseUrl}/Pacientes'));
    final List data = jsonDecode(resPacientes.body);
    final actual = data.firstWhere((p) => p['usuario']?['id'] == userId, orElse: () => null);

    if (actual == null) return;
    final pacienteId = actual['id'];

    final resAlertas = await http.get(Uri.parse('${ApiService.baseUrl}/Alerta'));
    final resComunicados = await http.get(Uri.parse('${ApiService.baseUrl}/Comunicado'));

    setState(() {
      paciente = actual;
      alertas = jsonDecode(resAlertas.body)
          .where((a) => a['paciente']?['id'] == pacienteId)
          .toList();
      comunicados = jsonDecode(resComunicados.body)
          .where((c) => c['destinatario'] == 1 || c['destinatario'] == 4)
          .toList();
      loading = false;
    });
  }

  Widget _buildSectionTitle(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        "$title ($count)",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyMessage(String msg) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(msg, style: const TextStyle(color: Colors.grey)),
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
                      color: Colors.pinkAccent,
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
                        Text("Bienvenida gestante 🤰", style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Contenido
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildSectionTitle("Comunicados", comunicados.length),
                        if (comunicados.isEmpty)
                          _buildEmptyMessage("No tienes comunicados aún.")
                        else
                          ...comunicados.map((c) => Card(
                                color: Colors.blue[50],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: const Icon(Icons.announcement, color: Colors.blue),
                                  title: Text(c['titulo'] ?? "Comunicado"),
                                  subtitle: Text(c['cuerpo'] ?? ""),
                                ),
                              )),

                        const SizedBox(height: 20),

                        _buildSectionTitle("Alertas recientes", alertas.length),
                        if (alertas.isEmpty)
                          _buildEmptyMessage("Sin alertas recientes")
                        else
                          ...alertas.map((a) => Card(
                                color: Colors.red[50],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: const Icon(Icons.warning, color: Colors.red),
                                  title: Text(a['titulo'] ?? "Alerta"),
                                  subtitle: Text(a['descripcion'] ?? ""),
                                ),
                              )),
                      ],
                    ),
                  ),

CustomBottomNav(
  currentIndex: 0,
  rol: (ApiService.currentUser?['rol'] ?? 'gestante').toString().toLowerCase(),
),
                ],
              ),
      ),
    );
  }
}
