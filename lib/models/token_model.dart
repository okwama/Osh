class Token {
  final int id;
  final String token;
  final int userId;
  final DateTime createdAt;
  final DateTime expiresAt;

  Token({
    required this.id,
    required this.token,
    required this.userId,
    required this.createdAt,
    required this.expiresAt,
  });

  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
      id: json['id'],
      token: json['token'],
      userId: json['userId'],
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'token': token,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}
