import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData? suffixIcon;
  final Widget? suffixWidget;
  final bool isPassword;
  final bool? obscureText;
  final bool isRequired;
  final TextEditingController? controller;
  final String? errorText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLength;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    this.suffixIcon,
    this.suffixWidget,
    this.isPassword = false,
    this.obscureText,
    this.isRequired = true,
    this.controller,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
                fontFamily: 'Manrope',
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFE2E8F0),
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            child: TextField(
              controller: controller,
              obscureText: obscureText ?? isPassword,
              readOnly: readOnly,
              onTap: onTap,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              textCapitalization: textCapitalization,
              maxLength: maxLength,
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 15,
                ),
                counterText: '',
                suffixIcon: suffixWidget ??
                    (suffixIcon != null
                        ? Icon(suffixIcon, color: const Color(0xFF64748B), size: 20)
                        : null),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
