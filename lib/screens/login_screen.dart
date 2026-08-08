import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const int _pinLength = 4;

  final List<TextEditingController> _controllers =
      List.generate(_pinLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_pinLength, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentPin =>
      _controllers.map((c) => c.text).join();

  void _onDigitEntered(int index, String value) {
    // Only keep the last character if somehow multiple are pasted/typed
    if (value.length > 1) {
      _controllers[index].text = value[value.length - 1];
      _controllers[index].selection = const TextSelection.collapsed(offset: 1);
    }

    if (value.isNotEmpty && index < _pinLength - 1) {
      // Advance focus to next box
      _focusNodes[index + 1].requestFocus();
    } else if (value.isNotEmpty && index == _pinLength - 1) {
      // Last digit entered — unfocus and attempt login
      _focusNodes[index].unfocus();
      _attemptLogin();
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      // Move focus back on backspace when box is empty
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  void _clearPin({bool keepError = false}) {
    for (final c in _controllers) {
      c.clear();
    }
    if (!keepError) {
      setState(() => _errorMessage = null);
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _attemptLogin() async {
    final pin = _currentPin;
    if (pin.length < _pinLength) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call the security-definer RPC that resolves PIN → credentials
      // without exposing the user_pins table to the anon role directly.
      final result = await Supabase.instance.client
          .rpc('get_credentials_for_pin', params: {'pin_code': pin});

      if (result == null || (result is List && result.isEmpty)) {
        setState(() => _errorMessage = 'Ungültige PIN. Bitte erneut versuchen.');
        _clearPin(keepError: true);
        return;
      }

      final data = result is List ? result.first : result;
      final email = data['email'] as String?;
      final password = data['service_password'] as String?;

      if (email == null || password == null) {
        setState(() => _errorMessage = 'Ungültige Anmeldedaten vom Server.');
        _clearPin(keepError: true);
        return;
      }

      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // Auth state change will automatically navigate away via authStateProvider
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
        _clearPin(keepError: true);
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Ein Fehler ist aufgetreten.');
        _clearPin(keepError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Berichtsheft',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'PIN eingeben',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // PIN digit boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pinLength, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _PinBox(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        onChanged: (val) => _onDigitEntered(index, val),
                        onKeyEvent: (event) => _onKeyEvent(index, event),
                        hasError: _errorMessage != null,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                // Error message
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _errorMessage != null
                      ? Text(
                          _errorMessage!,
                          key: ValueKey(_errorMessage),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        )
                      : const SizedBox(height: 18, key: ValueKey('empty')),
                ),

                const SizedBox(height: 16),

                // Loading indicator
                if (_isLoading) const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final void Function(KeyEvent) onKeyEvent;
  final bool hasError;

  const _PinBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: onKeyEvent,
      child: SizedBox(
        width: 52,
        height: 60,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          obscureText: true,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: '',
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? colorScheme.error : colorScheme.outline,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? colorScheme.error : colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.error, width: 2),
            ),
            filled: true,
            // ignore: deprecated_member_use
            fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
