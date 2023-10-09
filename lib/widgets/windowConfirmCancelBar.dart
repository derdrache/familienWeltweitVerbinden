import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../global/style.dart'as style;


class WindowConfirmCancelBar extends StatelessWidget {
  final String? confirmTitle;
  final Function()? onConfirm;
  final bool withCloseWindow;

  const WindowConfirmCancelBar({super.key, this.onConfirm, this.confirmTitle, this.withCloseWindow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10, bottom: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton(
            child: Text(confirmTitle ?? AppLocalizations.of(context)!.bestaetigen,
                style: TextStyle(fontSize: style.textSize)),
            onPressed: () {
              if(withCloseWindow) Navigator.pop(context);
              if(onConfirm != null) onConfirm!();
            }),
        const SizedBox(width: 10,),
        TextButton(
          child: Text(AppLocalizations.of(context)!.abbrechen,
              style: TextStyle(fontSize: style.textSize)),
          onPressed: () => Navigator.pop(context),
        ),
      ]),
    );
  }
}
