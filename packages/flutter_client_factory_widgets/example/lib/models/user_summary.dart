/// The fields this screen needs from its API response.
class UserSummary {
  const UserSummary({required this.id, required this.name});

  factory UserSummary.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected a user object.');
    }
    final id = value['id'];
    final name = value['name'];
    if (id is! int || name is! String) {
      throw const FormatException('Expected an integer id and a string name.');
    }
    return UserSummary(id: id, name: name);
  }

  final int id;
  final String name;
}
