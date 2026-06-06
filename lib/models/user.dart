class User {
  final int? id;
  final String username;
  final String email;
  final String password;
  final String displayName;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.displayName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      password: '',
      displayName: (json['display_name'] ?? json['username'])?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'display_name': displayName,
    };
  }
}