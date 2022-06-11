import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/dialogWindow.dart';

class UmcomingUpdatesWindow{
  var context;

  UmcomingUpdatesWindow({this.context});


  _update(title){

    return Container(
      width: 200,
      margin: EdgeInsets.only(left: 10, top: 10),
      child: Text(
        "- " + title,
        style: TextStyle(fontSize: 15),
        maxLines: null,
      )
    );
  }

  openWindow(){
    var patchnotesTitle = AppLocalizations.of(context).geplanteErweiterungen;

    showDialog(
        context: context,
        builder: (BuildContext buildContext){
          return CustomAlertDialog(
              title: patchnotesTitle,
              children: [
                _update(AppLocalizations.of(context).familienAnzeige),
                _update(AppLocalizations.of(context).newsBoard),
                _update(AppLocalizations.of(context).weitereAnemdlungsMoeglichkeiten),
                _update(AppLocalizations.of(context).eventErweiterung),
                _update(AppLocalizations.of(context).eventsOrganisationstools),
                _update(AppLocalizations.of(context).chatErweiterung),
                _update(AppLocalizations.of(context).chatgruppen),
                _update(AppLocalizations.of(context).gemeinschaftenUpdate),
                _update(AppLocalizations.of(context).layoutVerbessern),
              ]
          );
        });
  }

}