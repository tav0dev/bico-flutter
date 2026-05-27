import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bico_provider.dart';

class BicoField extends StatelessWidget {
  final String? label;
  final String? placeholder;
  final bool obscureText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final IconData? leadingIcon;
  final Widget? trailing;
  final String? error;
  final String? hint;

  const BicoField({
    super.key,
    this.label,
    this.placeholder,
    this.obscureText = false,
    this.controller,
    this.onChanged,
    this.leadingIcon,
    this.trailing,
    this.error,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: tokens.text,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: tokens.bgSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: error != null ? tokens.red : tokens.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 18, color: tokens.textMuted),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  obscureText: obscureText,
                  style: TextStyle(
                    fontSize: 16,
                    color: tokens.text,
                  ),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: TextStyle(color: tokens.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        if (hint != null && error == null) ...[
          const SizedBox(height: 5),
          Text(hint!, style: TextStyle(fontSize: 12, color: tokens.textMuted)),
        ],
        if (error != null) ...[
          const SizedBox(height: 5),
          Text(error!, style: TextStyle(fontSize: 12, color: tokens.red)),
        ],
      ],
    );
  }
}
