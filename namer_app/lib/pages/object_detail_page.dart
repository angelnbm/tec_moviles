import 'package:flutter/material.dart';
import 'package:namer_app/models/report.dart';
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
        child: ListView(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ubicación:', style: Theme.of(context).textTheme.titleLarge),
                    Text(report.location),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: () {
                    // TODO: Implement map view logic
                  },
                  tooltip: 'Ver en mapa',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Fecha:', style: Theme.of(context).textTheme.titleLarge),
            Text(formattedDate),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Text('Información de contacto', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            const ListTile(
              leading: CircleAvatar(child: Icon(Icons.person)),
              title: Text('Usuario invitado'),
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.message),
                label: const Text('Contactar'),
                onPressed: () {
                  // TODO: Implement contact logic
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}