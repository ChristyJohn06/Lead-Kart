class UserModel {
  final String userId;
  final String authUserId;
  final String username;
  final String userType; // "Student" or "Staff"
  final String email;
  final String? phone;
  final String name;
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.authUserId,
    required this.username,
    required this.userType,
    required this.email,
    this.phone,
    required this.name,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'],
      authUserId: json['auth_user_id'],
      username: json['username'],
      userType: json['user_type'],
      email: json['email'],
      phone: json['phone'],
      name: json['name'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'auth_user_id': authUserId,
      'username': username,
      'user_type': userType,
      'email': email,
      'phone': phone,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'auth_user_id': authUserId,
      'username': username,
      'user_type': userType,
      'email': email,
      'phone': phone,
      'name': name,
    };
  }

  UserModel copyWith({
    String? userId,
    String? authUserId,
    String? username,
    String? userType,
    String? email,
    String? phone,
    String? name,
    DateTime? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      authUserId: authUserId ?? this.authUserId,
      username: username ?? this.username,
      userType: userType ?? this.userType,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
