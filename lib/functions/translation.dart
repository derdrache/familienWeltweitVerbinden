import 'package:translator/translator.dart';

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
    if(withTranslationNotice) textEng += "\n\n<This is an automatic translation>";
    textGer = text;
  } else {
    var textTranslation = await translator.translate(text,
        from: "auto", to: "de");

    textEng = text;
    textGer = textTranslation.toString();
    if(withTranslationNotice) textGer += "\n\n<Dies ist eine automatische Übersetzung>";
  }

  return{
    "eng": textEng,
    "ger": textGer,
    "language": languageCheck.sourceLanguage.code
  };
}