import 'package:flutter/material.dart';
import '../global/style.dart' as style;

Future<void> CustomPopupMenu(BuildContext context, {required List<SimpleDialogOption> children}) {
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 205,
              child: SimpleDialog(
                contentPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(style.roundedCorners),
                ),
                insetPadding:
                const EdgeInsets.only(top: 10, left: 0, right: 10),
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
