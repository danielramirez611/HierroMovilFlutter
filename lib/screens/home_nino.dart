import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets/custom_bottom_nav.dart';
import '../services/api_service.dart';

class HomeNinoScreen extends StatefulWidget {
  const HomeNinoScreen({super.key});

  @override
  State<HomeNinoScreen> createState() => _HomeNinoScreenState();
}

class _HomeNinoScreenState extends State<HomeNinoScreen> {
  Map<String, dynamic>? pacienteData;
  List visitas = [];
  List comunicados = [];
  List alertas = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchPacienteData();
  }

  Future<void> fetchPacienteData() async {
    final userId = ApiService.currentUser?['id'];
    if (userId == null) return;

    final resPaciente = await http.get(Uri.parse('${ApiService.baseUrl}/Pacientes'));
    final List data = jsonDecode(resPaciente.body);

    final paciente = data.cast<Map<String, dynamic>>().firstWhere(
      (p) => p['usuario']?['id'] == userId,
      orElse: () => {},
    );

    if (paciente.isEmpty) return;

    final pacienteId = paciente['id'];

    final resVisitas = await http.get(Uri.parse('${ApiService.baseUrl}/VisitaDomiciliaria/paciente/$pacienteId'));
    final resAlertas = await http.get(Uri.parse('${ApiService.baseUrl}/Alerta'));
    final resComunicados = await http.get(Uri.parse('${ApiService.baseUrl}/Comunicado'));

    setState(() {
      pacienteData = paciente;
      visitas = jsonDecode(resVisitas.body);
      alertas = jsonDecode(resAlertas.body)
          .where((a) => a['paciente']?['id'] == pacienteId)
          .toList();
      comunicados = jsonDecode(resComunicados.body)
          .where((c) => c['destinatario'] == 0 || c['destinatario'] == 4)
          .toList();
      loading = false;
    });
  }

  Widget _buildSectionTitle(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        '$title ($count)',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Niños de Hierro',
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Bienvenido ${pacienteData?['usuario']?['nombres'] ?? 'niño/a'} 👦👧',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Anemia: ${pacienteData?['anemia'] == true ? "Sí" : "No"}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Visitas
                        _buildSectionTitle("Visitas domiciliarias", visitas.length),
                        if (visitas.isEmpty)
                          _buildEmptyMessage("Sin visitas registradas")
                        else
                          ...visitas.map((v) => Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  title: Text(v['observaciones'] ?? 'Sin observaciones'),
                                  subtitle: Text(
                                      'Ubicación: ${v['ubicacionConfirmada'] == true ? "Confirmada" : "No confirmada"}'),
                                ),
                              )),

                        const SizedBox(height: 20),

                        // Alertas
                        _buildSectionTitle("Alertas recientes", alertas.length),
                        if (alertas.isEmpty)
                          _buildEmptyMessage("Sin alertas recientes")
                        else
                          ...alertas.map((a) => Card(
                                color: Colors.red[50],
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: const Icon(Icons.warning, color: Colors.red),
                                  title: Text(a['titulo'] ?? 'Alerta'),
                                  subtitle: Text(a['descripcion'] ?? ''),
                                ),
                              )),

                        const SizedBox(height: 20),

                        // Comunicados
                        _buildSectionTitle("Comunicados importantes", comunicados.length),
                        if (comunicados.isEmpty)
                          _buildEmptyMessage("Sin comunicados importantes")
                        else
                          ...comunicados.map((c) => Card(
                                color: Colors.blue[50],
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: const Icon(Icons.announcement, color: Colors.blue),
                                  title: Text(c['titulo'] ?? 'Comunicado'),
                                  subtitle: Text(c['cuerpo'] ?? ''),
                                ),
                              )),
                      ],
                    ),
                  ),
                ],
              ),
      ),
bottomNavigationBar: CustomBottomNav(
  currentIndex: 0,
  rol: (ApiService.currentUser?['rol'] ?? 'niño').toString().toLowerCase(),
),
    );
  }
}
