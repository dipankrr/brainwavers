import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';

// class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
//   final String title;
//   final List<Widget>? actions;
//   final bool showBackButton;
//
//   const CustomAppBar({
//     super.key,
//     required this.title,
//     this.actions,
//     this.showBackButton = true,
//   });
//
//   @override
//   Size get preferredSize => Size.fromHeight(
//     ResponsiveUtils.responsiveValue(
//       // We need context for responsiveValue, but we can't use it here
//       // So we'll use fixed heights that work well for most screens
//       56.0, // mobile
//       64.0, // tablet
//       72, // desktop
//     ),
//   );
//
//   @override
//   Widget build(BuildContext context) {
//     final appBarHeight = ResponsiveUtils.responsiveValue(
//       context,
//       56.0, // mobile
//       64.0, // tablet
//       72.0, // desktop
//     );
//
//     return AppBar(
//       backgroundColor: AppColors.primary,
//       foregroundColor: Colors.white,
//       elevation: 0,
//       centerTitle: true,
//       leading: showBackButton
//           ? IconButton(
//         icon: Icon(
//           Icons.arrow_back,
//           size: ResponsiveUtils.responsiveValue(context, 20.0, 22.0, 24.0),
//         ),
//         onPressed: () => Navigator.of(context).pop(),
//       )
//           : null,
//       title: Text(
//         title,
//         style: AppTextStyles.titleLarge(context)!.copyWith(
//           color: Colors.white,
//         ),
//       ),
//       actions: actions,
//     );
//   }
// }
//

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
  });

  // ✅ Use a fixed height (context not available here)
  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    final appBarHeight = ResponsiveUtils.responsiveValue(
      context,
      56.0, // mobile
      64.0, // tablet
      72.0, // desktop
    );

    return PreferredSize(
      preferredSize: Size.fromHeight(appBarHeight),
      child: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: showBackButton
            ? IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: ResponsiveUtils.responsiveValue(context, 20.0, 22.0, 24.0),
          ),
          onPressed: () => Navigator.of(context).pop(),
        )
            : null,
        title: Text(
          title,
          style: AppTextStyles.titleLarge(context)!.copyWith(color: Colors.white),
        ),
        actions: actions,
      ),
    );
  }
}
