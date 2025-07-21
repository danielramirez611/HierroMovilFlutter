import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';
import '../utils/verification_helper.dart';

class DniScreen extends StatefulWidget {
  const DniScreen({super.key});

  @override
  State<DniScreen> createState() => _DniScreenState();
}

class _DniScreenState extends State<DniScreen> with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  bool _isLoading = false;
  bool _isVerified = false;

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkVerificationStatus() async {
    final verified = await VerificationHelper.isPhoneVerified();
    setState(() => _isVerified = verified);
  }

  Future<void> _handleSubmit() async {
    final dni = _dniController.text.trim();
    var phone = _phoneController.text.trim();

    if (dni.isEmpty) {
      _showMessage('Debe ingresar su DNI.');
      return;
    }

    ApiService.dni = dni;

    if (_isVerified) {
      Navigator.pushNamed(context, '/password');
    } else {
      if (phone.isEmpty) {
        _showMessage('Debe ingresar su número de celular.');
        return;
      }

      if (!phone.startsWith('+')) {
        phone = '+$phone';
      }

      ApiService.phone = phone;

      setState(() => _isLoading = true);
      final success = await ApiService.sendVerification(phone);
      setState(() => _isLoading = false);

      if (success) {
        Navigator.pushNamed(context, '/code');
      } else {
        _showMessage('No se pudo enviar el código. Verifica el número.');
      }
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/hierro.jpg',
            fit: BoxFit.cover,
          ),

          // Filtro de desenfoque con capa oscura
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),

          // Contenido
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 26),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/logoH.png', height: 60),
                      const SizedBox(height: 18),
                      Text(
                        _isVerified
                            ? "Verificación de Identidad"
                            : "Verifica tu número de celular",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isVerified
                            ? "Ingresa tu DNI para continuar"
                            : "Ingresa tu número de celular y tu DNI",
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (!_isVerified)
                        CustomInput(
                          controller: _phoneController,
                          hint: 'Teléfono',
                          icon: Icons.phone_android_rounded,
                          isNumber: true,
                        ),
                      CustomInput(
                        controller: _dniController,
                        hint: 'DNI',
                        icon: Icons.credit_card_rounded,
                        isNumber: true,
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : CustomButton(
                              text: 'Continuar',
                              onPressed: _handleSubmit,
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
}
