import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/api_service.dart';

class PacientesPage extends StatefulWidget {
  const PacientesPage({super.key});

  @override
  State<PacientesPage> createState() => _PacientesPageState();
}

class _PacientesPageState extends State<PacientesPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> pacientes = [];
  List<dynamic> usuarios = [];
  bool loading = true;

  final _formKey = GlobalKey<FormState>();
  int? editingId;
  int? selectedUserId;
  bool tieneAnemia = false;
  bool _anemiaSwitchTouched = false;
  OverlayEntry? _overlayEntry;
  String? filtroRol; // 'niño', 'gestante' o null
  late Animation<double> _fadeAnimation;

  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;

@override
void initState() {
  super.initState();
  fetchData();

  _animationController = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
  );

  _scaleAnimation = CurvedAnimation(
    parent: _animationController!,
    curve: Curves.easeOutBack,
  );

  _fadeAnimation = CurvedAnimation(
    parent: _animationController!,
    curve: Curves.easeIn,
  );
}

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

Future<void> fetchData() async {
  setState(() {
    loading = true;
    _animationController?.reset();
    _animationController?.forward();
  });

  await Future.delayed(const Duration(milliseconds: 600)); // espera animación

  pacientes = filtroRol == null
      ? await ApiService.getPacientes()
      : await ApiService.getPacientesPorRol(filtroRol!);

  usuarios = await ApiService.getUsuariosPacientes();

  if (mounted) {
    _animationController?.reverse(); // desaparece suavemente
    await Future.delayed(const Duration(milliseconds: 300)); // espera que termine fade-out
    setState(() => loading = false);
  }
}


  void resetForm() {
    editingId = null;
    selectedUserId = null;
    tieneAnemia = false;
    _anemiaSwitchTouched = false;
  }

  void showAnimatedSuccessIcon() {
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation!,
              child: Image.asset('assets/check_green.png', height: 100),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_overlayEntry!);
    _animationController!.forward();

    Future.delayed(const Duration(seconds: 2), () {
      _animationController!.reverse();
      _overlayEntry?.remove();
    });
  }

  Future<void> savePaciente() async {
    if (!_formKey.currentState!.validate() || selectedUserId == null) return;

    final alreadyExists = pacientes.any((p) =>
        p['usuario'] != null &&
        p['usuario']['id'] == selectedUserId &&
        editingId == null);

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este usuario ya está registrado como paciente.')),
      );
      return;
    }

    final ok = editingId == null
        ? await ApiService.createPaciente(selectedUserId!, tieneAnemia)
        : await ApiService.updatePaciente(editingId!, selectedUserId!, tieneAnemia);

    if (ok) {
      showAnimatedSuccessIcon();
      await Future.delayed(const Duration(seconds: 2));
      final nuevosPacientes = await ApiService.getPacientes();
      if (mounted) {
        setState(() => pacientes = nuevosPacientes);
      }
      resetForm();
      if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  Widget buildFiltroRolButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ['todos', 'niño', 'gestante'].map((rol) {
          final isSelected = filtroRol == rol || (rol == 'todos' && filtroRol == null);
          final color = isSelected ? Colors.indigo : Colors.grey[300];
          final textColor = isSelected ? Colors.white : Colors.black87;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [BoxShadow(color: Colors.indigo.withOpacity(0.4), blurRadius: 6)]
                    : [],
              ),
              child: InkWell(
                onTap: () async {
                  setState(() => filtroRol = rol == 'todos' ? null : rol);
                  await fetchData();
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    rol.toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pacientes'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          if (!loading)
            pacientes.isEmpty
                ? const Center(child: Text('No hay pacientes registrados.'))
                : Column(
                    children: [
                      buildFiltroRolButtons(),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: pacientes.length,
                          itemBuilder: (_, i) {
                            final p = pacientes[i];
                            final usuario = p['usuario'];
                            final nombre = usuario != null
                                ? "${usuario['firstName']} ${usuario['lastNameP']}"
                                : 'Sin usuario';
                            final tieneAnemiaText = p['tieneAnemia'] ? 'Con anemia' : 'Sin anemia';

                            return AnimatedOpacity(
                              opacity: 1,
                              duration: const Duration(milliseconds: 500),
                              child: Card(
                                elevation: 4,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                margin: const EdgeInsets.only(bottom: 14),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.indigo,
                                    child: Text(nombre.isNotEmpty ? nombre[0] : '?',
                                        style: const TextStyle(color: Colors.white, fontSize: 18)),
                                  ),
                                  title: Text(
                                    nombre,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600, fontSize: 16),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Icon(
                                        p['tieneAnemia'] ? Icons.warning : Icons.check_circle,
                                        color: p['tieneAnemia'] ? Colors.orange : Colors.green,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        tieneAnemiaText,
                                        style: TextStyle(
                                          color: p['tieneAnemia'] ? Colors.orange : Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                        onPressed: () => openForm(paciente: p),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => deletePaciente(p['id']),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
if (loading)
  Container(
    color: Colors.white,
    width: double.infinity,
    height: double.infinity,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnimation!,
            child: Image.asset(
              'assets/logoH.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                print('ERROR al cargar imagen: $error');
                return const Icon(Icons.broken_image, size: 80, color: Colors.red);
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Cargando...',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.indigo,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    ),
  ),


        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openForm(),
        label: const Text("Nuevo paciente"),
        icon: const Icon(Icons.person_add),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  void deletePaciente(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Estás seguro?'),
        content: const Text('Esta acción eliminará el paciente de forma permanente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      final ok = await ApiService.deletePaciente(id);
      if (ok) fetchData();
    }
  }

  void openForm({Map? paciente}) async {
    if (paciente != null) {
      editingId = paciente['id'];
      selectedUserId = paciente['usuario']?['id'];
      tieneAnemia = paciente['tieneAnemia'] ?? false;
    }

    _anemiaSwitchTouched = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[100],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Form(
            key: _formKey,
            child: Wrap(
              runSpacing: 20,
              children: [
                Center(
                  child: Text(
                    editingId == null ? 'Nuevo Paciente' : 'Editar Paciente',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[800],
                    ),
                  ),
                ),
                DropdownButtonFormField<int>(
                  value: selectedUserId,
                  decoration: InputDecoration(
                    labelText: 'Seleccionar usuario',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: usuarios
                      .where((u) {
                        final userId = u['id'];
                        final yaAsignado = pacientes.any((p) =>
                            p['usuario'] != null &&
                            p['usuario']['id'] == userId &&
                            (editingId == null || p['id'] != editingId));
                        return !yaAsignado || userId == selectedUserId;
                      })
                      .map<DropdownMenuItem<int>>((u) => DropdownMenuItem<int>(
                            value: u['id'],
                            child: Text(u['nombre']),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => selectedUserId = val),
                  validator: (val) => val == null ? 'Seleccione un usuario' : null,
                ),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ListTile(
                    leading: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: _anemiaSwitchTouched
                          ? (tieneAnemia
                              ? const Icon(Icons.warning, key: ValueKey('anemia'), color: Colors.orange)
                              : const Icon(Icons.check_circle, key: ValueKey('ok'), color: Colors.green))
                          : const Icon(Icons.check_circle, key: ValueKey('default'), color: Colors.grey),
                    ),
                    title: Text(
                      _anemiaSwitchTouched
                          ? (tieneAnemia ? 'Paciente con Anemia' : 'Paciente sin Anemia')
                          : '¿Tiene Anemia?',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _anemiaSwitchTouched
                            ? (tieneAnemia ? Colors.orange : Colors.green)
                            : Colors.black87,
                      ),
                    ),
                    trailing: Switch(
                      value: tieneAnemia,
                      activeColor: Colors.orange,
                      inactiveThumbColor: Colors.green,
                      onChanged: (val) {
                        setModalState(() {
                          tieneAnemia = val;
                          _anemiaSwitchTouched = true;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: Text(editingId == null ? 'Registrar' : 'Actualizar'),
                    onPressed: savePaciente,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    resetForm();
  }
}
