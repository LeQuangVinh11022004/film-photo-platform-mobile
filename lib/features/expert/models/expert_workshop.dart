class ExpertWorkshop {
  final String id, title, description, startTime, endTime, location, category;
  final DateTime date;
  final int capacity;
  const ExpertWorkshop({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.capacity,
    required this.category,
  });
}
