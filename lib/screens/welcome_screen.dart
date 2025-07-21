import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bgBlur;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoGlow;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _bgBlur = Tween<double>(begin: 5.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeOut)),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.5, curve: Curves.elasticOut)),
    );

    _logoGlow = Tween<double>(begin: 0.0, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.5, curve: Curves.easeInOut)),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 0.8, curve: Curves.easeIn)),
    );

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 0.9, curve: Curves.easeOut)),
    );

    _buttonScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0, curve: Curves.elasticOut)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🌄 Fondo con desenfoque animado
          Image.asset('assets/hierro.jpg', fit: BoxFit.cover),
          AnimatedBuilder(
            animation: _bgBlur,
            builder: (_, __) => BackdropFilter(
              filter: ImageFilter.blur(sigmaX: _bgBlur.value, sigmaY: _bgBlur.value),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),

          // 🌟 Contenido principal
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔥 Logo animado con flare glow
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(_logoGlow.value),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: Image.asset('assets/logoH.png', fit: BoxFit.contain),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // ✨ Título flotante con opacidad y elevación
                  FadeTransition(
                    opacity: _titleOpacity,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: const Text(
                        "Niños de Hierro",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.white60,
                              blurRadius: 18,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 📄 Descripción
                  FadeTransition(
                    opacity: _titleOpacity,
                    child: const Text(
                      "Inicia sesión\ny conoce nuestra política de privacidad.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 🚀 Botón con rebote animado
                  ScaleTransition(
                    scale: _buttonScale,
                    child: CustomButton(
                      text: 'Aceptar y continuar',
                      onPressed: () => Navigator.pushNamed(context, '/dni'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
