import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/api_service.dart';
import '../../widgets/mapa_selector.dart';
import 'package:latlong2/latlong.dart'; // 👈 NECESARIO para usar LatLng correctamente

class VisitasPage extends StatefulWidget {
  const VisitasPage({super.key});

  @override
  State<VisitasPage> createState() => _VisitasPageState();
}

class _VisitasPageState extends State<VisitasPage> {
  List<dynamic> visitas = [];
  bool loading = true;
  final _formKey = GlobalKey<FormState>();
  int? editingId;

  int? pacienteId;
  int? gestorId;
  int? asignacionId;
  DateTime fechaVisita = DateTime.now();
  final observacionController = TextEditingController();
  final alturaController = TextEditingController();
  final pesoController = TextEditingController();
  bool tieneAgua = false;
  bool tieneLuz = false;
  bool tieneInternet = false;

  double? latitud;
  double? longitud;
  bool ubicacionConfirmada = false;

  @override
  void initState() {
    super.initState();
    fetchVisitas();
  }

  Future<void> fetchVisitas() async {
    setState(() => loading = true);
    visitas = await ApiService.getVisitas();
    setState(() => loading = false);
  }

Future<void> obtenerUbicacionActual() async {
  final servicioHabilitado = await Geolocator.isLocationServiceEnabled();
  if (!servicioHabilitado) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activa el GPS del dispositivo.')),
    );
    return;
  }

  LocationPermission permiso = await Geolocator.checkPermission();
  if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
    permiso = await Geolocator.requestPermission();
    if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de ubicación denegado')),
      );
      return;
    }
  }

  try {
    final posicion = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      latitud = posicion.latitude;
      longitud = posicion.longitude;
      ubicacionConfirmada = true;
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo obtener la ubicación')),
    );
  }
}



void openForm({Map<String, dynamic>? visita}) {
  if (visita == null) {
    // Evitamos error al abrir modal con async
    obtenerUbicacionActual().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _abrirFormularioModal(null);
      });
    });
  } else {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _abrirFormularioModal(visita);
    });
  }
}


void _abrirFormularioModal(Map<String, dynamic>? visita) {
  editingId = visita?['id'];
  pacienteId = visita?['pacienteId'];
  gestorId = visita?['gestorId'];
  asignacionId = visita?['asignacionId'];
  observacionController.text = visita?['observacion'] ?? '';
  alturaController.text = visita?['altura']?.toString() ?? '';
  pesoController.text = visita?['peso']?.toString() ?? '';
  tieneAgua = visita?['tieneAgua'] ?? false;
  tieneLuz = visita?['tieneLuz'] ?? false;
  tieneInternet = visita?['tieneInternet'] ?? false;
  latitud = visita?['latitud'] ?? latitud;
  longitud = visita?['longitud'] ?? longitud;
  ubicacionConfirmada = visita?['ubicacionConfirmada'] ?? ubicacionConfirmada;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            TextFormField(
              controller: observacionController,
              decoration: const InputDecoration(labelText: 'Observación'),
            ),
            TextFormField(
              controller: alturaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Altura (cm)'),
            ),
            TextFormField(
              controller: pesoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Peso (kg)'),
            ),
            SwitchListTile(
              title: const Text('¿Tiene Agua?'),
              value: tieneAgua,
              onChanged: (v) => setState(() => tieneAgua = v),
              secondary: const Icon(Icons.water_drop_outlined),
            ),
            SwitchListTile(
              title: const Text('¿Tiene Luz?'),
              value: tieneLuz,
              onChanged: (v) => setState(() => tieneLuz = v),
              secondary: const Icon(Icons.lightbulb_outline),
            ),
            SwitchListTile(
              title: const Text('¿Tiene Internet?'),
              value: tieneInternet,
              onChanged: (v) => setState(() => tieneInternet = v),
              secondary: const Icon(Icons.wifi),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.location_on_outlined),
                const SizedBox(width: 8),
                Text(
                  'Ubicación: ${latitud?.toStringAsFixed(5) ?? "-"}, ${longitud?.toStringAsFixed(5) ?? "-"}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    ElevatedButton.icon(
      onPressed: () async {
        try {
          final servicioHabilitado = await Geolocator.isLocationServiceEnabled();
          if (!servicioHabilitado) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Activa el GPS del dispositivo')),
            );
            return;
          }

          LocationPermission permiso = await Geolocator.checkPermission();
          if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
            permiso = await Geolocator.requestPermission();
            if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Permiso de ubicación denegado')),
              );
              return;
            }
          }

          final posicion = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          setState(() {
            latitud = posicion.latitude;
            longitud = posicion.longitude;
            ubicacionConfirmada = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Ubicación actual obtenida')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Error al obtener la ubicación')),
          );
        }
      },
      icon: const Icon(Icons.my_location),
      label: const Text('Ubicación actual'),
    ),
    ElevatedButton.icon(
      onPressed: () async {
        LatLng? seleccion;

        await showDialog(
          context: context,
          builder: (_) => Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: MapaSelector(
                latInicial: latitud ?? -9.189967,
                lngInicial: longitud ?? -75.015152,
                onUbicacionSeleccionada: (lat, lng) {
                  seleccion = LatLng(lat, lng);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        );

        if (seleccion != null) {
          setState(() {
            latitud = seleccion!.latitude;
            longitud = seleccion!.longitude;
            ubicacionConfirmada = true;
          });
        }
      },
      icon: const Icon(Icons.map_outlined),
      label: const Text('Mapa'),
    ),
  ],
),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: saveVisita,
              icon: Icon(editingId == null ? Icons.save : Icons.update),
              label: Text(editingId == null ? 'Registrar' : 'Actualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}


  Future<void> saveVisita() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      "pacienteId": pacienteId ?? 1, // reemplazar por selector real
      "gestorId": gestorId ?? 1,
      "asignacionId": asignacionId ?? 1,
      "fechaVisita": DateTime.now().toIso8601String(),
      "observacion": observacionController.text.trim(),
      "altura": double.tryParse(alturaController.text) ?? 0,
      "peso": double.tryParse(pesoController.text) ?? 0,
      "tieneAgua": tieneAgua,
      "tieneLuz": tieneLuz,
      "tieneInternet": tieneInternet,
      "latitud": latitud ?? 0.0,
      "longitud": longitud ?? 0.0,
      "ubicacionConfirmada": ubicacionConfirmada,
    };

    final ok = editingId == null
        ? await ApiService.createVisita(data)
        : await ApiService.updateVisita(editingId!, data);

    if (ok) {
      Navigator.pop(context);
      fetchVisitas();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Error al guardar visita')),
      );
    }
  }

  Future<void> deleteVisita(int id) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar Visita?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await ApiService.deleteVisita(id);
              if (ok) fetchVisitas();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        title: const Text('Visitas Domiciliarias'),
        backgroundColor: Colors.teal,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: visitas.length,
              itemBuilder: (_, i) {
                final v = visitas[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text("Paciente ID: ${v['pacienteId']}"),
                    subtitle: Text(
                      "Fecha: ${v['fechaVisita']}\n"
                      "Observación: ${v['observacion'] ?? '-'}\n"
                      "Altura: ${v['altura']} cm | Peso: ${v['peso']} kg\n"
                      "Lat: ${v['latitud']?.toStringAsFixed(4) ?? "-"}, Lng: ${v['longitud']?.toStringAsFixed(4) ?? "-"}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => openForm(visita: v),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteVisita(v['id']),
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
        label: const Text('Nueva Visita'),
        backgroundColor: Colors.teal,
      ),
    );
  }
}
