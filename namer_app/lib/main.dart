import 'package:flutter/material.dart';
import 'dart:math';

// --- DATA MODELS ---

enum ReportCategory { found, lost }

class Report {
  final String title;
  final String description;
  final ReportCategory category;
  final String location;
  final DateTime date;
  final String? imageUrl;

  Report({
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.date,
    this.imageUrl,
  });
}

// --- MOCK DATA ---

final List<Report> mockReports = List.generate(
  20,
  (index) => Report(
    title: 'Objeto #${index + 1}',
    description: 'Descripción detallada del objeto perdido o encontrado número ${index + 1}.',
    category: index % 3 == 0 ? ReportCategory.lost : ReportCategory.found,
    location: 'Edificio ${index % 5 + 1}, Campus Talca',
    date: DateTime.now().subtract(Duration(days: index)),
  ),
);

void main() {
  runApp(const LossUtalApp());
}

class LossUtalApp extends StatelessWidget {
  const LossUtalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loss UTAL',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Espacio para el logo
              SizedBox(
                height: 150,
                child: Center(child: Image.asset('assets/images/logo.png')), // Placeholder para el logo
              ),
              const SizedBox(height: 30),

              // Título y subtítulo
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.headlineLarge,
                  children: const [
                    TextSpan(text: 'LOSS '),
                    TextSpan(
                      text: 'UTALCA',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Text(
                'Objetos perdidos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 50),

              // Botón Iniciar Sesión
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginFormPage()),
                    );
                  },
                  child: const Text('Iniciar sesión', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 20),

              // Botón Explorar como invitado
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainPage()),
                  );
                },
                child: Text(
                  'Explorar como invitado',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginFormPage extends StatelessWidget {
  const LoginFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Lógica de inicio de sesión
              },
              child: const Text('Ingresar'),
            ),
          ],
        ),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    GuestLandingPage(),
    MyReportsPage(),
    SearchPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
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

class GuestLandingPage extends StatefulWidget {
  const GuestLandingPage({super.key});

  @override
  State<GuestLandingPage> createState() => _GuestLandingPageState();
}

class _GuestLandingPageState extends State<GuestLandingPage> {
  int _currentPage = 1;
  final int _itemsPerPage = 5;
  late int _totalPages;
  late List<Report> _reports;

  @override
  void initState() {
    super.initState();
    _reports = mockReports;
    _totalPages = (_reports.length / _itemsPerPage).ceil();
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = min(startIndex + _itemsPerPage, _reports.length);
    final List<Report> paginatedReports = _reports.sublist(startIndex, endIndex);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 18, color: Colors.black),
                children: [
                  TextSpan(text: 'LOSS '),
                  TextSpan(
                    text: 'UTALCA',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Text('Objetos perdidos', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: paginatedReports.length,
              itemBuilder: (context, index) {
                final report = paginatedReports[index];
                final reportType = report.category == ReportCategory.found
                    ? 'Encontré esto'
                    : 'Busco esto';
                final formattedDate = "${report.date.day}/${report.date.month}/${report.date.year}";

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                    title: Text(report.title),
                    subtitle: Text(
                        '${report.location} - $formattedDate\nTipo: $reportType'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ObjectDetailPage(report: report),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewReportPage()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Reporte'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48), // Ancho completo
              ),
            ),
          ),
          _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_totalPages, (index) {
            final page = index + 1;
            return TextButton(
              onPressed: () => _goToPage(page),
              style: TextButton.styleFrom(
                backgroundColor: _currentPage == page ? Colors.blue : Colors.transparent,
                foregroundColor: _currentPage == page ? Colors.white : Colors.blue,
              ),
              child: Text('$page'),
            );
          }),
        ),
      ),
    );
  }
}

class ObjectDetailPage extends StatelessWidget {
  final Report report;

  const ObjectDetailPage({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final reportType = report.category == ReportCategory.found
        ? 'Objeto Encontrado'
        : 'Objeto Perdido';
    final formattedDate = "${report.date.day}/${report.date.month}/${report.date.year}";

    return Scaffold(
      appBar: AppBar(
        title: Text(report.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reportType, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.image, size: 100, color: Colors.grey)),
            ),
            const SizedBox(height: 20),
            Text('Descripción:', style: Theme.of(context).textTheme.titleLarge),
            Text(report.description),
            const SizedBox(height: 20),
            Text('Ubicación:', style: Theme.of(context).textTheme.titleLarge),
            Text(report.location),
            const SizedBox(height: 20),
            Text('Fecha:', style: Theme.of(context).textTheme.titleLarge),
            Text(formattedDate),
          ],
        ),
      ),
    );
  }
}

class MyReportsPage extends StatelessWidget {
  const MyReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // En una app real, esta lista se filtraría por el usuario actual
    final myReports = mockReports.sublist(0, 5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reportes'),
      ),
      body: ListView.builder(
        itemCount: myReports.length,
        itemBuilder: (context, index) {
          final report = myReports[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.title, style: Theme.of(context).textTheme.titleLarge),
                  Text(report.description),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () {}, child: const Text('Editar')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Marcar como Resuelto'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Objeto'),
      ),
      body: const Center(
        child: Text('Aquí podrás buscar objetos.'),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Aquí verás tu perfil.'),
            const SizedBox(height: 30),
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

class NewReportPage extends StatefulWidget {
  const NewReportPage({super.key});

  @override
  State<NewReportPage> createState() => _NewReportPageState();
}

class _NewReportPageState extends State<NewReportPage> {
  final _formKey = GlobalKey<FormState>();
  ReportCategory _selectedCategory = ReportCategory.found;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Reporte'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Este campo es requerido' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Este campo es requerido' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<ReportCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: ReportCategory.found,
                    child: Text('Encontré este objeto'),
                  ),
                  DropdownMenuItem(
                    value: ReportCategory.lost,
                    child: Text('Perdí este objeto'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              const Text('Imagen (opcional)'),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () { /* Lógica para abrir cámara */ },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Cámara'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () { /* Lógica para abrir galería */ },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galería'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Lógica para guardar el reporte
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Crear Reporte', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}