import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class PacientesPage extends StatefulWidget {
  const PacientesPage({super.key});

  @override
  State<PacientesPage> createState() => _PacientesPageState();
}

class _PacientesPageState extends State<PacientesPage> {
  List<dynamic> pacientes = [];
  List<dynamic> usuarios = [];
  bool loading = true;

  final _formKey = GlobalKey<FormState>();
  int? editingId;
  int? selectedUserId;
  bool tieneAnemia = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => loading = true);
    pacientes = await ApiService.getPacientes();
    usuarios = await ApiService.getUsuariosPacientes();
    setState(() => loading = false);
  }

  void resetForm() {
    editingId = null;
    selectedUserId = null;
    tieneAnemia = false;
  }

  Future<void> savePaciente() async {
    if (!_formKey.currentState!.validate() || selectedUserId == null) return;

    final alreadyExists = pacientes.any((p) =>
        p['usuario'] != null &&
        p['usuario']['id'] == selectedUserId &&
        editingId == null); // solo al registrar

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este usuario ya está registrado como paciente.')),
      );
      return;
    }

    final ok = editingId == null
        ? await ApiService.createPaciente(selectedUserId!, tieneAnemia)
        : await ApiService.updatePaciente(editingId!, selectedUserId!, tieneAnemia);

    if (ok) {
      resetForm();
      fetchData();
      Navigator.pop(context);
    }
  }

  Future<void> deletePaciente(int id) async {
    final ok = await ApiService.deletePaciente(id);
    if (ok) fetchData();
  }

  void openForm({Map? paciente}) {
    if (paciente != null) {
      editingId = paciente['id'];
      selectedUserId = paciente['usuario']?['id'];
      tieneAnemia = paciente['tieneAnemia'] ?? false;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Form(
          key: _formKey,
          child: Wrap(
            runSpacing: 16,
            children: [
              Center(
                child: Text(
                  editingId == null ? 'Nuevo Paciente' : 'Editar Paciente',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              DropdownButtonFormField<int>(
                value: selectedUserId,
                decoration: const InputDecoration(
                  labelText: 'Seleccionar usuario',
                  border: OutlineInputBorder(),
                ),
                items: usuarios
                    .where((u) {
                      final userId = u['id'];
                      final yaAsignado = pacientes.any((p) =>
                          p['usuario'] != null &&
                          p['usuario']['id'] == userId &&
                          (editingId == null || p['id'] != editingId));
                      return !yaAsignado || userId == selectedUserId;
                    })
                    .map<DropdownMenuItem<int>>((u) => DropdownMenuItem<int>(
                          value: u['id'],
                          child: Text(u['nombre']),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => selectedUserId = val),
                validator: (val) => val == null ? 'Seleccione un usuario' : null,
              ),
              SwitchListTile(
                title: const Text("¿Tiene Anemia?"),
                value: tieneAnemia,
                onChanged: (val) => setState(() => tieneAnemia = val),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(editingId == null ? 'Registrar' : 'Actualizar'),
                  onPressed: savePaciente,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => resetForm());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pacientes'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : pacientes.isEmpty
              ? const Center(child: Text('No hay pacientes registrados.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pacientes.length,
                  itemBuilder: (_, i) {
                    final p = pacientes[i];
                    final usuario = p['usuario'];
                    final nombre = usuario != null
                        ? "${usuario['firstName']} ${usuario['lastNameP']}"
                        : 'Sin usuario';
                    final tieneAnemiaText = p['tieneAnemia'] ? 'Con anemia' : 'Sin anemia';

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo,
                          child: Text(nombre.isNotEmpty ? nombre[0] : '?',
                              style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(
                          nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(
                              p['tieneAnemia'] ? Icons.warning : Icons.check_circle,
                              color: p['tieneAnemia'] ? Colors.orange : Colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tieneAnemiaText,
                              style: TextStyle(
                                color: p['tieneAnemia'] ? Colors.orange : Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
                              onPressed: () => openForm(paciente: p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deletePaciente(p['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openForm(),
        label: const Text("Nuevo paciente"),
        icon: const Icon(Icons.person_add),
        backgroundColor: Colors.indigo,
      ),
    );
  }
}
