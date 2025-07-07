// Test file with intentional linter errors to demonstrate the debug script

import 'dart:io'; // This import will be unused
import 'package:flutter/material.dart';

class TestWidget extends StatefulWidget {
  final String title; // This field will be unused
  final int count;

  const TestWidget({super.key, required this.title, required this.count});

  @override
  State<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> {
  final String _message = "Hello"; // This will trigger prefer_single_quotes

  @override
  Widget build(BuildContext context) {
    print("Building widget"); // This will trigger avoid_print

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.title), // This will trigger prefer_const_constructors
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                "Count: ${widget.count}"), // This will trigger prefer_const_constructors
            ElevatedButton(
              onPressed: () async {
                await Future.delayed(Duration(seconds: 1));
                Navigator.pop(
                    context); // This will trigger use_build_context_synchronously
              },
              child: Text(
                  "Go Back"), // This will trigger prefer_const_constructors
            ),
          ],
        ),
      ),
    );
  }
}
