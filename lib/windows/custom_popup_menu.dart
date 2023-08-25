import 'package:flutter/material.dart';
import '../global/style.dart' as style;

CustomPopupMenu(BuildContext context, {
    required List children,
    double width = 205.0,
    double topDistance = 40.0
}) {
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: width,
              child: SimpleDialog(
                contentPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(style.roundedCorners),
                ),
                insetPadding: EdgeInsets.only(top: topDistance, left: 0, right: 10),
                children: [
                  const SizedBox(height: 10),
                  ...children,
                  const SizedBox(height: 10)
                ],
              ),
            ),
          ],
        );
      });
}
