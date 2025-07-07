class Manager {
  final int id;
  final int userId;
  final String? email;
  final String? department;
  final String name;
  final String role;

  Manager({
    required this.id,
    required this.userId,
    this.email,
    this.department,
    required this.name,
    required this.role,
  });

  factory Manager.fromJson(Map<String, dynamic> json) {
    return Manager(
      id: json['id'],
      userId: json['userId'],
      email: json['email'],
      department: json['department'],
      name: json['name'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'email': email,
      'department': department,
      'name': name,
      'role': role,
    };
  }
}
