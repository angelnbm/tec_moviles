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