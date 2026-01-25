import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';

class AdaptiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool fullWidth;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isOutlined;

  const AdaptiveButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.fullWidth = false,
    this.backgroundColor,
    this.textColor,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = ResponsiveUtils.responsiveValue(
      context,
      48.0, // mobile
      52.0, // tablet
      56.0, // desktop
    );

    final buttonPadding = EdgeInsets.symmetric(
      horizontal: ResponsiveUtils.responsiveValue(context, 16.0, 20.0, 24.0),
      vertical: ResponsiveUtils.responsiveValue(context, 12.0, 14.0, 16.0),
    );

    final textStyle = AppTextStyles.bodyMedium(context)!.copyWith(
      color: textColor ?? (isOutlined ? AppColors.primary : Colors.white),
      fontWeight: FontWeight.w600,
    );

    if (isOutlined) {
      return SizedBox(
        width: fullWidth ? double.infinity : null,
        height: buttonHeight,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            //backgroundColor: ,
            padding: buttonPadding,
            side: BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(text, style: textStyle),
        ),
      );
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          padding: buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(text, style: textStyle),
      ),
    );
  }
}