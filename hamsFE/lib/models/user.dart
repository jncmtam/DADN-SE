class User {
  final String id;
  final String name;
  final String email;
  // final String avatarUrl;
  // final String gender;
  final DateTime? joinDate;
  final String role;
  final bool emailVerified;

  User({
    required this.id,
    required this.name,
    required this.email,
    // required this.avatarUrl,
    required this.joinDate,
    required this.role,
    required this.emailVerified,
  });

  // Map<String, dynamic> toJson();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 'N/A',
      name: json['username'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
      // avatarUrl: json['avatarUrl'] ??
      //     'https://drive.google.com/uc?export=view&id=1df6TULh5Q0RWm4c_P7BGIvfIh7jSivPr', // default avatar
      role: json['role'] ?? 'N/A',
      joinDate: DateTime.parse(json['created_at']),
      emailVerified: json['is_email_verified'] ?? false,
    );
  }
}

// {
// "id": "ec45993c-1094-499a-b932-1534edee4e24",
// "username": "admin1",
// "email": "admin@example.com",
// "PasswordHash": "$2b$12$VTeoBTSBoWy6ncrFXqx4Vu/XVTaCXCjXrBY3gmqm7/1aCT6rnHLdi",
// "OTPSecret": "",
// "is_email_verified": true,
// "role": "admin",
// "created_at": "2025-03-21T00:26:05.708043Z",
// "updated_at": "2025-03-21T00:26:05.708043Z"
// }