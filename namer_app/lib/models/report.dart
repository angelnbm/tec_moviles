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