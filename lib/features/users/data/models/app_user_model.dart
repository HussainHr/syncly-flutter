import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:syncly/features/auth/domain/entities/user_role.dart';

import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.uid,
    required super.email,
    required super.displayName,
    required super.displayNameLowercase,
    required super.bio,
    required super.isOnline,
    required super.createdAt,
    required super.updatedAt,
    super.photoUrl,
    super.photoBase64,
    super.lastSeenAt,
    super.privacyLastSeen,
    super.privacyOnline,
    super.privacyPhoto,
    super.privacyAbout,
    super.readReceiptsEnabled,
    super.typingIndicatorEnabled,
    super.role,
  });

  static DateTime _readDate(dynamic value, {DateTime? fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? (fallback ?? DateTime.now());
    return fallback ?? DateTime.now();
  }

  factory AppUserModel.fromFirestore(Map<String, dynamic> json, {required String uid}) {
    final displayName = (json['displayName'] as String?)?.trim();
    final email = (json['email'] as String?)?.trim();
    final lower = (json['displayNameLowercase'] as String?)?.trim();

    final createdAt = _readDate(json['createdAt']);
    final updatedAt = _readDate(json['updatedAt'], fallback: createdAt);

    return AppUserModel(
      uid: uid,
      email: email ?? '',
      displayName: displayName?.isNotEmpty == true ? displayName! : (email?.split('@').first ?? 'User'),
      displayNameLowercase: (lower?.isNotEmpty == true
              ? lower
              : (displayName?.toLowerCase() ?? (email?.toLowerCase() ?? 'user')))
          .toString(),
      photoUrl: json['photoUrl'] as String?,
      photoBase64: json['photoBase64'] as String?,
      bio: (json['bio'] as String?) ?? '',
      isOnline: (json['isOnline'] as bool?) ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastSeenAt: json['lastSeenAt'] == null ? null : _readDate(json['lastSeenAt']),
      privacyLastSeen: PrivacyAudience.fromString(json['privacyLastSeen'] as String?),
      privacyOnline: PrivacyAudience.fromString(json['privacyOnline'] as String?),
      privacyPhoto: PrivacyAudience.fromString(json['privacyPhoto'] as String?),
      privacyAbout: PrivacyAudience.fromString(json['privacyAbout'] as String?),
      readReceiptsEnabled: (json['readReceiptsEnabled'] as bool?) ?? true,
      typingIndicatorEnabled: (json['typingIndicatorEnabled'] as bool?) ?? true,
      role: UserRole.fromString(json['role'] as String?),
    );
  }
}

