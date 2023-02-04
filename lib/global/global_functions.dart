import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:familien_suche/global/variablen.dart';
import 'package:url_launcher/url_launcher.dart';


checkValidatorEmpty(context) {
  return (value){
    if(value == null || value.isEmpty){
      return AppLocalizations.of(context).diesesFeldAusfuellen;
    }
    return null;
  };
}

checkValidationEmail(context, {emailCheck = ""}){
  return (value){

    bool emailHasAT = value.contains("@");
    bool emailHasEnd = false;
    if(emailHasAT) emailHasEnd = value.split("@")[1].contains(".");

    if(value == null || value.isEmpty){
      return AppLocalizations.of(context).emailEingeben;
    } else if(!emailHasAT || !emailHasEnd){
      return AppLocalizations.of(context).gueltigeEmailEingeben;
    } else if(emailCheck!= "" && value != emailCheck){
      return AppLocalizations.of(context).emailStimmtNichtUeberein;
    }
  };
}

checkValidatorPassword(context, {passwordCheck = ""}){
 return (value){
   if(value == null || value.isEmpty){
     return AppLocalizations.of(context).passwortEingeben;
   } else if(passwordCheck!= "" && value != passwordCheck){
     return AppLocalizations.of(context).passwortStimmtNichtUeberein;
   }
   return null;
 };
}

checkValidationMultiTextForm(context){
  return (value){
    if(value == null || value.isEmpty){
      return AppLocalizations.of(context).ausfuellen;
    }
    return null;
  };
}

changePage(context, page, {whenComplete}){
  Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page)
  ).whenComplete(whenComplete ?? (){});
}

changePageForever(context, page){
  Navigator.pushReplacement(
      context,
      MaterialPageRoute(maintainState:false,builder: (context) => page)
  );
}


class ChangeTimeStamp{
  var timeStamp;

  ChangeTimeStamp(this.timeStamp);



  intoDate(){
    DateTime dateTime = DateTime.parse(timeStamp.split(" ")[0]);
    return dateTime;
  }

  intoString(){
    var dateTimeString = timeStamp.split(" ")[0].toString();
    return dateTimeString.split("-").reversed.join("-");
  }

  intoYears(){
    DateTime dateTime = DateTime.parse(timeStamp.split(" ")[0]);
    return DateTime.now().difference(dateTime).inDays ~/ 365;
  }


}


getChatID(chatPartnerId){
  var userId = FirebaseAuth.instance.currentUser.uid;
  var users = [userId, chatPartnerId];
  var sortedList = users.toList(growable: false)..sort();
  return sortedList.join("_");
}

changeGermanToEnglish(list){
  List<String> englishOutputList = [];
  var checkList = [];
  var englishList = [];

  if(interessenListe.contains(list[0])) {
    checkList = interessenListe;
    englishList = interessenListeEnglisch;
  }
  if(sprachenListe.contains(list[0])){
    checkList = sprachenListe;
    englishList = sprachenListeEnglisch;
  }
  if(list.runtimeType == String && checkList.isEmpty){
    var reiseartenIndex = reisearten.indexOf(list);
    var eventIntervalIndex = meetupInterval.indexOf(list);
    var eventArtIndex = eventArt.indexOf(list);
    var aufreiseIndex = aufreise.indexOf(list);
    var standortBestimmungIndex = standortbestimmung.indexOf(list);
    var reiseplanungPrivacyIndex = privacySetting.indexOf(list);
    var interesseIndex = interessenListe.indexOf(list);

    if(reiseartenIndex > -1) return reiseartenEnglisch[reiseartenIndex];
    if(eventIntervalIndex > -1) return meetupIntervalEnglisch[eventIntervalIndex];
    if(eventArtIndex > -1) return eventArtEnglisch[eventArtIndex];
    if(aufreiseIndex > -1) return aufreiseEnglisch[aufreiseIndex];
    if(standortBestimmungIndex > -1) return standortbestimmungEnglisch[standortBestimmungIndex];
    if(reiseplanungPrivacyIndex > -1) return privacySettingEnglisch[reiseplanungPrivacyIndex];
    if(interesseIndex > -1) return interessenListeEnglisch[interesseIndex];


    return list;
  }
  if(checkList.isEmpty) return list;

  for(var i = 0; i < list.length; i++){
    var index = checkList.indexOf(list[i]);
    englishOutputList.add(englishList[index]);
  }

  return englishOutputList;
}

changeEnglishToGerman(list){
  List<String> germanOutputList = [];
  var checkList = [];
  var germanList = [];


  if(interessenListeEnglisch.contains(list[0])) {
    checkList = interessenListeEnglisch;
    germanList = interessenListe;
  }
  if(sprachenListeEnglisch.contains(list[0])){
    checkList = sprachenListeEnglisch;
    germanList = sprachenListe;
  }

  if(list.runtimeType == String && checkList.isEmpty){
    var reiseartenIndex = reiseartenEnglisch.indexOf(list);
    var eventIntervalIndex = meetupIntervalEnglisch.indexOf(list);
    var eventArtIndex = eventArtEnglisch.indexOf(list);
    var aufreiseIndex = aufreiseEnglisch.indexOf(list);
    var standortBestimmungIndex = standortbestimmungEnglisch.indexOf(list);
    var reiseplanungPrivacyIndex = privacySettingEnglisch.indexOf(list);
    var interessenIndex = interessenListeEnglisch.indexOf(list);

    if(reiseartenIndex > -1) return reisearten[reiseartenIndex];
    if(eventIntervalIndex > -1) return meetupInterval[eventIntervalIndex];
    if(eventArtIndex > -1) return eventArt[eventArtIndex];
    if(aufreiseIndex > -1) return aufreise[aufreiseIndex];
    if(standortBestimmungIndex > -1) return standortbestimmung[standortBestimmungIndex];
    if(reiseplanungPrivacyIndex > -1) return privacySetting[reiseplanungPrivacyIndex];
    if(interessenIndex > -1) return interessenListe[interessenIndex];

    return list;
  }
  if(checkList.isEmpty) return list;

  for(var i = 0; i < list.length; i++){
    var index = checkList.indexOf(list[i]);

    if(germanList[index] == null) continue;

    germanOutputList.add(germanList[index]);
  }

  return germanOutputList;
}

openURL(url) async{
  if(url.contains("http")){
    url = Uri.parse(url);
  }else if(isPhoneNumber(url)){
    var tel = Uri(
      scheme: 'tel',
      path: url,
    );
    launchUrl(tel);
    return;
  }else{
    url = Uri.https(url);
  }

  await launchUrl(
      url,
      mode: LaunchMode.inAppWebView
  );
}

bool isLink(String input) {
  if(input.contains("http") || input.contains("www.")){
    var first4Letters = input.substring(0,4);

    return !(first4Letters == "http" && first4Letters == "www.");
  }

  final matcher = RegExp(
        r"(/([\w+]+\:\/\/)?([\w\d-]+\.)*[\w-]+[\.\:]\w+([\/\?\=\&\#\.]?[\w-]+)*\/?/gm)");

  return matcher.hasMatch(input);
}

bool isPhoneNumber(String input){
  input = input.replaceAll(" ", "");
  final matcher = RegExp(r'^(?:[+0][1-9])?[0-9]{10,12}$');

  return matcher.hasMatch(input);
}
