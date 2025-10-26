import 'package:flutter/material.dart';
import 'package:namer_app/pages/login_page.dart';

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic>? user;

  const ProfilePage({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    // Usa los datos del usuario si existen, si no, muestra valores por defecto.
    final String userName = user?['name'] ?? 'Usuario invitado';
    final String userEmail = user?['email'] ?? 'Sin correo electrónico';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(
                  radius: 60,
                  child: Icon(Icons.person, size: 60),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () {
                        // TODO: Implement image change logic
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              userName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              userEmail,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Editar información'),
              onPressed: () {
                // TODO: Implement edit information logic
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}