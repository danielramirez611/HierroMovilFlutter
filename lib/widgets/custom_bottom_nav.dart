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
        case 2: _showLoadingAndNavigate(context, '/asignacion'); break;
        case 3: _showLoadingAndNavigate(context, '/visitas'); break;
        case 4: _showLoadingAndNavigate(context, '/alertas'); break;
      }
    } else if (rol == 'gestante' || rol == 'niño') {
      switch (index) {
        case 0: _showLoadingAndNavigate(context, '/visitas'); break;
        case 1: _showLoadingAndNavigate(context, '/comunicados'); break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildNavItems();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.indigo[600],
          unselectedItemColor: Colors.grey[500],
          selectedFontSize: 14,
          unselectedFontSize: 12,
          iconSize: 26,
          onTap: onTap ?? (index) => _handleNavigation(context, index),
          items: items,
          showUnselectedLabels: true,
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavItems() {
    if (rol == 'administrador') {
      return [
        _buildStyledItem(Icons.person_rounded, 'Pacientes', 0),
        _buildStyledItem(Icons.local_hospital, 'Tambos', 1),
        _buildStyledItem(Icons.assignment_add, 'Asignacion', 2),
        _buildStyledItem(Icons.follow_the_signs_outlined, 'Visitas', 3),
        _buildStyledItem(Icons.notifications_none_outlined, 'Alertas', 4),

      ];
    } else {
      return [
        _buildStyledItem(Icons.home_rounded, 'Visitas', 0),
        _buildStyledItem(Icons.campaign_outlined, 'Comunicados', 1),
      ];
    }
  }

  BottomNavigationBarItem _buildStyledItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: index == currentIndex ? Colors.indigo.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon),
      ),
      label: label,
    );
  }
}
