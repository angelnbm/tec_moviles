import 'package:flutter/material.dart';
import 'package:namer_app/data/mock_data.dart';
import 'package:namer_app/models/report.dart';

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