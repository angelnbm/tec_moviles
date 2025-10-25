import 'package:namer_app/models/report.dart';

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