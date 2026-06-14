class Topic {
  final String id;
  final String title;

  Topic({required this.id, required this.title});

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(id: json['id'], title: json['title']);
  }
}
