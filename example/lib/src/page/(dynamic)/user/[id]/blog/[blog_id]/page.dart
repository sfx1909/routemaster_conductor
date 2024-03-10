import 'dart:convert';

import 'package:flutter/material.dart';

class BlogPostPage extends StatelessWidget {
  const BlogPostPage({
    super.key,
    required this.blogId,
    required this.id,
  });

  final String blogId;
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          const JsonEncoder.withIndent(' ').convert(
            {
              'id': id,
              'blogId': blogId,
            },
          ),
        ),
      ),
    );
  }
}
