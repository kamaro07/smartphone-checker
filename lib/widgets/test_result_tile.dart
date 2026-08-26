import 'package:flutter/material.dart';

class TestResultTile extends StatelessWidget {
  final String testName;
  final bool? result; // null = running, true = success, false = fail

  const TestResultTile({Key? key, required this.testName, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    if (result == null) {
      icon = Icons.hourglass_top;
      color = Colors.grey;
    } else if (result == true) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else {
      icon = Icons.error;
      color = Colors.red;
    }
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(testName),
      subtitle: result == null ? const Text('Executando...') : Text(result! ? 'Sucesso' : 'Falha'),
    );
  }
}
