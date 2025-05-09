import 'dart:convert';
import 'dart:io'; // Para capturar errores de red
import 'package:http/http.dart' as http;

class ApiService {
  static String baseUrl = 'https://192.168.18.6:7268/api';
  static String phone = '';
  static String dni = '';

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

  /// Intenta iniciar sesión con DNI y contraseña
  static Future<bool> login(String dni, String password) async {
    try {
      final url = Uri.parse('$baseUrl/Users/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"dni": dni, "password": password}),
      );

      if (response.statusCode == 200) return true;

      print('❌ Error en login: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print('❗ Error en login: $e');
      return false;
    }
  }
}
