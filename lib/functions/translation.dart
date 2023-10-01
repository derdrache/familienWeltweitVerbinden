import 'package:translator/translator.dart';

import '../global/variablen.dart';

translation(text, {withTranslationNotice = false}) async{
  final translator = GoogleTranslator();
  var languageCheck = await translator.translate(text);
  bool isGerman = languageCheck.sourceLanguage.code == "de";
  String textEng;
  String textGer;

  if (isGerman) {
    var textTranslation = await translator.translate(text,
        from: "de", to: "auto");

    textEng = textTranslation.toString();
    if(withTranslationNotice) textEng += automaticTranslationEng;
    textGer = text;
  } else {
    var textTranslation = await translator.translate(text,
        from: "auto", to: "de");

    textEng = text;
    textGer = textTranslation.toString();
    if(withTranslationNotice) textGer += automaticTranslationGer;
  }

  return{
    "eng": textEng,
    "ger": textGer,
    "language": languageCheck.sourceLanguage.code
  };
}