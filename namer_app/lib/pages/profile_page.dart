import 'package:flutter/material.dart';
import 'package:namer_app/pages/login_page.dart';
import 'package:namer_app/pages/edit_profile_page.dart';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? user;
  final String? token;
  final Function(Map<String, dynamic>)? onUserUpdated;

  const ProfilePage({super.key, this.user, this.token, this.onUserUpdated});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
  }

  void _navigateToEditProfile() async {
    if (widget.user == null || widget.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para editar tu perfil'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final updatedUser = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          user: widget.user!,
          token: widget.token!,
        ),
      ),
    );

    // Si se actualizó el perfil, notificar a MainPage
    if (updatedUser != null && widget.onUserUpdated != null) {
      widget.onUserUpdated!(updatedUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usa los datos del usuario si existen, si no, muestra valores por defecto.
    final String userName = widget.user?['name'] ?? 'Usuario';
    final String userLastName = widget.user?['lastName'] ?? 'Invitado';
    final String userEmail = widget.user?['email'] ?? 'Sin correo electrónico';
    final String? profilePhoto = widget.user?['profilePhoto'];
    final bool isGuest = widget.user == null;

    ImageProvider? backgroundImage;
    if (profilePhoto != null && profilePhoto.isNotEmpty && profilePhoto.contains(',')) {
      try {
        backgroundImage = MemoryImage(base64Decode(profilePhoto.split(',').last));
      } catch (e) {
        print('Error decodificando imagen Base64: $e');
        backgroundImage = null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: backgroundImage,
                    child: backgroundImage == null
                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                  if (!isGuest)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                          onPressed: _navigateToEditProfile,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '$userName $userLastName',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                userEmail,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              if (isGuest) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Modo invitado',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 30),
              if (!isGuest) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar Perfil'),
                    onPressed: _navigateToEditProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: Text(isGuest ? 'Ir a Iniciar Sesión' : 'Cerrar Sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}