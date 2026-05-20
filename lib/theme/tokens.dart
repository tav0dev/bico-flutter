import 'package:flutter/painting.dart';

class BiccoTokens {
  final Color green;
  final Color greenDark;
  final Color greenSoft;
  final Color purple;
  final Color purpleSoft;
  final Color orange;
  final Color orangeSoft;
  final Color navy;
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color bg;
  final Color bgSoft;
  final Color border;
  final Color borderSoft;
  final Color red;
  final Color redSoft;

  const BiccoTokens({
    required this.green,
    required this.greenDark,
    required this.greenSoft,
    required this.purple,
    required this.purpleSoft,
    required this.orange,
    required this.orangeSoft,
    required this.navy,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.bg,
    required this.bgSoft,
    required this.border,
    required this.borderSoft,
    required this.red,
    required this.redSoft,
  });

  static const light = BiccoTokens(
    green: Color(0xFF16A34A),
    greenDark: Color(0xFF15803D),
    greenSoft: Color(0xFFDCFCE7),
    purple: Color(0xFF4338CA),
    purpleSoft: Color(0xFFEEF2FF),
    orange: Color(0xFFF97316),
    orangeSoft: Color(0xFFFFEDD5),
    navy: Color(0xFF1E293B),
    text: Color(0xFF0F172A),
    textMuted: Color(0xFF64748B),
    textFaint: Color(0xFF94A3B8),
    bg: Color(0xFFFFFFFF),
    bgSoft: Color(0xFFF8FAFC),
    border: Color(0xFFE2E8F0),
    borderSoft: Color(0xFFF1F5F9),
    red: Color(0xFFDC2626),
    redSoft: Color(0xFFFEE2E2),
  );

  static const dark = BiccoTokens(
    green: Color(0xFF22C55E),
    greenDark: Color(0xFF16A34A),
    greenSoft: Color(0x2622C55E),
    purple: Color(0xFF818CF8),
    purpleSoft: Color(0x26818CF8),
    orange: Color(0xFFFB923C),
    orangeSoft: Color(0x26FB923C),
    navy: Color(0xFF1E293B),
    text: Color(0xFFF1F5F9),
    textMuted: Color(0xFF94A3B8),
    textFaint: Color(0xFF64748B),
    bg: Color(0xFF0B1220),
    bgSoft: Color(0xFF0F172A),
    border: Color(0xFF1E293B),
    borderSoft: Color(0xFF1E293B),
    red: Color(0xFFF87171),
    redSoft: Color(0x2EDC2626),
  );

  BiccoTokens copyWith({
    Color? green,
    Color? greenDark,
    Color? greenSoft,
    Color? purple,
    Color? purpleSoft,
    Color? orange,
    Color? orangeSoft,
    Color? navy,
    Color? text,
    Color? textMuted,
    Color? textFaint,
    Color? bg,
    Color? bgSoft,
    Color? border,
    Color? borderSoft,
    Color? red,
    Color? redSoft,
  }) {
    return BiccoTokens(
      green: green ?? this.green,
      greenDark: greenDark ?? this.greenDark,
      greenSoft: greenSoft ?? this.greenSoft,
      purple: purple ?? this.purple,
      purpleSoft: purpleSoft ?? this.purpleSoft,
      orange: orange ?? this.orange,
      orangeSoft: orangeSoft ?? this.orangeSoft,
      navy: navy ?? this.navy,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      bg: bg ?? this.bg,
      bgSoft: bgSoft ?? this.bgSoft,
      border: border ?? this.border,
      borderSoft: borderSoft ?? this.borderSoft,
      red: red ?? this.red,
      redSoft: redSoft ?? this.redSoft,
    );
  }
}
