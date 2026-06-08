import 'package:equatable/equatable.dart';

class Friendship extends Equatable {
  final String id;
  final String uidA;
  final String uidB;
  final DateTime createdAt;

  const Friendship({
    required this.id,
    required this.uidA,
    required this.uidB,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, uidA, uidB, createdAt];
}

