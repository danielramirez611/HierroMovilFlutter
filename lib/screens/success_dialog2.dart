import 'package:flutter/material.dart';

void showSuccessDialog2(BuildContext context, {VoidCallback? onAccept}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "🎉 Bienvenido a Niños de Hierro",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: const Text("¡Nos alegra tenerte aquí!"),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            if (onAccept != null) onAccept();
          },
          child: const Text("Comenzar"),
        ),
      ],
    ),
  );
}
