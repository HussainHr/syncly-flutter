import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncly/core/providers/auth_provider.dart';
import 'package:syncly/features/users/presentation/screens/user_profile_page.dart';

class MyProfilePage extends ConsumerWidget {
  const MyProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    if (me == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }
    return UserProfilePage(uid: me.uid);
  }
}

