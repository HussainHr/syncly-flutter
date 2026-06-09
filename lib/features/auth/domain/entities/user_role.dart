enum UserRole {
  host,
  member;

  String toFirestore() => name;

  static UserRole fromString(String? value) {
    return switch ((value ?? '').toLowerCase()) {
      'host' => UserRole.host,
      _ => UserRole.member,
    };
  }

  String get label => switch (this) {
        UserRole.host => 'Host',
        UserRole.member => 'Member',
      };

  String get description => switch (this) {
        UserRole.host => 'Create and manage workspaces',
        UserRole.member => 'Join workspaces with an invite code',
      };
}
