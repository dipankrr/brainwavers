import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';

class ResponsiveDropdown<T> extends StatelessWidget {
  final String? label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final String hint;
  final bool showLabel;

  const ResponsiveDropdown({
    super.key,
    this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    required this.hint,
    this.showLabel = true, // NEW
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel && label != null && label!.isNotEmpty) ...[
          Text(
            label!,
            style: AppTextStyles.bodyMedium(context)!.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white, // modern white dropdown background

            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium(context)!.copyWith(
              color: const Color(0xFF6F737B), // modern gray
            ),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), // smoother
              borderSide: const BorderSide(color: Color(0xFFE0E1E5)), // thin soft border
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E4EA)),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF3A83F1), // modern blue highlight
                width: 1.4,
              ),
            ),
          ),
          isExpanded: true,
        ),
      ],
    );
  }
}
