import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String baseUrl = 'https://192.168.18.10:7268/api';
  static String phone = '';
  static String dni = '';

  static Map<String, dynamic>? currentUser;
  //-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//
                                                                             /// DNI ///
  /// Envía un código SMS al número proporcionado
  static Future<bool> sendVerification(String number) async {
    try {
      if (!number.startsWith('+')) {
        number = '+$number';
      }

      phone = number;

      final url = Uri.parse('$baseUrl/Users/verify/send');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"phone": number}),
      );

      if (response.statusCode == 200) return true;

      print('❌ Error al enviar código: ${response.statusCode} - ${response.body}');
      return false;
    } on SocketException catch (e) {
      print('⚠️ Error de red: $e');
      return false;
    } catch (e) {
      print('❗ Excepción inesperada en sendVerification: $e');
      return false;
    }
  }

  /// Verifica el código ingresado por el usuario
  static Future<bool> checkVerification(String number, String code) async {
    try {
      final url = Uri.parse('$baseUrl/Users/verify/check');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"phone": number, "code": code}),
      );

      if (response.statusCode == 200) return true;

      print('❌ Código incorrecto o expirado: ${response.body}');
      return false;
    } catch (e) {
      print('❗ Error en checkVerification: $e');
      return false;
    }
  }

  /// Obtiene datos de RENIEC por DNI
  static Future<Map<String, String>?> getReniecData(String dni) async {
    try {
      final url = Uri.parse('$baseUrl/Users/dni');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"dni": dni}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'firstName': data['firstName'],
          'lastNameP': data['lastNameP'],
          'lastNameM': data['lastNameM'],
        };
      }

      print('❌ Error obteniendo datos de RENIEC: ${response.body}');
      return null;
    } catch (e) {
      print('❗ Error en getReniecData: $e');
      return null;
    }
  }

  /// Inicia sesión con DNI y contraseña
  static Future<bool> login(String dni, String password) async {
    try {
      final url = Uri.parse('$baseUrl/Users/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"dni": dni, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Usuario logueado: $data');

        // Validar que exista la clave esperada
        if (!data.containsKey('rol') && !data.containsKey('role')) {
          print('⚠️ El backend no envió "rol" ni "role"');
          return false;
        }

        currentUser = data;
        return true;
      }

      print('❌ Error en login: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print('❗ Error en login: $e');
      return false;
    }
  }
 
 /// 🔄 Obtener todos los usuarios
static Future<List<dynamic>> getAllUsers() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/Users'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('❌ Error al obtener usuarios: ${response.body}');
      return [];
    }
  } catch (e) {
    print('❗ Error en getAllUsers: $e');
    return [];
  }
}

                                                                             /// DNI ///
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//
                                                                             /// PACIENTES ///
/// 🔄 Obtener todos los pacientes
static Future<List<dynamic>> getPacientes() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/Pacientes'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('❌ Error al obtener pacientes: ${response.body}');
      return [];
    }
  } catch (e) {
    print('❗ Error en getPacientes: $e');
    return [];
  }
}

/// 🔄 Obtener usuarios elegibles para paciente (Niño o Gestante)
static Future<List<dynamic>> getUsuariosPacientes() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/Pacientes/usuarios-pacientes'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('❌ Error al obtener usuarios pacientes: ${response.body}');
      return [];
    }
  } catch (e) {
    print('❗ Error en getUsuariosPacientes: $e');
    return [];
  }
}

/// ➕ Crear paciente
static Future<bool> createPaciente(int userId, bool tieneAnemia) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/Pacientes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "userId": userId,
        "tieneAnemia": tieneAnemia,
      }),
    );

    return response.statusCode == 201;
  } catch (e) {
    print('❗ Error en createPaciente: $e');
    return false;
  }
}

/// ✏️ Actualizar paciente
static Future<bool> updatePaciente(int id, int userId, bool tieneAnemia) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/Pacientes/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "id": id,
        "userId": userId,
        "tieneAnemia": tieneAnemia,
      }),
    );

    return response.statusCode == 204;
  } catch (e) {
    print('❗ Error en updatePaciente: $e');
    return false;
  }
}

/// ❌ Eliminar paciente
static Future<bool> deletePaciente(int id) async {
  try {
    final response = await http.delete(Uri.parse('$baseUrl/Pacientes/$id'));
    return response.statusCode == 204;
  } catch (e) {
    print('❗ Error en deletePaciente: $e');
    return false;
  }
}

/// 🔍 Obtener pacientes filtrados por rol
static Future<List<dynamic>> getPacientesPorRol(String rol) async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/Pacientes/filtrar?rol=$rol'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('❌ Error al filtrar pacientes: ${response.body}');
      return [];
    }
  } catch (e) {
    print('❗ Error en getPacientesPorRol: $e');
    return [];
  }
}
                                                                              /// PACIENTES ///
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//
                                                                              /// TAMBOS ///
/// 🔄 Obtener todos los tambos
static Future<List<dynamic>> getTambos() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/Tambos'));
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  } catch (e) {
    print('❗ Error en getTambos: $e');
    return [];
  }
}

/// ➕ Crear tambo
static Future<bool> createTambo(Map<String, dynamic> data) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/tambos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    debugPrint('RESPONSE STATUS: ${response.statusCode}');
    debugPrint('RESPONSE BODY: ${response.body}');

    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    debugPrint('ERROR EN createTambo: $e');
    return false;
  }
}

/// ✏️ Actualizar tambo
static Future<bool> updateTambo(int id, Map<String, dynamic> data) async {
  try {
    final res = await http.put(
      Uri.parse('$baseUrl/Tambos/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return res.statusCode == 204;
  } catch (e) {
    print('❗ Error en updateTambo: $e');
    return false;
  }
}

/// ❌ Eliminar tambo
static Future<bool> deleteTambo(int id) async {
  try {
    final res = await http.delete(Uri.parse('$baseUrl/Tambos/$id'));
    return res.statusCode == 204;
  } catch (e) {
    print('❗ Error en deleteTambo: $e');
    return false;
  }
}

/// 🔢 Obtener siguiente código de tambo
static Future<String> getNextCode(String departamento, String provincia, String distrito) async {
  try {
    final uri = Uri.parse('$baseUrl/Tambos/next-code')
        .replace(queryParameters: {
          'departamento': departamento,
          'provincia': provincia,
          'distrito': distrito,
        });

    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return res.body.replaceAll('"', ''); // para evitar comillas extras
    } else {
      print('❌ Error al obtener código: ${res.body}');
      return '';
    }
  } catch (e) {
    print('❗ Error en getNextCode: $e');
    return '';
  }
}


                                                                              /// TAMBOS ///
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//
                                                                              /// UBIGUEO ///
/// 🔄 Departamentos
static Future<List<String>> getDepartamentos() async {
  try {
    final res = await http.get(Uri.parse('$baseUrl/Tambos/departamentos'));
    return res.statusCode == 200 ? List<String>.from(jsonDecode(res.body)) : [];
  } catch (e) {
    print('❗ Error en getDepartamentos: $e');
    return [];
  }
}

/// 🔄 Provincias por departamento
static Future<List<String>> getProvincias(String departamento) async {
  try {
    final res = await http.get(Uri.parse('$baseUrl/Tambos/provincias/$departamento'));
    return res.statusCode == 200 ? List<String>.from(jsonDecode(res.body)) : [];
  } catch (e) {
    print('❗ Error en getProvincias: $e');
    return [];
  }
}

/// 🔄 Distritos por provincia
static Future<List<String>> getDistritos(String departamento, String provincia) async {
  try {
    final res = await http.get(Uri.parse('$baseUrl/Tambos/distritos/$departamento/$provincia'));
    return res.statusCode == 200 ? List<String>.from(jsonDecode(res.body)) : [];
  } catch (e) {
    print('❗ Error en getDistritos: $e');
    return [];
  }
}
                                                                              /// UBIGUEO ///
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//
                                                                              /// ASIGNACION TAMBO ///
/// Obtener asignaciones completas
static Future<List<dynamic>> getAsignacionesExtendidas() async {
  try {
    final res = await http.get(Uri.parse('$baseUrl/Asignaciones/extendidas'));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  } catch (e) {
    print('❗ Error en getAsignacionesExtendidas: $e');
    return [];
  }
}

/// Obtener gestores disponibles
static Future<List<dynamic>> getGestoresDisponibles() async {
  try {
    final res = await http.get(Uri.parse('$baseUrl/Asignaciones/gestores-disponibles'));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  } catch (e) {
    print('❗ Error en getGestoresDisponibles: $e');
    return [];
  }
}

/// Obtener tambos disponibles
static Future<List<dynamic>> getTambosDisponibles({
  String? departamento,
  String? provincia,
  String? distrito,
}) async {
  try {
    final uri = Uri.parse('$baseUrl/Asignaciones/tambos-disponibles').replace(queryParameters: {
      if (departamento != null) 'departamento': departamento,
      if (provincia != null) 'provincia': provincia,
      if (distrito != null) 'distrito': distrito,
    });

    final res = await http.get(uri);
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  } catch (e) {
    print('❗ Error en getTambosDisponibles: $e');
    return [];
  }
}

/// Crear asignación
static Future<bool> createAsignacion(Map<String, dynamic> data) async {
  try {
    final res = await http.post(
      Uri.parse('$baseUrl/Asignaciones'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return res.statusCode == 201;
  } catch (e) {
    print('❗ Error en createAsignacion: $e');
    return false;
  }
}

/// Editar asignación
static Future<bool> updateAsignacion(int id, Map<String, dynamic> data) async {
  try {
    final res = await http.put(
      Uri.parse('$baseUrl/Asignaciones/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return res.statusCode == 204;
  } catch (e) {
    print('❗ Error en updateAsignacion: $e');
    return false;
  }
}

/// Eliminar asignación
static Future<bool> deleteAsignacion(int id) async {
  try {
    final res = await http.delete(Uri.parse('$baseUrl/Asignaciones/$id'));
    return res.statusCode == 204;
  } catch (e) {
    print('❗ Error en deleteAsignacion: $e');
    return false;
  }
}
static Future<bool> deleteAsignacionPermanente(int id) async {
  try {
    final res = await http.delete(Uri.parse('$baseUrl/Asignaciones/$id/hard'));
    print('DELETE HARD => ${res.statusCode} | ${res.body}');
    return res.statusCode == 204;
  } catch (e) {
    print('❗ Error en deleteAsignacionPermanente: $e');
    return false;
  }
}
                                                                             /// ASIGNACION TAMBO ///
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//
                                                                             /// VISITAS ///
//🔄 Obtener todas las visitas domiciliarias
static Future<List<dynamic>> getVisitas() async {
  try{
    final response = await http.get(Uri.parse('$baseUrl/VisitaDomiciliaria'));
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }catch (e){
    print('!Error en visualizacion de visitas: $e');
    return [];
  }
}

/// 🔍 Obtener una visita por ID
static Future <Map<String, dynamic>?> getVisitasById(int id) async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/visitasDomiciliaria/$id'));
    if (response.statusCode == 200 )  return jsonDecode(response.body);
    return null;

  } catch (e) {
    print('! Error en ver la visitas por ID: $e');
    return null;
  }
}

/// ➕ Crear visita domiciliaria
static Future<bool> createVisita(Map<String, dynamic> data) async {
  try {
    final response = await http.post(Uri.parse('$baseUrl/VisitaDomiciliaria'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
    );
    return response.statusCode == 201;
  } catch (e) {
    print('! Error en crear la visita: $e');
    return false;
  }
}

/// ✏️ Actualizar visita domiciliaria
static Future<bool> updateVisita(int id, Map<String, dynamic> data) async {
  try {
    final response = await http.put(Uri.parse('$baseUrl/VisitaDomiciliaria/$id'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
    );
    return response.statusCode == 204;
  } catch (e) {
    print('! Error en actualizar visita: $e');
    return false;
  }
}

/// ❌ Eliminar visita domiciliaria
static Future<bool> deleteVisita(int id) async {
  try {
    final response = await http.delete(Uri.parse('$baseUrl/VisitaDomiciliaria/$id'));
    return response.statusCode == 204 ;
  } catch (e) {
    print('!Error al eliminar visita: $e');
    return false;
  }
}

/// 🔄 Obtener visitas por paciente
static Future<List<dynamic>> getVisitasPorPaciente(int pacienteId) async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/VisitaDomiciliaria/paciente/$pacienteId'));
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  } catch (e) {
    print('❗ Error al ver visitas por paciente: $e');
    return [];
  }
}

/// 🔄 Obtener visitas por gestor
static Future<List<dynamic>> getVisitasPorGestor(int gestorId) async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/VisitaDomiciliaria/gestor/$gestorId'));
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  } catch (e) {
    print('❗ Error a ver visitas por gestor: $e');
    return [];
  }
}

/// 🔄 Obtener pacientes sin visita hoy
static Future<List<dynamic>> getPacientesSinVisitaHoy(int gestorId) async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/VisitaDomiciliaria/no-registradas-hoy/$gestorId'));
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  } catch (e) {
    print('❗ Error en ver visitas del gestor del dia de hoy: $e');
    return [];
  }
}

/// 🔁 Sincronizar visitas offline
static Future<bool> sincronizarVisitasOffline(List<Map<String, dynamic>> visitas) async {
  try {
    final response = await http.post(Uri.parse('$baseUrl/VisitaDomiciliaria/sincronizar-offline'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(visitas),
    );
    return response.statusCode == 200;
  } catch (e) {
     print('!Error al sincronizar envio de visita sin cobertura a red: $e');
     return false;
  }
}
                                                                             /// VISITAS ///
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//
}
