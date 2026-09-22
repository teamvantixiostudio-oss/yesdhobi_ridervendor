import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yesdhobi_ridervendor/theme.dart';

class OtpInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final String initialValue;

  const OtpInput({
    super.key,
    this.length = 4,
    required this.onChanged,
    this.onCompleted,
    this.initialValue = '',
  });

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (i) => TextEditingController(
        text: i < widget.initialValue.length ? widget.initialValue[i] : '',
      ),
    );
    _focusNodes = List.generate(widget.length, (i) => FocusNode());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Find the first empty box or focus box 0
      int firstEmpty = _controllers.indexWhere((c) => c.text.isEmpty);
      if (firstEmpty == -1) firstEmpty = widget.length - 1;
      _focusNodes[firstEmpty].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentOtp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste
      final clean = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < widget.length; i++) {
        if (i < clean.length) {
          _controllers[i].text = clean[i];
        }
      }
      final lastIndex = (clean.length - 1).clamp(0, widget.length - 1);
      _focusNodes[lastIndex].requestFocus();
      final otp = _currentOtp;
      widget.onChanged(otp);
      if (otp.length == widget.length) {
        widget.onCompleted?.call(otp);
      }
      setState(() {});
      return;
    }

    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      }
    }

    final otp = _currentOtp;
    widget.onChanged(otp);
    if (otp.length == widget.length) {
      widget.onCompleted?.call(otp);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        final isFocused = _focusNodes[index].hasFocus;
        final hasValue = _controllers[index].text.isNotEmpty;

        return Container(
          width: 60,
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: hasValue || isFocused ? Colors.white : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused
                  ? AppTheme.primaryColor
                  : const Color(0xFFE2E8F0),
              width: isFocused ? 2.0 : 1.5,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Placeholder dot when empty and not focused
              if (!hasValue && !isFocused)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                  ),
                ),
              // Focused cursor indicator when empty
              if (!hasValue && isFocused)
                Container(
                  width: 2,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.backspace) {
                    if (_controllers[index].text.isEmpty && index > 0) {
                      _controllers[index - 1].clear();
                      _focusNodes[index - 1].requestFocus();
                      widget.onChanged(_currentOtp);
                      setState(() {});
                    }
                  }
                },
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  showCursor: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) => _onDigitChanged(index, val),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
