import 'package:flutter/material.dart';
import 'package:namer_app/data/mock_data.dart';
import 'package:namer_app/models/report.dart';
import 'package:namer_app/pages/object_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<bool> _searchType = <bool>[true, false];
  DateTimeRange? _selectedDateRange;
  List<Report> _filteredReports = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterReports);
    _filterReports();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterReports);
    _searchController.dispose();
    super.dispose();
  }

  void _filterReports() {
    setState(() {
      _filteredReports = mockReports.where((report) {
        final searchLower = _searchController.text.toLowerCase();
        final titleMatch = report.title.toLowerCase().contains(searchLower);
        final descriptionMatch =
            report.description.toLowerCase().contains(searchLower);

        final typeIndex = report.category == ReportCategory.lost ? 0 : 1;
        final typeMatch = _searchType[typeIndex];

        bool dateMatch = true;
        if (_selectedDateRange != null) {
          final reportDate =
              DateTime(report.date.year, report.date.month, report.date.day);
          final startDate = DateTime(_selectedDateRange!.start.year,
              _selectedDateRange!.start.month, _selectedDateRange!.start.day);
          final endDate = DateTime(_selectedDateRange!.end.year,
              _selectedDateRange!.end.month, _selectedDateRange!.end.day);
          dateMatch = !reportDate.isBefore(startDate) &&
              !reportDate.isAfter(endDate);
        }

        return (_searchController.text.isEmpty ||
                titleMatch ||
                descriptionMatch) &&
            typeMatch &&
            dateMatch;
      }).toList();
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
        _filterReports();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Objeto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Escribe aquí para buscar...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ToggleButtons(
                  onPressed: (int index) {
                    setState(() {
                      for (int i = 0; i < _searchType.length; i++) {
                        _searchType[i] = i == index;
                      }
                      _filterReports();
                    });
                  },
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  constraints: const BoxConstraints(
                    minHeight: 40.0,
                    minWidth: 100.0,
                  ),
                  isSelected: _searchType,
                  children: const <Widget>[
                    Text('Perdí esto'),
                    Text('Encontré esto'),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.map_outlined),
                  onPressed: () {
                    // TODO: Implement map location selection
                  },
                  tooltip: 'Seleccionar ubicación',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDateRange == null
                        ? 'Ningún rango de fechas seleccionado'
                        : 'Rango: ${_selectedDateRange!.start.toLocal().toString().split(' ')[0]} - ${_selectedDateRange!.end.toLocal().toString().split(' ')[0]}',
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Seleccionar fecha'),
                  onPressed: () => _selectDateRange(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _filterReports,
                child: const Text('Buscar'),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredReports.length,
                itemBuilder: (context, index) {
                  final report = _filteredReports[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ObjectDetailPage(report: report),
                          ),
                        );
                      },
                      child: ListTile(
                        title: Text(report.title),
                        subtitle: Text(
                            '${report.location} - ${report.date.toLocal().toString().split(' ')[0]}'),
                        trailing: Icon(
                          report.category == ReportCategory.lost
                              ? Icons.help_outline
                              : Icons.check_circle_outline,
                          color: report.category == ReportCategory.lost
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}