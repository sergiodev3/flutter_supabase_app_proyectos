// lib/data/models/user_profile_model.dart

import '../../domain/entities/user_profile.dart';

/// Modelo de perfil: serialización JSON ↔ [UserProfile].
class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.email,
    required super.createdAt,
    super.fullName,
    super.avatarUrl,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id:        json['id']         as String,
      email:     json['email']      as String,
      fullName:  json['full_name']  as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'full_name':  fullName,
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
