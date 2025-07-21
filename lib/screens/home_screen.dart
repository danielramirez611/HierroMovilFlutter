import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final String rol;
  const HomeScreen({super.key, required this.rol});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Redirección con pequeño delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      final rol = widget.rol.toLowerCase();
      String ruta = '/home';
      if (rol == 'niño') ruta = '/home_nino';
      else if (rol == 'gestante') ruta = '/home_gestante';
      else if (rol == 'gestor') ruta = '/home_gestor';
      else if (rol == 'administrador') ruta = '/home_administrador';

      Navigator.pushReplacementNamed(context, ruta);
    });
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
          Image.asset('assets/hierro.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.4)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _animation,
                  child: Image.asset(
                    'assets/logoH.png',
                    height: 100,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Preparando tu espacio...',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
