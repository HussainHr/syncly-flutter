// To parse this JSON data, do
//
//     final userModel = userModelFromJson(jsonString);

import 'dart:convert';

UserModel userModelFromJson(String str) => UserModel.fromJson(json.decode(str));

String userModelToJson(UserModel data) => json.encode(data.toJson());

class UserModel {
  String? status;
  String? message;
  UserData? data;

  UserModel({
    this.status,
    this.message,
    this.data,
  });

  UserModel copyWith({
    String? status,
    String? message,
    UserData? data,
  }) =>
      UserModel(
        status: status ?? this.status,
        message: message ?? this.message,
        data: data ?? this.data,
      );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    status: json["status"],
    message: json["message"],
    data: json["data"] == null ? null : UserData.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

class UserData {
  int? id;
  String? name;
  String? email;
  String? phone;
  String? photo;
  String? role;
  String? bio;
  String? subscriptionType;
  bool? isVerified;
  bool? isBanned;
  String? createdAt;

  UserData({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.photo,
    this.role,
    this.bio,
    this.subscriptionType,
    this.isVerified,
    this.isBanned,
    this.createdAt,
  });

  UserData copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? photo,
    String? role,
    String? bio,
    String? subscriptionType,
    bool? isVerified,
    bool? isBanned,
    String? createdAt,
  }) =>
      UserData(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        photo: photo ?? this.photo,
        role: role ?? this.role,
        bio: bio ?? this.bio,
        subscriptionType: subscriptionType ?? this.subscriptionType,
        isVerified: isVerified ?? this.isVerified,
        isBanned: isBanned ?? this.isBanned,
        createdAt: createdAt ?? this.createdAt,
      );

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    id: json["id"],
    name: json["name"],
    email: json["email"],
    phone: json["phone"],
    photo: json["photo"],
    role: json["role"],
    bio: json["bio"],
    subscriptionType: json["subscription_type"],
    isVerified: json["is_verified"],
    isBanned: json["is_banned"],
    createdAt: json["created_at"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "phone": phone,
    "photo": photo,
    "role": role,
    "bio": bio,
    "subscription_type": subscriptionType,
    "is_verified": isVerified,
    "is_banned": isBanned,
    "created_at": createdAt,
  };
}
