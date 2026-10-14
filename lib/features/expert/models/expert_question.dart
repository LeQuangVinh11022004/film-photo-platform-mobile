
class ExpertQuestion {
  final String id;
  final String author;
  final String title;
  final String body;
  final String category;
  final DateTime createdAt;
  final List<String> comments;

  const ExpertQuestion({
    required this.id,
    required this.author,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    this.comments = const [],
  });

  ExpertQuestion copyWith({
    List<String>? comments,
  }) {
    return ExpertQuestion(
      id: id,
      author: author,
      title: title,
      body: body,
      category: category,
      createdAt: createdAt,
      comments: comments ?? this.comments,
    );
  }
}
