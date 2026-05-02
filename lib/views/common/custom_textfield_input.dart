import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextFieldInput extends StatelessWidget {
  const CustomTextFieldInput({
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    super.key,
    this.validator,
    this.suffixIcon,
    this.obscureText,
    this.maxLength,
    this.inputFormatters,
    this.hintStyle,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final bool? obscureText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? hintStyle;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: keyboardType,
      obscureText: obscureText ?? false,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: suffixIcon,
        hintStyle: hintStyle ?? const TextStyle(color: Colors.white70, fontSize: 16),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.red, width: 0.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.red, width: 0.5),
        ),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
      controller: controller,
      cursorHeight: 25,
      style: const TextStyle(color: Colors.white70, fontSize: 16),
      validator: validator,
    );
  }
}
