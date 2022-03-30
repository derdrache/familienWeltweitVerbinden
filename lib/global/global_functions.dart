import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


checkValidatorEmpty(context) {
  return (value){
    if(value == null || value.isEmpty){
      return AppLocalizations.of(context).diesesFeldAusfuellen;
    }
    return null;
  };
}

checkValidationEmail(context){
  return (value){

    bool emailHasAT = value.contains("@");
    bool emailHasEnd = false;
    if(emailHasAT) emailHasEnd = value.split("@")[1].contains(".");

    if(value == null || value.isEmpty){
      return AppLocalizations.of(context).emailEingeben;
    } else if(!emailHasAT || !emailHasEnd){
      return AppLocalizations.of(context).gueltigeEmailEingeben;
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

changePage(context, page){
  Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page)
  );
}

changePageForever(context, page){
  Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page)
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

getChatID(usersList){
  var sortedList = usersList.toList(growable: false)..sort();
  return sortedList.join("_");
}

