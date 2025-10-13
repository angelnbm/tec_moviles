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
  final List<bool> _searchType = <bool>[false, false];
  DateTimeRange? _selectedDateRange;
  List<Report> _filteredReports = [];
  bool _filtersActive = false;

  @override
  void initState() {
    super.initState();
    // _searchController.addListener(_applyFilters); // No longer needed here
  }

  @override
  void dispose() {
    // _searchController.removeListener(_applyFilters); // No longer needed here
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    if (!_filtersActive) {
      setState(() {
        _filteredReports = [];
      });
      return;
    }

    setState(() {
      _filteredReports = mockReports.where((report) {
        final searchLower = _searchController.text.toLowerCase();
        final titleMatch = report.title.toLowerCase().contains(searchLower);
        final descriptionMatch =
            report.description.toLowerCase().contains(searchLower);

        bool typeMatch = true;
        if (_searchType.contains(true)) {
          final typeIndex = report.category == ReportCategory.lost ? 0 : 1;
          typeMatch = _searchType[typeIndex];
        }

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

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      for (int i = 0; i < _searchType.length; i++) {
        _searchType[i] = false;
      }
      _selectedDateRange = null;
      _filtersActive = false;
      _filteredReports = [];
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
        // _filtersActive = true; // This will be set by the search button
        // _applyFilters(); // This will be called by the search button
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Objeto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_off_outlined),
            onPressed: _resetFilters,
            tooltip: 'Desactivar filtros',
          ),
        ],
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
              onChanged: (value) {
                // No longer apply filters on change
              },
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
                      // _filtersActive = true; // This will be set by the search button
                      // _applyFilters(); // This will be called by the search button
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
            TextField(
              readOnly: true,
              onTap: () => _selectDateRange(context),
              decoration: InputDecoration(
                hintText: 'Seleccionar rango de fechas',
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today),
                labelText: _selectedDateRange == null
                    ? 'Rango de Fechas'
                    : '${_selectedDateRange!.start.toLocal().toString().split(' ')[0]} - ${_selectedDateRange!.end.toLocal().toString().split(' ')[0]}',
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _filtersActive = true;
                  });
                  _applyFilters();
                },
                child: const Text('Buscar'),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _filteredReports.isEmpty && _filtersActive
                  ? const Center(child: Text('No se encontraron resultados.'))
                  : ListView.builder(
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
                                  builder: (context) =>
                                      ObjectDetailPage(report: report),
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