import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final setting = Routemaster.of(context).currentRoute.pathParameters;
    return Scaffold(
      body: Center(
        child: Text(
          const JsonEncoder.withIndent(' ').convert(
            setting,
          ),
        ),
      ),
    );
  }
}
