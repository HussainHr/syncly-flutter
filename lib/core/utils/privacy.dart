import 'package:syncly/features/friends/presentation/providers/relationship_provider.dart';
import 'package:syncly/features/users/domain/entities/app_user.dart';

bool canSeeByAudience({
  required PrivacyAudience audience,
  required bool isMe,
  required RelationshipStatus relationship,
}) {
  if (isMe) return true;
  return switch (audience) {
    PrivacyAudience.everyone => true,
    PrivacyAudience.friends => relationship == RelationshipStatus.friends,
    PrivacyAudience.nobody => false,
  };
}

