import 'package:translator/translator.dart';

translation(text) async{
  final translator = GoogleTranslator();
  var languageCheck = await translator.translate(text.text);
  bool isGerman = languageCheck.sourceLanguage.code == "de";
  String textEng;
  String textGer;

  if (isGerman) {
    var textTranslation = await translator.translate(text,
        from: "de", to: "auto");

    textEng = textTranslation.toString() + "\n\nThis is an automatic translation";
    textGer = text;
  } else {
    var textTranslation = await translator.translate(text,
        from: "auto", to: "de");

    textEng = text;
    textGer = textTranslation.toString() + "\n\nDies ist eine automatische Übersetzung";
  }




  return{
    "eng": textEng,
    "ger": textGer,
    "language": languageCheck.sourceLanguage.code
  };
}