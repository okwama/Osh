class NoticeBoard {
  final int id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? countryId;

  NoticeBoard({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.countryId,
  });

  factory NoticeBoard.fromJson(Map<String, dynamic> json) {
    return NoticeBoard(
      id: json['id'],
      title: json['title'] ?? 'No Notice',
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      countryId: json['countryId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'countryId': countryId,
    };
  }
}
