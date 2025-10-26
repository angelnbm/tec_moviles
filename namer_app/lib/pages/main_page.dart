import 'package:flutter/material.dart';
import 'guest_landing_page.dart';
import 'my_reports_page.dart';
import 'search_page.dart';
import 'profile_page.dart';

class MainPage extends StatefulWidget {
  final Map<String, dynamic>? user;
  final String? token;

  const MainPage({super.key, this.user, this.token});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  late Map<String, dynamic>? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _updateUser(Map<String, dynamic> updatedUser) {
    setState(() {
      currentUser = updatedUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      GuestLandingPage(),
      MyReportsPage(),
      SearchPage(),
      ProfilePage(
        user: currentUser,
        token: widget.token,
        onUserUpdated: _updateUser,
      ),
    ];

    return Scaffold(
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Mis Reportes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}