import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapaSelector extends StatefulWidget {
  final Function(double lat, double lng) onUbicacionSeleccionada;
  final double? latInicial;
  final double? lngInicial;

  const MapaSelector({
    super.key,
    required this.onUbicacionSeleccionada,
    this.latInicial,
    this.lngInicial,
  });

  @override
  State<MapaSelector> createState() => _MapaSelectorState();
}

class _MapaSelectorState extends State<MapaSelector> {
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

    final ubicacion = LatLng(posicion.latitude, posicion.longitude);

    if (!limitesPeru.contains(ubicacion)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠ La ubicación actual está fuera del Perú')),
      );
      return;
    }

    setState(() {
      punto = ubicacion;
      fueraDePeru = false;
    });

    // Opcional: seleccionar automáticamente la ubicación al obtenerla
    // widget.onUbicacionSeleccionada(punto.latitude, punto.longitude);
    // Navigator.of(context).pop();

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo obtener la ubicación actual')),
    );
  }
}

  late LatLng punto;
  final LatLng centroDefault = LatLng(-9.189967, -75.015152); // Centro Perú
  final LatLngBounds limitesPeru = LatLngBounds(
    LatLng(-18.5, -82.0), // suroeste
    LatLng(0.5, -67.0),   // noreste
  );

  bool fueraDePeru = false;

  @override
  void initState() {
    super.initState();

    LatLng inicial = centroDefault;

    if (widget.latInicial != null && widget.lngInicial != null) {
      final intento = LatLng(widget.latInicial!, widget.lngInicial!);
      if (limitesPeru.contains(intento)) {
        inicial = intento;
      } else {
        fueraDePeru = true; // marcar que se salió del Perú
      }
    }

    punto = inicial;
  }

  @override
  Widget build(BuildContext context) {
    // Usar centro seguro para evitar AssertionError
// Si la ubicación está fuera de Perú, fuerza centro seguro
LatLng centroSeguro = punto;
if (!limitesPeru.contains(punto)) {
  centroSeguro = centroDefault;
  // También corrige el punto para evitar reuso futuro fuera de los límites
  WidgetsBinding.instance.addPostFrameCallback((_) {
    setState(() {
      punto = centroDefault;
      fueraDePeru = true;
    });
  });
}

    // Mostrar alerta si estaba fuera de Perú
    if (fueraDePeru) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠ Ubicación fuera del Perú. Mostrando mapa centrado.'),
            duration: Duration(seconds: 3),
          ),
        );
      });
    }

    return Column(
  children: [
    Expanded(
      child: FlutterMap(
        options: MapOptions(
          center: limitesPeru.contains(punto) ? punto : centroDefault,
          zoom: 6.5,
          minZoom: 5,
          maxZoom: 18,
          cameraConstraint: CameraConstraint.contain(bounds: limitesPeru),
          onTap: (_, latlng) {
            if (limitesPeru.contains(latlng)) {
              setState(() {
                punto = latlng;
                fueraDePeru = false;
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('⚠ Selección fuera del Perú')),
              );
            }
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.hierro.flutter',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: punto,
                width: 50,
                height: 50,
                child: const Icon(Icons.location_on, color: Colors.red, size: 35),
              ),
            ],
          ),
        ],
      ),
    ),
    const SizedBox(height: 10),
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: obtenerUbicacionActual,
          icon: const Icon(Icons.my_location),
          label: const Text('Ubicación actual'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (!limitesPeru.contains(punto)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('⚠ No puedes seleccionar una ubicación fuera del Perú')),
              );
              return;
            }

            widget.onUbicacionSeleccionada(punto.latitude, punto.longitude);
          },
          icon: const Icon(Icons.check),
          label: const Text('Usar esta ubicación'),
        ),
      ],
    ),
    const SizedBox(height: 10),
  ],
)
;
  }
}
