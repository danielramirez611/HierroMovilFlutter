// screens/code_verification_screen.dart
import 'package:flutter/material.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';
import 'success_dialog.dart';
import '../utils/verification_helper.dart'; // ✅ Asegúrate de importar esto

class CodeVerificationScreen extends StatelessWidget {
  const CodeVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController _codeController = TextEditingController();

    Future<void> _verify() async {
      final code = _codeController.text.trim();
      final result = await ApiService.checkVerification(ApiService.phone, code);
      if (result) {
 // ✅ Guardar que el celular ya fue verificado
        await VerificationHelper.savePhoneVerified();

        showSuccessDialog(
          context,
          onAccept: () => Navigator.pushNamed(context, '/password'),
        );      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código incorrecto')));
      }
    }

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
                  const Text("Verificación de código",
                      style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  CustomInput(controller: _codeController, hint: 'Código recibido', icon: Icons.message, isNumber: true),
                  const SizedBox(height: 20),
                  CustomButton(text: 'Verificar', onPressed: _verify),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
