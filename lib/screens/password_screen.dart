import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'success_dialog2.dart';
import '../utils/verification_helper.dart';
import '../screens/home_screen.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> with TickerProviderStateMixin {
  final StringBuffer _buffer = StringBuffer();
  bool _isLoading = false;
  bool _errorShake = false;

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );

    _controller.forward();
  }

  void _addDigit(String digit) {
  if (_isLoading) return;

  if (_buffer.length >= 10) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Máximo 10 dígitos permitidos.")),
    );
    return;
  }

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
      _triggerErrorShake();
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
      await VerificationHelper.saveLoginDate();
      final user = ApiService.currentUser;
      final rol = (user?['rol'] ?? user?['role'])?.toString().toLowerCase() ?? 'niño';

      showSuccessDialog2(
        context,
        onAccept: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(rol: rol)),
          );
        },
      );
    } else {
      _triggerErrorShake();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contraseña incorrecta o usuario no encontrado")),
      );
      setState(() => _buffer.clear());
    }
  }

  void _triggerErrorShake() {
    setState(() => _errorShake = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() => _errorShake = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/hierro.jpg', fit: BoxFit.cover),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.5), Colors.black.withOpacity(0.3)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.translationValues(_errorShake ? 8.0 : 0.0, 0, 0),
                  margin: const EdgeInsets.symmetric(horizontal: 26),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Hero(
                        tag: 'logo',
                        child: Image.asset('assets/logoH.png', height: 60),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Ingrese su contraseña",
                        style: TextStyle(fontSize: 18, color: Colors.white),
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
                      const SizedBox(height: 24),
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : GridView.count(
                              shrinkWrap: true,
                              crossAxisCount: 3,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              children: List.generate(12, (index) {
                                if (index == 9) {
                                  return _buildActionKey(Icons.check, _login, Colors.green);
                                } else if (index == 10) {
                                  return _buildKey('0');
                                } else if (index == 11) {
                                  return _buildActionKey(Icons.backspace, _deleteDigit, Colors.red);
                                } else {
                                  return _buildKey('${index + 1}');
                                }
                              }),
                            ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Funcionalidad aún no implementada")),
                          );
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String value) {
    return InkWell(
      onTap: () => _addDigit(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey(IconData icon, VoidCallback onTap, Color color) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.85),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
      ),
      child: Icon(icon, color: color),
    );
  }
}
