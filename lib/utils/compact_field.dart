import 'package:flutter/material.dart';

Widget _compactField(BuildContext context, Widget child) {
  final w = MediaQuery.of(context).size.width;
  return SizedBox(
    width: w < 480 ? w : 180,
    child: child,
  );
}
