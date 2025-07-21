import 'package:shared_preferences/shared_preferences.dart';

class VerificationHelper {
  static const _lastLoginKey = 'last_login_date';
  static const _isVerifiedKey = 'is_verified'; // ✅ nuevo

  /// Guarda la fecha del último inicio de sesión exitoso
  static Future<void> saveLoginDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
  }

  /// Verifica si es necesario volver a iniciar sesión (más de 30 días)
  static Future<bool> needsLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_lastLoginKey);

    if (dateStr == null) return true;

    final lastDate = DateTime.tryParse(dateStr);
    if (lastDate == null) return true;

    final diff = DateTime.now().difference(lastDate);
    return diff.inDays >= 30;
  }

  /// Limpia la fecha de login
  static Future<void> clearLoginDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastLoginKey);
  }

  /// ✅ Guarda que el celular fue verificado
  static Future<void> savePhoneVerified() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isVerifiedKey, true);
  }

  /// ✅ Verifica si ya se validó el celular
  static Future<bool> isPhoneVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isVerifiedKey) ?? false;
  }

  /// ✅ Limpia el estado de verificación (por ejemplo al cerrar sesión)
  static Future<void> clearVerificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isVerifiedKey);
  }
}
