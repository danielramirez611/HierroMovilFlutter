// ... imports
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';

class AgendarVisitaPage extends StatefulWidget {
  const AgendarVisitaPage({super.key});

  @override
  State<AgendarVisitaPage> createState() => _AgendarVisitaPageState();
}

class _AgendarVisitaPageState extends State<AgendarVisitaPage> {
  bool cargando = true;
  List<dynamic> pacientes = [];
  List<dynamic> gestores = [];
  List<dynamic> visitasAgendadas = [];

  int? pacienteId;
  int? gestorId;
  DateTime fechaVisita = DateTime.now();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    pacientes = await ApiService.getPacientes();
    gestores = await ApiService.getGestoresDisponibles();
    visitasAgendadas = await ApiService.getAgendamientos();
    setState(() => cargando = false);
  }

  void mostrarFormulario({bool edicion = false, dynamic visita}) {
    if (edicion && visita != null) {
      pacienteId = visita['paciente']['id'];
      gestorId = visita['gestor']['id'];
      fechaVisita = DateTime.parse(visita['fechaProgramada']);
    } else {
      pacienteId = null;
      gestorId = null;
      fechaVisita = DateTime.now();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(edicion ? 'Editar visita agendada' : 'Agendar nueva visita'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: pacienteId,
                decoration: const InputDecoration(labelText: 'Paciente'),
                items: pacientes.map<DropdownMenuItem<int>>((p) {
                  final usuario = p['usuario'] ?? p['user'] ?? {};
                  final nombre = '${usuario['firstName'] ?? ''} ${usuario['lastNameP'] ?? ''}';
                  return DropdownMenuItem(value: p['id'], child: Text(nombre));
                }).toList(),
                onChanged: (value) => setState(() => pacienteId = value),
                validator: (value) => value == null ? 'Seleccione un paciente' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: gestorId,
                decoration: const InputDecoration(labelText: 'Gestor'),
                items: gestores.map<DropdownMenuItem<int>>((g) {
                  final nombre = '${g['firstName'] ?? ''} ${g['lastNameP'] ?? ''}';
                  return DropdownMenuItem(value: g['id'], child: Text(nombre));
                }).toList(),
                onChanged: (value) => setState(() => gestorId = value),
                validator: (value) => value == null ? 'Seleccione un gestor' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: fechaVisita.toLocal().toString().split(' ')[0]),
                decoration: const InputDecoration(labelText: 'Fecha de Visita'),
                onTap: () async {
                  final fechaSeleccionada = await showDatePicker(
                    context: context,
                    initialDate: fechaVisita,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (fechaSeleccionada != null) {
                    setState(() => fechaVisita = fechaSeleccionada);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;

              bool ok = false;
              if (edicion) {
                ok = await ApiService.editarAgendamiento(
                  id: visita['id'],
                  pacienteId: pacienteId!,
                  gestorId: gestorId!,
                  fechaProgramada: fechaVisita,
                );
              } else {
                ok = await ApiService.crearAgendamiento(
                  pacienteId: pacienteId!,
                  gestorId: gestorId!,
                  fechaProgramada: fechaVisita,
                );
              }

              if (ok && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(edicion ? '✅ Visita actualizada.' : '✅ Visita agendada.')),
                );
                cargarDatos();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Error al ${edicion ? 'actualizar' : 'agendar'} visita.')),
                );
              }
            },
            child: Text(edicion ? 'Actualizar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> eliminarVisita(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar esta visita?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await ApiService.eliminarAgendamiento(id);
      if (ok) cargarDatos();
    }
  }

  Widget buildVisitaTile(dynamic visita) {
    final paciente = visita['paciente']?['usuario'] ?? visita['paciente']?['user'] ?? {};
    final gestor = visita['gestor'] ?? {};
    final fecha = visita['fechaProgramada']?.toString().split('T').first ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👤 Paciente: ${paciente['firstName'] ?? ''} ${paciente['lastNameP'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('🧑‍⚕️ Gestor: ${gestor['firstName'] ?? ''} ${gestor['lastNameP'] ?? ''}'),
            const SizedBox(height: 4),
            Text('📅 Fecha: $fecha'),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
              IconButton(
  icon: const Icon(Icons.playlist_add_check, color: Colors.green),
  tooltip: 'Registrar esta visita',
  onPressed: () {
    Navigator.pushNamed(
  context,
  '/visitas',
  arguments: {
    "pacienteId": visita['paciente']['id'],
    "gestorId": visita['gestor']['id'],
    "fechaVisita": visita['fechaProgramada'],
    "agendamientoId": visita['id'],
  },
);

  },
),

                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Editar visita',
                  onPressed: () => mostrarFormulario(edicion: true, visita: visita),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Eliminar visita',
                  onPressed: () => eliminarVisita(visita['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Visita'),
        backgroundColor: Colors.teal,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: cargarDatos,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const Text('📋 Visitas Agendadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (visitasAgendadas.isEmpty)
                    const Text('No hay visitas agendadas.', textAlign: TextAlign.center),
                  ...visitasAgendadas.map(buildVisitaTile).toList(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => mostrarFormulario(edicion: false),
        icon: const Icon(Icons.add),
        label: const Text('Agendar Visita'),
        backgroundColor: Colors.teal,
      ),
    );
  }
}
