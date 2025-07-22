import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/api_service.dart';
import '../../widgets/mapa_selector.dart';
import 'package:latlong2/latlong.dart'; // 👈 NECESARIO para usar LatLng correctamente
import 'dart:io';
import 'dart:async';
import 'dart:convert'; // para usar jsonEncode y jsonDecode
import 'package:shared_preferences/shared_preferences.dart'; // para usar SharedPreferences

class VisitasPage extends StatefulWidget {
  const VisitasPage({super.key});

  @override
  State<VisitasPage> createState() => _VisitasPageState();
}

class _VisitasPageState extends State<VisitasPage> {
  List<dynamic> visitas = [];
  List<dynamic> pacientes = [];
  List<dynamic> gestores = [];
  Timer? _internetTimer;

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
    fetchPacientesYGestores();
    startInternetChecker(); // ✅ agrega esta línea
  }

@override
void dispose() {
  _internetTimer?.cancel(); // ✅ importante
  observacionController.dispose();
  alturaController.dispose();
  pesoController.dispose();
  super.dispose();
}
Future<void> sincronizarVisitasOfflineSiExisten() async {
  final prefs = await SharedPreferences.getInstance();
  final offlineData = prefs.getString('visitasOffline');
  if (offlineData != null) {
    final List visitasOffline = jsonDecode(offlineData);
    if (visitasOffline.isNotEmpty) {
      final ok = await ApiService.sincronizarVisitasOffline(visitasOffline.cast<Map<String, dynamic>>());
      if (ok) {
        await prefs.remove('visitasOffline');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Visitas offline sincronizadas.')),
        );
      }
    }
  }
}

void startInternetChecker() {
  _internetTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
    final connected = await hasInternetConnection();
    
    if (!connected) {
      showOfflineBanner(); // ⚠ sin conexión
      return;
    }

    // Si hay conexión:
    hideBanner();

    final prefs = await SharedPreferences.getInstance();
    final offlineData = prefs.getString('visitasOffline');
    final List visitasOffline = offlineData != null ? jsonDecode(offlineData) : [];

    if (visitasOffline.isNotEmpty) {
      // 🟡 Avisar que hay pendientes antes de sincronizar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔄 ${visitasOffline.length} visitas pendientes de sincronizar...'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    await sincronizarVisitasOfflineSiExisten(); // 🔁
    await fetchVisitas(); // 🔄
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
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('⚠ Sin conexión. Mostrando visitas cacheadas.'),
      duration: Duration(days: 1),
    ),
  );
}

void hideBanner() {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
}

  Future<void> fetchPacientesYGestores() async {
    pacientes = await ApiService.getPacientes();
    gestores = await ApiService.getGestoresDisponibles();
    setState(() {});
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
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
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
      builder:
          (context) => Padding(
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
DropdownButtonFormField<int>(
  value: pacientes.any((p) => p['id'] == pacienteId) ? pacienteId : null,
  onChanged: (val) => setState(() => pacienteId = val),
  decoration: const InputDecoration(labelText: 'Paciente'),
  hint: const Text('Selecciona un paciente'),
  items: pacientes.map<DropdownMenuItem<int>>((p) {
    final nombre = p['usuario'] != null
    ? "${p['usuario']['firstName']} ${p['usuario']['lastNameP']}"
    : "Paciente sin datos";

    return DropdownMenuItem<int>(
      value: p['id'],
      child: Text(nombre),
    );
  }).toList(),
  selectedItemBuilder: (context) {
    return pacientes.map<Widget>((p) {
      final nombre = p['usuario'] != null
    ? "${p['usuario']['firstName']} ${p['usuario']['lastNameP']}"
    : "Paciente sin datos";

      return Text(nombre);
    }).toList();
  },
),



                  DropdownButtonFormField<int>(
                    value: gestorId,
                    onChanged: (val) => setState(() => gestorId = val),
                    decoration: const InputDecoration(
                      labelText: 'Gestor',
                    ), // ✅ Agrega esto

                    items:
                        gestores.map<DropdownMenuItem<int>>((g) {
                          final nombre =
                              g['firstName'] != null
                                  ? "${g['firstName']} ${g['lastNameP']}"
                                  : "Gestor ${g['id']}";
                          return DropdownMenuItem(
                            value: g['id'],
                            child: Text(nombre),
                          );
                        }).toList(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Fecha programada de visita'),
                    subtitle: Text('${fechaVisita.toLocal()}'.split(' ')[0]),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fechaVisita,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          fechaVisita = picked;
                        });
                      }
                    },
                  ),

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
                            final servicioHabilitado =
                                await Geolocator.isLocationServiceEnabled();
                            if (!servicioHabilitado) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Activa el GPS del dispositivo',
                                  ),
                                ),
                              );
                              return;
                            }

                            LocationPermission permiso =
                                await Geolocator.checkPermission();
                            if (permiso == LocationPermission.denied ||
                                permiso == LocationPermission.deniedForever) {
                              permiso = await Geolocator.requestPermission();
                              if (permiso == LocationPermission.denied ||
                                  permiso == LocationPermission.deniedForever) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Permiso de ubicación denegado',
                                    ),
                                  ),
                                );
                                return;
                              }
                            }

                            final posicion =
                                await Geolocator.getCurrentPosition(
                                  desiredAccuracy: LocationAccuracy.high,
                                );

                            setState(() {
                              latitud = posicion.latitude;
                              longitud = posicion.longitude;
                              ubicacionConfirmada = true;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Ubicación actual obtenida'),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '❌ Error al obtener la ubicación',
                                ),
                              ),
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
                            builder:
                                (_) => Dialog(
                                  insetPadding: const EdgeInsets.all(16),
                                  child: SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.8,
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
    "pacienteId": pacienteId!,
    "gestorId": gestorId!,
    "asignacionId": asignacionId ?? 1,
    "fechaVisita": fechaVisita.toIso8601String(),
    "observacion": observacionController.text.trim(),
    "altura": double.tryParse(alturaController.text) ?? 0,
    "peso": double.tryParse(pesoController.text) ?? 0,
    "tieneAgua": tieneAgua,
    "tieneLuz": tieneLuz,
    "tieneInternet": tieneInternet,
    "latitud": latitud ?? 0.0,
    "longitud": longitud ?? 0.0,
    "ubicacionConfirmada": ubicacionConfirmada,
    "fechaRegistro": DateTime.now().toIso8601String(),
    "registradoOffline": false,
  };

  final conectado = await hasInternetConnection();

  if (conectado) {
    final ok = editingId == null
        ? await ApiService.createVisita(data)
        : await ApiService.updateVisita(editingId!, data);
    if (ok) {
      Navigator.pop(context);
      fetchVisitas();
    }
  } else {
    // Guardar offline
    final prefs = await SharedPreferences.getInstance();
    final offlineData = prefs.getString('visitasOffline');
    final List visitasOffline = offlineData != null ? jsonDecode(offlineData) : [];
    visitasOffline.add({...data, "registradoOffline": true});
    await prefs.setString('visitasOffline', jsonEncode(visitasOffline));
    Navigator.pop(context);
    fetchVisitas();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Visita guardada offline.')),
    );
  }
}


  Future<void> deleteVisita(int id) async {
    final confirm = await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('¿Eliminar Visita?'),
            content: const Text('Esta acción no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
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
          automaticallyImplyLeading: false, // 👈 ESTO OCULTA LA FLECHA DE RETROCESO

        backgroundColor: Colors.teal,
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: visitas.length,
                itemBuilder: (_, i) {
                  final v = visitas[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text(
                        v['paciente'] != null && v['paciente']['user'] != null
                            ? "${v['paciente']['user']['firstName']} ${v['paciente']['user']['lastNameP']}"
                            : "Paciente ID: ${v['pacienteId']}",
                      ),
                      subtitle: Text(
                        "📅 Visita programada: ${v['fechaVisita']?.split('T').first ?? '-'}\n"
                        "📝 Registro guardado: ${v['fechaRegistro']?.split('T').first ?? '-'}\n"
                        "🌐 Estado: ${v['registradoOffline'] == true ? '📴 Sin conexión' : '✅ En línea'}\n"
                        "📌 Observación: ${v['observacion'] ?? '-'}\n"
                        "📏 Altura: ${v['altura']} cm | ⚖️ Peso: ${v['peso']} kg\n"
                        "🗺️ Lat: ${v['latitud']?.toStringAsFixed(4) ?? "-"}, Lng: ${v['longitud']?.toStringAsFixed(4) ?? "-"}",
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
