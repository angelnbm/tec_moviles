import 'package:flutter/material.dart';
import 'package:namer_app/pages/object_detail_page.dart';
import 'package:namer_app/pages/edit_report_page.dart';
import 'package:namer_app/services/api_service.dart';
import 'package:namer_app/widgets/report_image.dart';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  String _filterStatus = 'Todos'; // Todos, Activos, Resueltos
  List<dynamic> _myReports = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMyReports();
  }

  Future<void> _loadMyReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getMyReports();
      
      if (result['success']) {
        setState(() {
          _myReports = result['data'] as List<dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar reportes: $e';
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getFilteredReports() {
    if (_filterStatus == 'Todos') {
      return _myReports;
    } else if (_filterStatus == 'Activos') {
      return _myReports.where((r) => r['status'] == 'active').toList();
    } else {
      return _myReports.where((r) => r['status'] == 'resolved').toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = _getFilteredReports();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mis Reportes',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_myReports.length} reportes registrados',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFFD32F2F)),
            onPressed: () {
              _showFilterDialog();
            },
            tooltip: 'Filtrar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar reportes',
                        style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadMyReports,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
        children: [
          // Header con estadísticas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  icon: Icons.search,
                  count: _myReports.where((r) => r['category'] == 'lost').length,
                  label: 'Perdidos',
                  color: Colors.orange.shade400,
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                _buildStatCard(
                  icon: Icons.check_circle,
                  count: _myReports.where((r) => r['category'] == 'found').length,
                  label: 'Encontrados',
                  color: Colors.green.shade400,
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                _buildStatCard(
                  icon: Icons.pending_actions,
                  count: _myReports.where((r) => r['status'] == 'active').length,
                  label: 'Activos',
                  color: const Color(0xFFD32F2F),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Chips de filtro
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Activos'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Resueltos'),
                ],
              ),
            ),
          ),
          // Lista de reportes
          Expanded(
            child: filteredReports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tienes reportes',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea tu primer reporte',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadMyReports,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredReports.length,
                      itemBuilder: (context, index) {
                        final report = filteredReports[index];
                        final isLost = report['category'] == 'lost';
                        final createdAt = DateTime.parse(report['createdAt']);
                        final formattedDate = "${createdAt.day}/${createdAt.month}/${createdAt.year}";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ObjectDetailPage(report: report),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header del card
                                  Row(
                                    children: [
                                      // Imagen
                                      ReportImage(
                                        imageBase64: report['imageUrl'],
                                        width: 70,
                                        height: 70,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      const SizedBox(width: 16),
                                      // Información
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    report['title'],
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isLost
                                                        ? Colors.orange.shade50
                                                        : Colors.green.shade50,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: isLost
                                                          ? Colors.orange.shade200
                                                          : Colors.green.shade200,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        isLost ? Icons.search : Icons.check_circle,
                                                        size: 12,
                                                        color: isLost
                                                            ? Colors.orange.shade700
                                                            : Colors.green.shade700,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        isLost ? 'Perdido' : 'Encontrado',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: isLost
                                                              ? Colors.orange.shade700
                                                              : Colors.green.shade700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on_outlined,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    report['location'] ?? 'Sin ubicación',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[700],
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today_outlined,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  formattedDate,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Descripción
                                  Text(
                                    report['description'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  // Botones de acción
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            _showEditDialog(report);
                                          },
                                          icon: const Icon(Icons.edit_outlined, size: 16),
                                          label: const Text('Editar'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFFD32F2F),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            side: const BorderSide(color: Color(0xFFD32F2F)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            _showResolveDialog(report);
                                          },
                                          icon: const Icon(Icons.check_circle_outline, size: 16),
                                          label: const Text('Resolver'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green.shade600,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            elevation: 0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterStatus == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _filterStatus = label;
        });
      },
      selectedColor: const Color(0xFFD32F2F).withOpacity(0.1),
      checkmarkColor: const Color(0xFFD32F2F),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFFD32F2F) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFFD32F2F) : Colors.grey.shade300,
        width: isSelected ? 1.5 : 1,
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Filtrar reportes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.list, color: Color(0xFFD32F2F)),
                ),
                title: const Text('Todos los reportes'),
                onTap: () {
                  setState(() {
                    _filterStatus = 'Todos';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.pending_actions, color: Color(0xFFD32F2F)),
                ),
                title: const Text('Solo activos'),
                onTap: () {
                  setState(() {
                    _filterStatus = 'Activos';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green),
                ),
                title: const Text('Solo resueltos'),
                onTap: () {
                  setState(() {
                    _filterStatus = 'Resueltos';
                  });
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(dynamic report) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditReportPage(report: report),
      ),
    );
    
    // Si se editó exitosamente, recargar la lista
    if (result == true) {
      _loadMyReports();
    }
  }

  void _showResolveDialog(dynamic report) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle, color: Colors.green),
              ),
              const SizedBox(width: 12),
              const Text('Resolver reporte'),
            ],
          ),
          content: Text(
            '¿Deseas marcar el reporte "${report['title']}" como resuelto?\n\nEsta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Cerrar el diálogo de confirmación
                Navigator.pop(dialogContext);
                
                // Usar el contexto del widget principal, no del diálogo
                if (!mounted) return;
                
                // Mostrar indicador de carga
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext loadingContext) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                );
                
                try {
                  // Llamar a la API para marcar como resuelto
                  final result = await ApiService.updateReport(
                    reportId: report['_id'],
                    status: 'resolved',
                  );
                  
                  // Cerrar el indicador de carga
                  if (mounted) {
                    Navigator.pop(context);
                  }
                  
                  if (mounted) {
                    if (result['success']) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 12),
                              Text('Reporte marcado como resuelto'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Recargar la lista
                      _loadMyReports();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${result['message']}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  // En caso de error, cerrar el indicador de carga
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Resolver'),
            ),
          ],
        );
      },
    );
  }
}