class ExampleUser {
  const ExampleUser({required this.id, required this.name});

  factory ExampleUser.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Expected a user object.');
    }

    final Object? id = json['id'];
    final Object? name = json['name'];
    if (id is! int || name is! String) {
      throw const FormatException('Expected an integer id and a string name.');
    }

    return ExampleUser(id: id, name: name);
  }

  Map<String, Object?> toJson() => {'id': id, 'name': name};

  final int id;
  final String name;
}
