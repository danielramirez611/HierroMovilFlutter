import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/api_service.dart';

class TambosPage extends StatefulWidget {
  const TambosPage({super.key});

  @override
  State<TambosPage> createState() => _TambosPageState();
}

class _TambosPageState extends State<TambosPage> {
  List<dynamic> tambos = [];
  List<dynamic> usuarios = []; // ✅ ESTA LÍNEA ES CLAVE
  final codeController = TextEditingController();

  final representanteController = TextEditingController();
  final telefonoController = TextEditingController();
  final List<Map<String, dynamic>> tiposTambo = [
    {'value': 'Temporal', 'icon': Icons.hourglass_empty},
    {'value': 'Movil', 'icon': Icons.directions_bus},
    {'value': 'Permanente', 'icon': Icons.home_filled},
  ];
  final List<Map<String, dynamic>> estadosTambo = [
    {
      'value': true,
      'label': 'Activo',
      'icon': Icons.check_circle,
      'color': Colors.green,
    },
    {
      'value': false,
      'label': 'Inactivo',
      'icon': Icons.cancel,
      'color': Colors.red,
    },
  ];

  bool loading = true;

  final _formKey = GlobalKey<FormState>();
  int? editingId;
  String departamento = '';
  String provincia = '';
  String distrito = '';
  String representante = '';
  String documento = '';
  String code = '';
  String nombre = '';
  String tipoTambo = '';
  String estadoTambo = '';
  String direccion = '';
  String referencia = '';
  String horario = '';
  String telefono = '';

  List<String> departamentos = [];
  List<String> provincias = [];
  List<String> distritos = [];

  @override
  void initState() {
    super.initState();
    fetchTambos();
    fetchUsuarios(); // ← Agrega esto
    setState(() {}); // ← opcional para forzar redibujo
  }

  Future<void> fetchUsuarios() async {
    final data = await ApiService.getAllUsers();
    usuarios =
        data.where((u) {
          final rol = u['role']?.toString().toLowerCase();
          return u['documentNumber'] != null &&
              (rol == 'administrador' || rol == 'gestor');
        }).toList();

    setState(() {});
  }

  Future<void> fetchTambos() async {
    setState(() => loading = true);
    tambos = await ApiService.getTambos();
    departamentos = await ApiService.getDepartamentos();
    setState(() => loading = false);
  }

  Future<void> fetchProvincias() async {
    provincias = await ApiService.getProvincias(departamento);
    setState(() {});
  }

  Future<void> fetchDistritos() async {
    distritos = await ApiService.getDistritos(departamento, provincia);
    setState(() {});
  }

  Future<void> generateCode() async {
    final result = await ApiService.getNextCode(
      departamento,
      provincia,
      distrito,
    );
    setState(() {
      code = result;
      codeController.text = result; // ✅ Actualiza el campo visible
    });
  }

  Future<void> saveTambo() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final tamboData = {
      "id": editingId,
      "code": codeController.text,
      "name": nombre,
      "tipo": tipoTambo,
      "estado": estadoTambo.toLowerCase() == 'activo',
      "departamento": departamento,
      "provincia": provincia,
      "distrito": distrito,
      "direccion": direccion,
      "referencia": referencia,
      "horarioAtencion": horario,
      "documentoRepresentante": documento,
      "representante": representanteController.text,
      "telefono": telefonoController.text,
    };

    // Eliminar el ID si es nuevo
    if (editingId == null) {
      tamboData.remove("id");
    }

    // 👇 NO lo envuelvas con "tambo"
    final ok =
        editingId == null
            ? await ApiService.createTambo(tamboData)
            : await ApiService.updateTambo(editingId!, tamboData);

    if (ok) {
      Navigator.pop(context);
      fetchTambos();
      resetForm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar el tambo')),
      );
    }

    debugPrint('DATOS A ENVIAR: $tamboData');
  }

  void resetForm() {
    editingId = null;
    departamento = '';
    provincia = '';
    distrito = '';
    representante = '';
    documento = '';
    code = '';
    nombre = '';
    tipoTambo = '';
    estadoTambo = '';
    direccion = '';
    referencia = '';
    horario = '';
    telefono = '';
    representanteController.clear();
    telefonoController.clear();
    provincias = [];
    distritos = [];
  }

  void openForm({Map? tambo}) async {
    if (usuarios.isEmpty) await fetchUsuarios(); // ← asegura que esté cargado
    representanteController.text = representante;
    telefonoController.text = telefono;

    if (tambo != null) {
      editingId = tambo['id'];
      departamento = tambo['departamento'];
      await fetchProvincias();
      provincia = tambo['provincia'];
      await fetchDistritos();
      distrito = tambo['distrito'];
      representante = tambo['representante'];
      documento = tambo['documentoRepresentante'];
      code = tambo['code'] ?? '';
      codeController.text = code;
      nombre = tambo['name'] ?? '';
    tipoTambo = tambo['tipo'] ?? ''; // ✅ Corrección aquí

      final estadoBool = tambo['estado'] ?? true;
    final estadoEncontrado = estadosTambo.firstWhere(
      (e) => e['value'] == estadoBool,
      orElse: () => estadosTambo[0],
    );
    estadoTambo = estadoEncontrado['label']; // ✅ Corrección aquí

      direccion = tambo['direccion'] ?? '';
      referencia = tambo['referencia'] ?? '';
      horario = tambo['horarioAtencion'] ?? '';
      telefono = tambo['telefono'] ?? '';
    }
    // ✅ Limpieza si no existe en las listas
    if (!departamentos.contains(departamento)) departamento = '';
    if (!provincias.contains(provincia)) provincia = '';
    if (!distritos.contains(distrito)) distrito = '';
    if (!usuarios
        .map((u) => u['documentNumber'].toString())
        .contains(documento.toString())) {
      documento = '';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[100],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextFormField(
                    enabled: false,
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Código generado',
                    ),
                  ),

                  TextFormField(
                    initialValue: nombre,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    onSaved: (val) => nombre = val ?? '',
                    validator:
                        (val) =>
                            val == null || val.isEmpty
                                ? 'Ingrese nombre'
                                : null,
                  ),

                  DropdownButtonFormField<String>(
                    value: tipoTambo.isNotEmpty ? tipoTambo : null,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Tambo',
                    ),
                    items:
                        tiposTambo.map((tipo) {
                          return DropdownMenuItem<String>(
                            value: tipo['value'],
                            child: Row(
                              children: [
                                Icon(tipo['icon'], size: 20),
                                const SizedBox(width: 8),
                                Text(tipo['value']),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (val) => setState(() => tipoTambo = val ?? ''),
                    validator:
                        (val) =>
                            val == null || val.isEmpty
                                ? 'Seleccione un tipo'
                                : null,
                  ),

                  DropdownButtonFormField<String>(
                    value: estadoTambo.isNotEmpty ? estadoTambo : null,
                    decoration: const InputDecoration(
                      labelText: 'Estado del Tambo',
                    ),
                    items:
                        estadosTambo.map((estado) {
                          return DropdownMenuItem<String>(
                            value: estado['label'],
                            child: Row(
                              children: [
                                Icon(
                                  estado['icon'],
                                  color: estado['color'],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  estado['label'],
                                  style: TextStyle(color: estado['color']),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (val) => setState(() => estadoTambo = val ?? ''),
                    validator:
                        (val) =>
                            val == null || val.isEmpty
                                ? 'Seleccione estado'
                                : null,
                  ),

                  DropdownButtonFormField<String>(
                    value: departamento.isNotEmpty ? departamento : null,
                    items:
                        departamentos
                            .map(
                              (dep) => DropdownMenuItem(
                                value: dep,
                                child: Text(dep),
                              ),
                            )
                            .toList(),
                    onChanged: (val) async {
                      departamento = val!;
                      provincia = '';
                      distrito = '';
                      code = '';
                      await fetchProvincias();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Departamento',
                    ),
                    validator:
                        (val) =>
                            val == null || val.isEmpty
                                ? 'Seleccione departamento'
                                : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: provincia.isNotEmpty ? provincia : null,
                    items:
                        provincias
                            .map(
                              (prov) => DropdownMenuItem(
                                value: prov,
                                child: Text(prov),
                              ),
                            )
                            .toList(),
                    onChanged: (val) async {
                      provincia = val!;
                      distrito = '';
                      code = '';
                      await fetchDistritos();
                    },
                    decoration: const InputDecoration(labelText: 'Provincia'),
                    validator:
                        (val) =>
                            val == null || val.isEmpty
                                ? 'Seleccione provincia'
                                : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: distrito.isNotEmpty ? distrito : null,
                    items:
                        distritos
                            .map(
                              (dist) => DropdownMenuItem(
                                value: dist,
                                child: Text(dist),
                              ),
                            )
                            .toList(),
                    onChanged: (val) async {
                      distrito = val!;
                      await generateCode();
                    },
                    decoration: const InputDecoration(labelText: 'Distrito'),
                    validator:
                        (val) =>
                            val == null || val.isEmpty
                                ? 'Seleccione distrito'
                                : null,
                  ),
                  TextFormField(
                    initialValue: direccion,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                    onSaved: (val) => direccion = val ?? '',
                  ),

                  TextFormField(
                    initialValue: referencia,
                    decoration: const InputDecoration(labelText: 'Referencia'),
                    onSaved: (val) => referencia = val ?? '',
                  ),

                  TextFormField(
                    initialValue: horario,
                    decoration: const InputDecoration(
                      labelText: 'Horario de Atención',
                    ),
                    onChanged: (val) => horario = val,
                  ),

                  /// ⬇️ DNI como dropdown
                  DropdownButtonFormField<String>(
                    value:
                        usuarios
                                .map((u) => u['documentNumber'].toString())
                                .contains(documento.toString())
                            ? documento.toString()
                            : null,
                    decoration: const InputDecoration(
                      labelText: 'DNI del Representante',
                    ),
                    items:
                        usuarios
                            .map(
                              (u) => DropdownMenuItem<String>(
                                value: u['documentNumber'].toString(),
                                child: Text(
                                  '${u['documentNumber']} (${u['role']})',
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      final selected = usuarios.firstWhere(
                        (u) => u['documentNumber'].toString() == val,
                        orElse: () => {},
                      );
                      setState(() {
                        documento = selected['documentNumber'] ?? '';
                        representante =
                            "${selected['firstName'] ?? ''} ${selected['lastNameP'] ?? ''} ${selected['lastNameM'] ?? ''}"
                                .trim();
                        telefono = selected['phone'] ?? '';
                        representanteController.text = representante;
                        telefonoController.text = telefono;
                      });
                    },
                    validator:
                        (val) =>
                            val == null || val.isEmpty
                                ? 'Seleccione un representante'
                                : null,
                  ),

                  TextFormField(
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Representante',
                    ),
                    controller: representanteController,
                  ),

                  TextFormField(
                    enabled: false,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    controller: telefonoController,
                  ),

                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: saveTambo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                    ),
                    child: Text(editingId == null ? 'Registrar' : 'Actualizar'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
    );
  }

  void deleteTambo(int id) async {
    final confirm = await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Confirmar'),
            content: const Text('¿Eliminar este tambo?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final ok = await ApiService.deleteTambo(id);
                  if (ok) fetchTambos();
                  Navigator.pop(context);
                },
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Tambos'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: tambos.length,
                itemBuilder: (_, i) {
                  final t = tambos[i];
                  return Card(
                    child: ListTile(
                      title: Text(
                        '${t['code']} - ${t['representante'] ?? "Sin nombre"}',
                      ),
                      subtitle: Text(
                        '${t['departamento']}, ${t['provincia']}, ${t['distrito']}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => openForm(tambo: t),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteTambo(t['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add),
        label: const Text("Nuevo Tambo"),
        onPressed: () => openForm(),
      ),
    );
  }
}
