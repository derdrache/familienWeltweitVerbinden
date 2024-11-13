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
      margin: const EdgeInsets.only(right: 10, bottom: 0, top: 20),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        /*
        TextButton(
            child: Text(confirmTitle ?? AppLocalizations.of(context)!.bestaetigen,
                style: TextStyle(fontSize: style.textSize)),
            onPressed: () {
              if(onConfirm != null) onConfirm!();
            }),
        const SizedBox(width: 10,),
        TextButton(
          child: Text(AppLocalizations.of(context)!.abbrechen,
              style: TextStyle(fontSize: style.textSize)),
          onPressed: () => Navigator.pop(context),
        ),
        
         */
        ElevatedButton(
          onPressed: () {
            if(onConfirm != null) onConfirm!();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green
          ),
          child: Text(AppLocalizations.of(context)!.bestaetigen, style: TextStyle(fontSize: style.textSize)),),
        const SizedBox(width: 30,),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red
          ),
          child: Text(AppLocalizations.of(context)!.abbrechen, style: TextStyle(fontSize: style.textSize)),)
      ]),
    );
  }
}
