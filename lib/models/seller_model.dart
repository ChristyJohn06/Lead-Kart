class SellerModel {
  final String sellerId;
  final String authUserId;
  final String username;
  final String brandName;
  final String email;
  final String? phone;
  final String status; // "online" or "offline"
  final DateTime createdAt;

  SellerModel({
    required this.sellerId,
    required this.authUserId,
    required this.username,
    required this.brandName,
    required this.email,
    this.phone,
    required this.status,
    required this.createdAt,
  });

  factory SellerModel.fromJson(Map<String, dynamic> json) {
    return SellerModel(
      sellerId: json['seller_id'],
      authUserId: json['auth_user_id'],
      username: json['username'],
      brandName: json['brand_name'],
      email: json['email'],
      phone: json['phone'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seller_id': sellerId,
      'auth_user_id': authUserId,
      'username': username,
      'brand_name': brandName,
      'email': email,
      'phone': phone,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'auth_user_id': authUserId,
      'username': username,
      'brand_name': brandName,
      'email': email,
      'phone': phone,
      'status': status,
    };
  }

  SellerModel copyWith({
    String? sellerId,
    String? authUserId,
    String? username,
    String? brandName,
    String? email,
    String? phone,
    String? status,
    DateTime? createdAt,
  }) {
    return SellerModel(
      sellerId: sellerId ?? this.sellerId,
      authUserId: authUserId ?? this.authUserId,
      username: username ?? this.username,
      brandName: brandName ?? this.brandName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
