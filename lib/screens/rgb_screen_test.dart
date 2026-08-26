import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

class RgbScreenTest extends StatefulWidget {
  const RgbScreenTest({super.key});

  @override
  State<RgbScreenTest> createState() => _RgbScreenTestState();
}

class _RgbScreenTestState extends State<RgbScreenTest> {
  int _currentIndex = 0;
  final List<Color> _colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.white,
    Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _nextColor() {
    if (_currentIndex < _colors.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('rgb_question'.tr()),
          actions: <Widget>[
            TextButton(
              child: Text('btn_no'.tr()),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(false); // Return result
              },
            ),
            TextButton(
              child: Text('btn_yes'.tr()),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(true); // Return result
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _nextColor,
        child: Container(
          color: _colors[_currentIndex],
          width: double.infinity,
          height: double.infinity,
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'rgb_instruction'.tr(),
                  style: TextStyle(
                    color: _colors[_currentIndex] == Colors.white ? Colors.black : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
