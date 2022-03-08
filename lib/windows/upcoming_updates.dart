import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../global/custom_widgets.dart';

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

    return CustomWindow(
        context: context,
        title: patchnotesTitle,
        children: [
          _update(AppLocalizations.of(context).familienAnzeige),
          _update(AppLocalizations.of(context).automatischerStandort),
          _update(AppLocalizations.of(context).nutzerBlockieren),
          _update(AppLocalizations.of(context).eventsPlanen),
          _update(AppLocalizations.of(context).reisePlanung),
          _update(AppLocalizations.of(context).gemeinschaftenUpdate),
          _update(AppLocalizations.of(context).freundeMarkieren),
          _update(AppLocalizations.of(context).chatgruppen),
          _update(AppLocalizations.of(context).eventboard),
          _update(AppLocalizations.of(context).anonymeAnmelden),
          _update(AppLocalizations.of(context).chatErweiterung),
          _update(AppLocalizations.of(context).accountLoeschen),
          _update(AppLocalizations.of(context).layoutVerbessern),
        ]
    );
  }

}