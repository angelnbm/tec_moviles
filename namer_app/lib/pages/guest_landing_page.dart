import 'dart:math';
import 'package:flutter/material.dart';
import 'package:namer_app/data/mock_data.dart';
import 'package:namer_app/models/report.dart';
import 'package:namer_app/pages/new_report_page.dart';
import 'package:namer_app/pages/object_detail_page.dart';

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