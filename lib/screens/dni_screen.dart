import 'package:flutter/material.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';

class DniScreen extends StatefulWidget {
  const DniScreen({super.key});

  @override
  State<DniScreen> createState() => _DniScreenState();
}

class _DniScreenState extends State<DniScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendCode() async {
    String phone = _phoneController.text.trim();
    String dni = _dniController.text.trim();

    if (phone.isEmpty || dni.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe ingresar ambos campos.')),
      );
      return;
    }

    // Asegura formato +51...
    if (!phone.startsWith('+')) {
      phone = '+$phone';
    }

    setState(() {
      _isLoading = true;
    });

    ApiService.dni = dni;
    ApiService.phone = phone;

    final success = await ApiService.sendVerification(phone);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.pushNamed(context, '/code');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar el código. Verifica el número.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset('assets/hierro.jpg', fit: BoxFit.cover, height: double.infinity),
          Container(color: Colors.black.withOpacity(0.3)),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Ingrese su número de celular y DNI",
                    style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  CustomInput(controller: _phoneController, hint: 'Teléfono', icon: Icons.phone, isNumber: true),
                  CustomInput(controller: _dniController, hint: 'DNI', icon: Icons.badge, isNumber: true),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : CustomButton(text: 'Siguiente', onPressed: _sendCode),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
