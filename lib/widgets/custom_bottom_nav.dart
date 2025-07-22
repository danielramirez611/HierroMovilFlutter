import 'package:flutter/material.dart';
import '../widgets/loading_dialog.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int)? onTap;
  final String rol;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.rol,
    this.onTap,
  });

  void _showLoadingAndNavigate(BuildContext context, String route) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingDialog(),
    );

    await Future.delayed(const Duration(milliseconds: 800));
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }

  void _handleNavigation(BuildContext context, int index) {
    if (rol == 'administrador') {
      switch (index) {
        case 0: _showLoadingAndNavigate(context, '/pacientes'); break;
        case 1: _showLoadingAndNavigate(context, '/tambos'); break;
        case 2: _showLoadingAndNavigate(context, '/visitas'); break;
        case 3: _showLoadingAndNavigate(context, '/perfil'); break;
      }
    } else {
      switch (index) {
        case 0: _showLoadingAndNavigate(context, '/visitas'); break;
        case 1: _showLoadingAndNavigate(context, '/comunicados'); break;
        case 2: _showLoadingAndNavigate(context, '/perfil'); break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildNavItems();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            backgroundColor: Colors.grey[100],
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.indigo,
            unselectedItemColor: Colors.grey,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            onTap: onTap ?? (index) => _handleNavigation(context, index),
            showUnselectedLabels: false,
            elevation: 0,
            items: items,
          ),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavItems() {
    final isAdmin = rol == 'administrador';

    final iconLabels = isAdmin
        ? [
            [Icons.person_rounded, 'Pacientes'],
            [Icons.local_hospital_outlined, 'Tambos'],
             [Icons.dashboard_outlined, 'Inicio'],        // 👉 nuevo ítem para dashboard
            [Icons.follow_the_signs_outlined, 'Visitas'],
            [Icons.account_circle, 'Perfil'],
          ]
        : [
            [Icons.home_rounded, 'Visitas'],
            [Icons.campaign_outlined, 'Comunicados'],
            [Icons.account_circle, 'Perfil'],
          ];

    return List.generate(iconLabels.length, (index) {
      final icon = iconLabels[index][0] as IconData;
      final label = iconLabels[index][1] as String;

      return BottomNavigationBarItem(
        icon: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: currentIndex == index ? Colors.indigo.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 26),
        ),
        label: label,
      );
    });
  }
}
