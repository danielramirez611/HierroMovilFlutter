import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class AsignacionTamboPage extends StatefulWidget {
  const AsignacionTamboPage({super.key});

  @override
  State<AsignacionTamboPage> createState() => _AsignacionTamboPageState();
}

class _AsignacionTamboPageState extends State<AsignacionTamboPage> {
  List<dynamic> asignaciones = [];
  List<dynamic> gestores = [];
  List<dynamic> tambosDisponibles = [];

  String? departamento;
  String? provincia;
  String? distrito;

  List<String> departamentos = [];
  List<String> provincias = [];
  List<String> distritos = [];

  int? selectedGestor;
  int? selectedTambo;
  int? editingId;

  bool loading = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => loading = true);
    asignaciones = await ApiService.getAsignacionesExtendidas();
    departamentos = await ApiService.getDepartamentos();
    gestores = await ApiService.getGestoresDisponibles();
    setState(() => loading = false);
  }

 Future<List<String>> fetchProvincias() async {
  provincias = await ApiService.getProvincias(departamento!);
  setState(() {});
  return provincias;
}

Future<List<String>> fetchDistritos() async {
  distritos = await ApiService.getDistritos(departamento!, provincia!);
  setState(() {});
  return distritos;
}
  Future<void> fetchTambosDisponibles() async {
    tambosDisponibles = await ApiService.getTambosDisponibles(
      departamento: departamento,
      provincia: provincia,
      distrito: distrito,
    );
    setState(() {});
  }

  void openForm({Map? asignacion}) async {
  final formKey = GlobalKey<FormState>();
editingId = asignacion?['id'];
bool localEstado = asignacion?['estado'] ?? true;
final centroPobladoController = TextEditingController(text: asignacion?['centroPoblado'] ?? '');

  // Variables locales
  String? localDepartamento = asignacion?['departamento'];
  String? localProvincia = asignacion?['provincia'];
  String? localDistrito = asignacion?['distrito'];
  int? localSelectedGestor = asignacion?['gestorId'];
  int? localSelectedTambo = asignacion?['tamboId'];

  List<String> localProvincias = localDepartamento != null
      ? await ApiService.getProvincias(localDepartamento)
      : [];
  List<String> localDistritos = (localDepartamento != null && localProvincia != null)
      ? await ApiService.getDistritos(localDepartamento, localProvincia)
      : [];

  tambosDisponibles = await ApiService.getTambosDisponibles(
    departamento: localDepartamento,
    provincia: localProvincia,
    distrito: localDistrito,
  );

  if (asignacion != null &&
      !tambosDisponibles.any((t) => t['id'] == localSelectedTambo)) {
    tambosDisponibles.add({
      'id': localSelectedTambo,
      'name': asignacion['tamboNombre'],
      'departamento': localDepartamento,
      'provincia': localProvincia,
      'distrito': localDistrito,
    });
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: localSelectedGestor,
                  items: gestores
    .where((g) => g != null && g.containsKey('id'))
    .map<DropdownMenuItem<int>>((g) {
  final nombre = [
    g['firstName'] ?? '',
    g['lastNameP'] ?? '',
    g['lastNameM'] ?? ''
  ].join(' ').trim();

  return DropdownMenuItem(
    value: g['id'],
    child: Text(
      nombre.isNotEmpty ? nombre : 'Gestor sin nombre',
      overflow: TextOverflow.ellipsis,
    ),
  );
}).toList(),

                    onChanged: (val) {
                      setModalState(() => localSelectedGestor = val);
                    },
                    decoration: const InputDecoration(labelText: 'Gestor'),
                    validator: (val) => val == null ? 'Seleccione un gestor' : null,
                  ),
                  const SizedBox(height: 10),
                   // 👇 Campo ESTADO
                  DropdownButtonFormField<bool>(
                    value: localEstado,
                    items: const [
                      DropdownMenuItem(value: true, child: Text('Activo')),
                      DropdownMenuItem(value: false, child: Text('Inactivo')),
                    ],
                    onChanged: (val) {
                      setModalState(() => localEstado = val!);
                    },
                    decoration: const InputDecoration(labelText: 'Estado'),
                  ),
                  const SizedBox(height: 10),
                  // 👇 Campo Centro Poblado
                  TextFormField(
                    controller: centroPobladoController,
                    decoration: const InputDecoration(labelText: 'Centro Poblado'),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Ingrese el centro poblado'
                        : null,
                  ),
                  const SizedBox(height: 20),   
                  DropdownButtonFormField<String>(
                    value: localDepartamento,
                    items: departamentos.map((dep) {
                      return DropdownMenuItem(value: dep, child: Text(dep));
                    }).toList(),
                    onChanged: (val) async {
                      localDepartamento = val;
                      localProvincia = null;
                      localDistrito = null;
                      localProvincias = await ApiService.getProvincias(val!);
                      localDistritos = [];
                      tambosDisponibles = await ApiService.getTambosDisponibles(departamento: val);
                      setModalState(() {});
                    },
                    decoration: const InputDecoration(labelText: 'Departamento'),
                    validator: (val) => val == null ? 'Seleccione departamento' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: localProvincia,
                    items: localProvincias.map((prov) {
                      return DropdownMenuItem(value: prov, child: Text(prov));
                    }).toList(),
                    onChanged: (val) async {
                      localProvincia = val;
                      localDistrito = null;
                      localDistritos = await ApiService.getDistritos(localDepartamento!, val!);
                      tambosDisponibles = await ApiService.getTambosDisponibles(
                        departamento: localDepartamento,
                        provincia: val,
                      );
                      setModalState(() {});
                    },
                    decoration: const InputDecoration(labelText: 'Provincia'),
                    validator: (val) => val == null ? 'Seleccione provincia' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: localDistrito,
                    items: localDistritos.map((dist) {
                      return DropdownMenuItem(value: dist, child: Text(dist));
                    }).toList(),
                    onChanged: (val) async {
                      localDistrito = val;
                      tambosDisponibles = await ApiService.getTambosDisponibles(
                        departamento: localDepartamento,
                        provincia: localProvincia,
                        distrito: val,
                      );
                      setModalState(() {});
                    },
                    decoration: const InputDecoration(labelText: 'Distrito'),
                    validator: (val) => val == null ? 'Seleccione distrito' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: localSelectedTambo,
                    items: tambosDisponibles.map<DropdownMenuItem<int>>((t) {
                      return DropdownMenuItem(
                        value: t['id'],
                        child: Text("${t['name']} (${t['distrito']})"),
                      );
                    }).toList(),
                    onChanged: (val) async {
                      final tambo = tambosDisponibles.firstWhere((t) => t['id'] == val);
                      localSelectedTambo = val;
                      localDepartamento = tambo['departamento'];
                      localProvincia = tambo['provincia'];
                      localDistrito = tambo['distrito'];
                      localProvincias = await ApiService.getProvincias(localDepartamento!);
                      localDistritos = await ApiService.getDistritos(localDepartamento!, localProvincia!);
                      setModalState(() {});
                    },
                    decoration: const InputDecoration(labelText: 'Tambo'),
                    validator: (val) => val == null ? 'Seleccione un tambo' : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
  onPressed: () async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      selectedGestor = localSelectedGestor;
      selectedTambo = localSelectedTambo;
      departamento = localDepartamento;
      provincia = localProvincia;
      distrito = localDistrito;
    });
final data = {
  "gestorId": localSelectedGestor,
  "tamboId": localSelectedTambo,
  "estado": localEstado,
  "centroPoblado": centroPobladoController.text.trim(),
  "departamento": localDepartamento,
  "provincia": localProvincia,
  "distrito": localDistrito,
};

if (editingId != null) {
  data["id"] = editingId;
}



    
    final ok = editingId == null
        ? await ApiService.createAsignacion(data)
        : await ApiService.updateAsignacion(editingId!, data);

    if (ok) {
      Navigator.pop(context);
      fetchData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar')),
      );
    }
  },
  child: Text(editingId == null ? 'Asignar' : 'Actualizar'),
),


                ],
              ),
            ),
          ),
        );
      });
    },
  );
}

Future<void> desactivarAsignacion(int id) async {
  final asignacion = asignaciones.firstWhere((a) => a['id'] == id);
  final data = {
    "id": asignacion['id'],
    "gestorId": asignacion['gestorId'],
    "tamboId": asignacion['tamboId'],
    "estado": false,
    "centroPoblado": asignacion['centroPoblado'],
    "departamento": asignacion['departamento'],
    "provincia": asignacion['provincia'],
    "distrito": asignacion['distrito'],
  };

  final ok = await ApiService.updateAsignacion(id, data);
  if (ok) {
    fetchData();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('❌ No se pudo desactivar')),
    );
  }
}

  Future<void> saveAsignacion() async {
if (!_formKey.currentState!.validate()) return; // este es GLOBAL

    final data = {
      "id": editingId,
      "gestorId": selectedGestor,
      "tamboId": selectedTambo,
    };

    final ok =
        editingId == null
            ? await ApiService.createAsignacion(data)
            : await ApiService.updateAsignacion(editingId!, data);

    if (ok) {
      Navigator.pop(context);
      fetchData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar asignación')),
      );
    }
  }

 void deleteAsignacion(int id) async {
  final confirm = await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('¿Qué desea hacer con esta asignación?'),
      content: const Text('Puedes eliminarla permanentemente o solo desactivarla.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await desactivarAsignacion(id);
          },
          child: const Text('Desactivar'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final ok = await ApiService.deleteAsignacionPermanente(id);

            if (ok) {
              fetchData();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('❌ No se pudo eliminar permanentemente')),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Eliminar completamente'),
        ),
      ],
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignación de Tambos'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: asignaciones.length,
                itemBuilder: (_, i) {
                  final a = asignaciones[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    child: ListTile(
                      title: Text('Tambo: ${a['tamboNombre']}'),
                      subtitle: Text(
  'Gestor: ${a['gestorNombre']} \n'
  '${a['departamento']} - ${a['provincia']} - ${a['distrito']} \n'
  'Centro Poblado: ${a['centroPoblado'] ?? "N/A"}\n'
  'Estado: ${a['estado'] == true ? "Activo" : "Inactivo"}',
),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => openForm(asignacion: a),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteAsignacion(a['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Asignación'),
        backgroundColor: Colors.indigo,
      ),
    );
  }
}
