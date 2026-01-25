import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final VoidCallback? onSuffixTap;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onSuffixTap,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fieldHeight = maxLines == 1
        ? ResponsiveUtils.responsiveValue(context, 48.0, 52.0, 56.0)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
            style: AppTextStyles.bodyMedium(context)!.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary.withOpacity(0.6),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: fieldHeight,
          child: TextFormField(
            readOnly: readOnly,
            onTap: onTap,
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            cursorColor: Colors.blue,
            validator: validator,
            maxLines: maxLines,
            style: AppTextStyles.bodyMedium(context).copyWith(
              fontWeight: FontWeight.w700
            ),
            decoration: InputDecoration(
              filled: true, fillColor: Colors.white, //added by me
              hintText: hint,
              hintStyle: AppTextStyles.bodyMedium(context)!.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w300
                //fontWeight: FontWeight.w700
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(
                prefixIcon,
                size: ResponsiveUtils.responsiveValue(context, 20.0, 22.0, 24.0),
                color: AppColors.textSecondary,
              )
                  : null,
              suffixIcon: suffixIcon != null
                  ? GestureDetector(
                onTap: onSuffixTap,
                child: Icon(
                  suffixIcon,
                  size: ResponsiveUtils.responsiveValue(context, 20.0, 22.0, 24.0),
                  color: AppColors.textSecondary,
                ),
              )
                  : null,
              contentPadding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.responsiveValue(context, 12.0, 16.0, 20.0),
                vertical: maxLines == 1
                    ? ResponsiveUtils.responsiveValue(context, 12.0, 14.0, 16.0)
                    : 16.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}