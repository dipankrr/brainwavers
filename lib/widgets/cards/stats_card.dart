import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 900;
    final accentColor = color ?? AppColors.primary;

    final double verticalSpacing = isLargeScreen ? 12 : 6;
    final double iconSize = isLargeScreen ? 32 : 22;
    final double valueFontSize = isLargeScreen ? 28 : 18;
    final double titleFontSize = isLargeScreen ? 16 : 12;
    final double padding = isLargeScreen ? 20 : 12;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: verticalSpacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// decent
// class StatsCard extends StatelessWidget {
//   final String title;
//   final String value;
//   final IconData icon;
//   final Color? color;
//
//   const StatsCard({
//     super.key,
//     required this.title,
//     required this.value,
//     required this.icon,
//     this.color,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isLargeScreen = screenWidth >= 900;
//
//     final Color accentColor = color ?? AppColors.primary;
//
//     return Container(
//       padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade200),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.03),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: isLargeScreen
//           ? Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           // Title
//           Expanded(
//             flex: 2,
//             child: Text(
//               title,
//               style: TextStyle(
//                 color: AppColors.textSecondary,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 16,
//               ),
//             ),
//           ),
//           // Value
//           Expanded(
//             flex: 2,
//             child: FittedBox(
//               fit: BoxFit.scaleDown,
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 value,
//                 style: TextStyle(
//                   color: AppColors.textPrimary,
//                   fontWeight: FontWeight.w700,
//                   fontSize: 24,
//                 ),
//               ),
//             ),
//           ),
//           // Icon
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: accentColor.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(
//               icon,
//               size: 28,
//               color: accentColor,
//             ),
//           ),
//         ],
//       )
//           : Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               color: AppColors.textSecondary,
//               fontWeight: FontWeight.w600,
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Expanded(
//                 child: FittedBox(
//                   fit: BoxFit.scaleDown,
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     value,
//                     style: TextStyle(
//                       color: AppColors.textPrimary,
//                       fontWeight: FontWeight.w700,
//                       fontSize: 20,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: accentColor.withOpacity(0.08),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(
//                   icon,
//                   size: 22,
//                   color: accentColor,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }


// not bad but too such space
// class StatsCard extends StatelessWidget {
//   final String title;
//   final String value;
//   final IconData icon;
//   final Color? color;
//
//   const StatsCard({
//     super.key,
//     required this.title,
//     required this.value,
//     required this.icon,
//     this.color,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isLargeScreen = MediaQuery.of(context).size.width > 900;
//     final bool isMediumScreen = MediaQuery.of(context).size.width > 600;
//
//     final double padding = isLargeScreen
//         ? 16.0
//         : isMediumScreen
//         ? 14.0
//         : 12.0;
//
//     final double iconSize = isLargeScreen
//         ? 28.0
//         : isMediumScreen
//         ? 24.0
//         : 22.0;
//
//     final Color accentColor = color ?? AppColors.primary;
//
//     return Center(
//       child: ConstrainedBox(
//         constraints: const BoxConstraints(maxWidth: 320),
//         child: Container(
//           width: double.infinity,
//           padding: EdgeInsets.all(padding),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey.shade200),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.03),
//                 blurRadius: 4,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Title
//               Text(
//                 title,
//                 style: AppTextStyles.bodyMedium(context)!.copyWith(
//                   color: AppColors.textSecondary,
//                   fontWeight: FontWeight.w600,
//                 ),
//                 overflow: TextOverflow.ellipsis,
//               ),
//
//               const SizedBox(height: 10),
//
//               // Value + Icon
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   // Value (auto scales)
//                   Expanded(
//                     child: FittedBox(
//                       fit: BoxFit.scaleDown,
//                       alignment: Alignment.centerLeft,
//                       child: Text(
//                         value,
//                         style: AppTextStyles.headlineMedium(context)!.copyWith(
//                           color: AppColors.textPrimary,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//
//                   // Icon box
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: accentColor.withOpacity(0.08),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Icon(
//                       icon,
//                       size: iconSize,
//                       color: accentColor,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// ds one
// class StatsCard extends StatelessWidget {
//   final String title;
//   final String value;
//   final IconData icon;
//   final Color? color;
//
//   const StatsCard({
//     super.key,
//     required this.title,
//     required this.value,
//     required this.icon,
//     this.color,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: EdgeInsets.all(
//           ResponsiveUtils.responsiveValue(context, 12.0, 16.0, 20.0),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Icon(
//                   icon,
//                   size: ResponsiveUtils.responsiveValue(context, 24.0, 28.0, 32.0),
//                   color: color ?? AppColors.primary,
//                 ),
//                 Text(
//                   value,
//                   style: AppTextStyles.headlineMedium(context)!.copyWith(
//                     color: AppColors.textPrimary,
//                   ),
//                 ),
//                 // Optional: Add trend indicator later
//               ],
//             ),
//             const SizedBox(height: 8),
//
//             const SizedBox(height: 4),
//             Text(
//               title,
//               style: AppTextStyles.bodyMedium(context)!.copyWith(
//                 color: AppColors.textSecondary,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }