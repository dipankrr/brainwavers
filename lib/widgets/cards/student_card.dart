import 'package:brainwavers/widgets/common/adaptive_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:brainwavers/core/constants/other_constants.dart';
import '../../models/student_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/responsive_utils.dart';

// String balanceIfWrapped(BuildContext context, String text, double maxWidth, TextStyle style) {
//   // Measure the text width
//   final textPainter = TextPainter(
//     text: TextSpan(text: text, style: style),
//     textDirection: Directionality.of(context), // <-- use context
//     maxLines: 1,
//   )..layout();
//
//
//   // If text fits, return as is
//   if (textPainter.width <= maxWidth) return text;
//
//   // Otherwise, split roughly in half
//   int mid = (text.length / 2).round();
//
//   // Try to split on nearest space to avoid mid-word break
//   int spaceIndex = text.indexOf(' ', mid);
//   if (spaceIndex != -1) mid = spaceIndex;
//
//   return text.substring(0, mid).trim() + "\n" + text.substring(mid).trim();
// }


class StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;
  final VoidCallback? onPressedIDGen;
  final VoidCallback? onPressedSendReq;
  final VoidCallback? onPressedMarksheet;
  final VoidCallback? onPressedCertificate;
  final String? sendReqButtonText;
  final String? studentStatus;
  final bool? needFather;
  final Color? cardColor;

  const StudentCard({
    super.key,
    required this.student,
    required this.onTap,
    this.cardColor,
    this.onPressedIDGen,
    this.onPressedSendReq,
    this.sendReqButtonText,
    this.needFather = true,
    this.studentStatus,
    this.onPressedMarksheet,
    this.onPressedCertificate,
  });

  @override
  Widget build(BuildContext context) {
    double cellPadding =
    ResponsiveUtils.responsiveValue(context, 8.0, 10.0, 12.0);

    String formattedDob =
    student.dob != null ? DateFormat('dd/MM/yyyy').format(student.dob!) : '';

    // Vertical divider
    Widget columnDivider = Container(
      width: 1,
      color: Colors.grey.shade300,
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: cellPadding),
        decoration: BoxDecoration(
          color: cardColor ?? Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
        ),

        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              columnDivider,
              const SizedBox(width: 5,),
              // NAME
              Expanded(
                flex: Int.nameFlex,
                child: Center(
                  child: Text(
                    student.name,
                    style: AppTextStyles.bodySmallCustom(context),
                    maxLines: 2,          // 👈 WRAP TEXT
                    softWrap: true,       // 👈 ALLOW MULTI-LINE
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              columnDivider,

              // ROLL NO
              Expanded(
                flex: Int.rollFlex,
                child: Center(
                  child: Text(
                    student.rollNumber.toString(),
                    style: AppTextStyles.bodySmallCustom(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              columnDivider,

              // ADMISSION CODE
              Expanded(
                flex: Int.admissionCodeFlex,
                child: Center(
                  child: Text(
                    student.admissionCode ?? '',
                    style: AppTextStyles.bodySmallCustom(context),
                    maxLines: 2,
                    softWrap: true,
                  ),
                ),
              ),

              columnDivider,

              // DOB
              Expanded(
                flex: Int.dobFlex,
                child: Center(
                  child: Text(
                    formattedDob,
                    style: AppTextStyles.bodySmallCustom(context),
                    maxLines: 1,
                  ),
                ),
              ),

              columnDivider,

              // todo:
              // FATHER NAME
              if(needFather == true)
              Expanded(
                flex: Int.fatherFlex,
                child: Center(
                  child: Text(
                    student.fatherName ?? '',
                    style: AppTextStyles.bodySmallCustom(context),
                    maxLines: 2,
                    softWrap: true,
                  ),
                ),
              ),

              columnDivider,

              //id card
              if (onPressedIDGen != null)
                Expanded(
                  flex: Int.rollFlex,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.print, color: Colors.blue,),
                      onPressed: onPressedIDGen,
                    ),

                  ),
                ),

              columnDivider,
              //id card
              if (onPressedSendReq != null)
                Expanded(
                  flex: Int.dobFlex,
                  child: Center(
                    child: Row(
                      children: [
                        if (studentStatus == "approved") ...[
                          AdaptiveButton(
                            onPressed: onPressedMarksheet,
                            text: "Marksheet",
                          ),
                          const SizedBox(width: 5,),
                          AdaptiveButton(
                            onPressed: onPressedCertificate,
                            text: "Certificate",
                          ),
                        ],
                        if (studentStatus == "sent")
                          AdaptiveButton(
                            onPressed: onPressedSendReq,
                            text: sendReqButtonText ?? "pending",
                          ),
                        if (studentStatus == "notsent")
                        AdaptiveButton(
                          onPressed: onPressedSendReq,
                          text: "Send Req",
                        ),
                      ],
                    ),

                  ),
                ),

              columnDivider,


            ],
          ),
        ),
      ),
    );
  }
}


// by deepseek
// class StudentCard extends StatelessWidget {
//   final Student student;
//   final VoidCallback onTap;
//
//   const StudentCard({
//     super.key,
//     required this.student,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 2,
//       margin: EdgeInsets.only(
//         bottom: ResponsiveUtils.responsiveValue(context, 8.0, 12.0, 16.0),
//       ),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(8),
//         child: Padding(
//           padding: EdgeInsets.all(
//             ResponsiveUtils.responsiveValue(context, 12.0, 16.0, 20.0),
//           ),
//           child: Row(
//             children: [
//               // Avatar
//               Container(
//                 width: ResponsiveUtils.responsiveValue(context, 48.0, 56.0, 64.0),
//                 height: ResponsiveUtils.responsiveValue(context, 48.0, 56.0, 64.0),
//                 decoration: BoxDecoration(
//                   color: AppColors.primary.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   Icons.person,
//                   size: ResponsiveUtils.responsiveValue(context, 24.0, 28.0, 32.0),
//                   color: AppColors.primary,
//                 ),
//               ),
//               const SizedBox(width: 16),
//
//               // Student Info
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       student.name,
//                       style: AppTextStyles.titleLarge(context)!.copyWith(
//                         fontWeight: FontWeight.w600,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Roll No: ${student.rollNumber}',
//                       style: AppTextStyles.bodyMedium(context)!.copyWith(
//                         color: AppColors.textSecondary,
//                       ),
//                     ),
//                     if (student.fatherName != null && student.fatherName!.isNotEmpty) ...[
//                       const SizedBox(height: 2),
//                       Text(
//                         'Father: ${student.fatherName!}',
//                         style: AppTextStyles.bodyMedium(context)!.copyWith(
//                           color: AppColors.textSecondary,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                     if (student.phoneNumber != null && student.phoneNumber!.isNotEmpty) ...[
//                       const SizedBox(height: 2),
//                       Text(
//                         'Phone: ${student.phoneNumber!}',
//                         style: AppTextStyles.bodyMedium(context)!.copyWith(
//                           color: AppColors.textSecondary,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//
//               // Actions
//               Icon(
//                 Icons.arrow_forward_ios,
//                 size: ResponsiveUtils.responsiveValue(context, 16.0, 18.0, 20.0),
//                 color: AppColors.textSecondary,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }