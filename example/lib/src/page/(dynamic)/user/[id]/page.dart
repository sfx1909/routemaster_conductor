import 'dart:convert';

import 'package:flutter/material.dart';

class UserPage extends StatelessWidget {
  const UserPage({
    super.key,
    required this.id,
  });

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          const JsonEncoder.withIndent(' ').convert(
            {
              'id': id,
            },
          ),
        ),
      ),
    );
  }
}
