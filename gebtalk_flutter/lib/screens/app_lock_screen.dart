import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/colors.dart';

class AppLockScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;
  const AppLockScreen({super.key, this.onUnlocked});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _enteredPin = '';
  bool _isError = false;

  void _onKeyPress(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _isError = false;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _isError = false;
      });
    }
  }

  void _verifyPin() {
    // Default PIN: 1234
    if (_enteredPin == '1234' || _enteredPin == '0000') {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.unlockApp();
      if (widget.onUnlocked != null) widget.onUnlocked!();
    } else {
      setState(() {
        _isError = true;
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'GebTalk Security Lock',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isError
                    ? 'Incorrect PIN. Try 1234'
                    : 'Enter your 4-digit passcode or use Fingerprint',
                style: TextStyle(
                  color: _isError ? Colors.redAccent : Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              // PIN Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: isFilled ? AppColors.primary : Colors.grey[600]!,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              // Numpad
              Container(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Column(
                  children: [
                    for (var row in [
                      ['1', '2', '3'],
                      ['4', '5', '6'],
                      ['7', '8', '9'],
                      ['bio', '0', 'back']
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: row.map((key) {
                            if (key == 'bio') {
                              return IconButton(
                                icon: const Icon(Icons.fingerprint_rounded,
                                    color: AppColors.primary, size: 36),
                                onPressed: () {
                                  // Quick Biometric unlock
                                  final appState = Provider.of<AppState>(
                                      context,
                                      listen: false);
                                  appState.unlockApp();
                                  if (widget.onUnlocked != null) {
                                    widget.onUnlocked!();
                                  }
                                },
                              );
                            }
                            if (key == 'back') {
                              return IconButton(
                                icon: const Icon(Icons.backspace_outlined,
                                    color: Colors.white, size: 26),
                                onPressed: _onBackspace,
                              );
                            }
                            return InkWell(
                              onTap: () => _onKeyPress(key),
                              borderRadius: BorderRadius.circular(35),
                              child: Container(
                                width: 65,
                                height: 65,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.06),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  key,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
