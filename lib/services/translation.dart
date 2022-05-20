import 'dart:convert';
import 'package:http/http.dart' as http;

import '../auth/secrets.dart';


class TranslationServices{

  getLanguage(text) async {
    text = text.replaceAll(" ", "_");
    text = Uri.encodeComponent(text);

    try {
      var url =
          "https://families-worldwide.com/services/googleDetectLanguage.php";

      var res = await http.post(Uri.parse(url),
          body: json.encode({
            "googleKey": google_key,
            "input": text,
          }));
      dynamic responseBody = res.body;
      var data = jsonDecode(responseBody);

      return data["data"]["detections"][0][0]["language"];
    } catch (error) {
      return ;
    }
  }

  getTextTranslation(text, sourceLanguage, targetLanguage) async {
    text = Uri.encodeComponent(text);

    try {
      var url =
          "https://families-worldwide.com/services/googleTranslation.php";

      var res = await http.post(Uri.parse(url),
          body: json.encode({
            "googleKey": google_key,
            "input": text,
            "targetLanguage": targetLanguage,
            "sourceLanguage": sourceLanguage
          }));
      dynamic responseBody = res.body;
      var data = jsonDecode(responseBody);

      return data["data"]["translations"][0]["translatedText"];
    } catch (error) {
      return "";
    }
  }

}