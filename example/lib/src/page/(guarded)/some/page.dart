import 'package:flutter/material.dart';

class GuardedPage extends StatelessWidget {
  const GuardedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Guarded'),
      ),
    );
  }
}
