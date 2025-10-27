import 'package:flutter/material.dart';
import 'package:namer_app/pages/login_page.dart';
import 'package:namer_app/pages/edit_profile_page.dart';
import 'package:namer_app/services/api_service.dart';
import 'package:namer_app/widgets/profile_avatar.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? user;

  const ProfilePage({super.key, this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await ApiService.getUserData();
    if (userData != null && mounted) {
      setState(() {
        _currentUser = userData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usa los datos del usuario si existen, si no, muestra valores por defecto.
    final String userName = _currentUser?['name'] ?? 'Usuario';
    final String userLastName = _currentUser?['lastName'] ?? 'Invitado';
    final String userEmail = _currentUser?['email'] ?? 'invitado@utalca.cl';
    final String userRut = _currentUser?['rut'] ?? 'Sin RUT';
    final String? profileImage = _currentUser?['profileImage'];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con foto de perfil
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      ProfileAvatar(
                        profileImageBase64: profileImage,
                        radius: 60,
                        borderColor: const Color(0xFFD32F2F),
                        borderWidth: 4,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$userName $userLastName',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Información personal
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Color(0xFFD32F2F),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Información Personal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    icon: Icons.badge_outlined,
                    label: 'RUT',
                    value: userRut,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    icon: Icons.person_outline,
                    label: 'Nombre',
                    value: userName,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    icon: Icons.person_outline,
                    label: 'Apellido',
                    value: userLastName,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    icon: Icons.email_outlined,
                    label: 'Correo electrónico',
                    value: userEmail,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Opciones
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildOptionTile(
                    context: context,
                    icon: Icons.edit_outlined,
                    title: 'Editar información',
                    subtitle: 'Actualiza tus datos personales',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(user: _currentUser!),
                        ),
                      );
                      
                      // Si se actualizó el perfil, recargar los datos
                      if (result != null) {
                        setState(() {
                          _currentUser = result;
                        });
                      }
                    },
                  ),
                  const Divider(height: 1),
                  _buildOptionTile(
                    context: context,
                    icon: Icons.lock_outline,
                    title: 'Cambiar contraseña',
                    subtitle: 'Actualiza tu contraseña',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Función próximamente disponible'),
                          backgroundColor: Color(0xFFD32F2F),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildOptionTile(
                    context: context,
                    icon: Icons.notifications_outlined,
                    title: 'Notificaciones',
                    subtitle: 'Configura tus preferencias',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Función próximamente disponible'),
                          backgroundColor: Color(0xFFD32F2F),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Botón de cerrar sesión
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD32F2F).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.logout,
                                  color: Color(0xFFD32F2F),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('Cerrar sesión'),
                            ],
                          ),
                          content: const Text(
                            '¿Estás seguro que deseas cerrar sesión?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                  (Route<dynamic> route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD32F2F),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Cerrar sesión'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: const Color(0xFFD32F2F).withOpacity(0.3),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Footer
            Column(
              children: [
                Icon(
                  Icons.school,
                  color: Colors.grey[400],
                  size: 20,
                ),
                const SizedBox(height: 8),
                Text(
                  '© 2025 Universidad de Talca',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sistema de Objetos Perdidos',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFD32F2F).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFFD32F2F),
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}