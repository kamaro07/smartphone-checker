import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

class ButtonsTestScreen extends StatefulWidget {
  const ButtonsTestScreen({super.key});

  @override
  State<ButtonsTestScreen> createState() => _ButtonsTestScreenState();
}

class _ButtonsTestScreenState extends State<ButtonsTestScreen> with WidgetsBindingObserver {
  bool _volumeUpPressed = false;
  bool _volumeDownPressed = false;
  bool _powerButtonPressed = false;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Request focus so we can intercept RawKeyboard events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_powerButtonPressed) {
        setState(() {
          _powerButtonPressed = true;
        });
        _checkCompletion();
      }
    } else if (state == AppLifecycleState.paused) {
      // The user locked the screen (power button), which causes paused -> resumed when unlocking
      // We will count it as power button pressed once they resume.
    }
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.audioVolumeUp) {
        if (!_volumeUpPressed) {
          setState(() {
            _volumeUpPressed = true;
          });
          _checkCompletion();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
        if (!_volumeDownPressed) {
          setState(() {
            _volumeDownPressed = true;
          });
          _checkCompletion();
        }
      }
    }
  }

  void _checkCompletion() {
    if (_volumeUpPressed && _volumeDownPressed && _powerButtonPressed) {
      // Small delay so the user sees the green checkmarks before it closes
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    }
  }

  Widget _buildCheckItem(String title, bool isChecked, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isChecked ? Colors.green.shade50 : Colors.white,
        border: Border.all(color: isChecked ? Colors.green : Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: isChecked ? Colors.green : Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isChecked ? Colors.green.shade700 : Colors.black87,
              ),
            ),
          ),
          if (isChecked)
            const Icon(Icons.check_circle, color: Colors.green, size: 32)
          else
            const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 32),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      autofocus: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Teste de Botões Físicos'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Pressione os botões abaixo no seu aparelho para testá-los:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              _buildCheckItem('Botão Volume +', _volumeUpPressed, Icons.volume_up),
              _buildCheckItem('Botão Volume -', _volumeDownPressed, Icons.volume_down),
              _buildCheckItem('Botão Power (Bloquear Tela)', _powerButtonPressed, Icons.power_settings_new),
              
              const Spacer(),
              const Text(
                'Nota: Para testar o botão Power, apenas bloqueie a tela do aparelho e desbloqueie novamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('Reprovar Teste Manualmente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
