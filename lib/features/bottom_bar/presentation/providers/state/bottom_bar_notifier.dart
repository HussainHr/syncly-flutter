import 'package:flutter_riverpod/flutter_riverpod.dart';

class BottomBarState {
  final int selectedIndex;

  const BottomBarState({this.selectedIndex = 0});

  BottomBarState copyWith({int? selectedIndex}) =>
      BottomBarState(selectedIndex: selectedIndex ?? this.selectedIndex);
}

class BottomBarNotifier extends StateNotifier<BottomBarState> {
  BottomBarNotifier() : super(const BottomBarState(selectedIndex: 0));

  void onItemTapped(int index) {
    if (index == state.selectedIndex) return;
    state = state.copyWith(selectedIndex: index);
  }
}

final bottomBarControllerProvider =
    StateNotifierProvider<BottomBarNotifier, BottomBarState>((ref) {
  return BottomBarNotifier();
});

