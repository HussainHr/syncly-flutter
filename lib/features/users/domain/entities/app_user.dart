import 'package:equatable/equatable.dart';
import 'package:syncly/features/auth/domain/entities/user_role.dart';

enum PrivacyAudience {
  everyone,
  friends,
  nobody;

  static PrivacyAudience fromString(String? v) {
    return switch ((v ?? '').toLowerCase()) {
      'friends' => PrivacyAudience.friends,
      'nobody' => PrivacyAudience.nobody,
      _ => PrivacyAudience.everyone,
    };
  }

  String toFirestore() => name;
}

class AppUser extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String displayNameLowercase;
  final String? photoUrl;
  final String? photoBase64;
  final String bio;
  final bool isOnline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSeenAt;

  // Privacy (WhatsApp-like)
  final PrivacyAudience privacyLastSeen;
  final PrivacyAudience privacyOnline;
  final PrivacyAudience privacyPhoto;
  final PrivacyAudience privacyAbout;
  final bool readReceiptsEnabled;
  final bool typingIndicatorEnabled;
  final UserRole role;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.displayNameLowercase,
    required this.bio,
    required this.isOnline,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.photoBase64,
    this.lastSeenAt,
    this.privacyLastSeen = PrivacyAudience.everyone,
    this.privacyOnline = PrivacyAudience.everyone,
    this.privacyPhoto = PrivacyAudience.everyone,
    this.privacyAbout = PrivacyAudience.everyone,
    this.readReceiptsEnabled = true,
    this.typingIndicatorEnabled = true,
    this.role = UserRole.member,
  });

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        displayNameLowercase,
        photoUrl,
        photoBase64,
        bio,
        isOnline,
        createdAt,
        updatedAt,
        lastSeenAt,
        privacyLastSeen,
        privacyOnline,
        privacyPhoto,
        privacyAbout,
        readReceiptsEnabled,
        typingIndicatorEnabled,
        role,
      ];
}

