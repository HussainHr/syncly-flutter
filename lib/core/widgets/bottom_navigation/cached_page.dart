import 'package:flutter/material.dart';

class CachedPage extends StatefulWidget {
  final Widget child;

  const CachedPage({super.key, required this.child});

  @override
  _KeepInMemoryState createState() => _KeepInMemoryState();
}

class _KeepInMemoryState extends State<CachedPage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
