// lib/widgets/test_result_tile.dart
import 'package:flutter/material.dart';

class TestResultTile extends StatelessWidget {
  final String label;
  final String? result;

  const TestResultTile({
    Key? key,
    required this.label,
    this.result,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bg;
    String display;
    if (result == null) {
      bg = Colors.grey.shade200;
      display = 'Not run';
    } else if (result == 'Running...') {
      bg = Colors.yellow.shade200;
      display = 'Running...';
    } else if (result!.startsWith('Error')) {
      bg = Colors.red.shade200;
      display = result!;
    } else {
      bg = Colors.green.shade200;
      display = result!;
    }
    return Card(
      color: bg,
      child: ListTile(
        title: Text(label),
        subtitle: Text(display),
      ),
    );
  }
}
