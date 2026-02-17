class NoteModel {
  final String id;
  final String content;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.content,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NoteModel.fromMap(Map<dynamic, dynamic> map) {
    return NoteModel(
      id: map['id'],
      content: map['content'],
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
