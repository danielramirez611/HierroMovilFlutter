import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'success_dialog2.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final StringBuffer _buffer = StringBuffer();
  bool _isLoading = false;

  void _addDigit(String digit) {
    if (_isLoading) return;
    setState(() => _buffer.write(digit));
  }

  void _deleteDigit() {
    if (_isLoading) return;
    if (_buffer.isNotEmpty) {
      setState(() => _buffer.clear());
    }
  }

  Future<void> _login() async {
    if (_buffer.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debe ingresar al menos 2 dígitos.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final dni = ApiService.dni;
    final password = _buffer.toString();
    final success = await ApiService.login(dni, password);
    setState(() => _isLoading = false);

    if (success) {
      showSuccessDialog2(
        context,
        onAccept: () {
          Navigator.popUntil(context, ModalRoute.withName('/'));
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Contraseña incorrecta o usuario no encontrado"),
        ),
      );
      setState(() => _buffer.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/hierro.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.4)), // oscurecer fondo

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Niños de Hierro",
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Ingrese su contraseña",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '*' * _buffer.length,
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 16),

              _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: List.generate(12, (index) {
                        if (index == 9) {
                          // Icono de puerta (izquierda)
                          return ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: const Icon(Icons.login, color: Colors.green),
                          );
                        }

                        if (index == 10) {
                          // Número 0 (centro)
                          return _buildKey('0');
                        }

                        if (index == 11) {
                          // Borrar (derecha)
                          return _buildIconKey(Icons.backspace, _deleteDigit);
                        }

                        return _buildKey('${index + 1}');
                      }),
                    ),
                  ),

              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  // Aquí podrías abrir un modal de recuperación
                },
                child: const Text(
                  "¿Olvidaste tu contraseña?",
                  style: TextStyle(
                    color: Colors.lightBlueAccent,
                    decoration: TextDecoration.underline,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String value) {
    return ElevatedButton(
      onPressed: () => _addDigit(value),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 24,
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildIconKey(IconData icon, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      child: Icon(icon, color: Colors.black),
    );
  }
}
