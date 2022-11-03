import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../global/global_functions.dart' as global_func;

class TextWithHyperlinkDetection extends StatelessWidget {
  String text;
  double fontsize;
  var hasLink = false;
  List<InlineSpan> textSpanList = [];
  Function onTextTab;
  var hyperlinkColor = Colors.blue[700];
  var textColor = Colors.black;

  TextWithHyperlinkDetection(
      {Key key, this.text, this.fontsize = 15, this.onTextTab})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<TextSpan> newTextList = [];
    var beschreibungsList = text.split(" ");
    var hasLink = false;

    addNormalText(text){
      newTextList.add(TextSpan(
          text: text,
          recognizer: TapGestureRecognizer()..onTap = onTextTab == null ? null :() => onTextTab(),
          style: const TextStyle(
        color: Colors.black,
      )));
    }

    addHyperlinkText(text){
      newTextList.add(TextSpan(
          text: text + " ",
          recognizer: TapGestureRecognizer()..onTap = () => global_func.openURL(text.trim()),
          style: const TextStyle(
        color: Colors.blue,
      )));
    }

    for (var word in beschreibungsList) {
      if(global_func.isLink(word) || word.contains("http")){
        hasLink = true;
        var wordArray = word.split("\n");

        if(wordArray.length == 1){
          addHyperlinkText(word +" ");
        }else{
          for(var line in wordArray){
            if(global_func.isLink(line) || line.contains("http")){
              addHyperlinkText(line);
              addNormalText("\n");
            }else{
              addNormalText(line);
              addNormalText("\n");
            }
          }
          newTextList.removeLast();
          addNormalText(" ");
        }

      }else{
        addNormalText(word +" ");
      }
    }

    if(!hasLink){
      newTextList = [];
      addNormalText(text);
    }

    return RichText(text: TextSpan(children: newTextList));

    /*

    addNormalText(text){
      textSpanList.add(WidgetSpan(
          child: GestureDetector(onTap: onTextTab == null ? null :() => onTextTab(), child: Text(text)),
          style: TextStyle(color: textColor, fontSize: fontsize)));
    }

    addHyperLinkText(text){
      textSpanList.add(WidgetSpan(
          child: GestureDetector(
              onTap: () => global_func.openURL(text),
              child: Text(text,
                  style: TextStyle(
                      color: hyperlinkColor,
                      fontSize: fontsize-2)))));
      addNormalText(" ");
    }

    for (var word in beschreibungsList) {

      if (_isLink(word) || word.contains("http")) {
        hasLink = true;
        var wordArray = word.split("\n");

        if (newText.isNotEmpty) {
          addNormalText(newText);
          newText = "";
        }

        if (wordArray.length == 1) {
          addHyperLinkText(word);
        } else {
          for (var line in wordArray) {
            if (line.isEmpty) continue;

            if (!_isLink(line)) {
              newText += line;
              break;
            }

            if(_isLink(line)) break;
          }

          addNormalText(newText);

          var hyperLinkIndex = wordArray.indexWhere(
              (checkWord) => _isLink(checkWord) || checkWord.contains("http"));
          var hyperLinkLine = wordArray[hyperLinkIndex];

          addHyperLinkText(hyperLinkLine);
/*
          textSpanList.add(WidgetSpan(
              child: GestureDetector(
                  onTap: () => global_func.openURL(hyperLinkLine),
                  child: Row(
                    children: [
                      Text(hyperLinkLine,
                          style: TextStyle(
                              color: hyperlinkColor,
                              fontSize: fontsize -2 )),
                    ],
                  ))));

 */

          var lastWord = wordArray
              .sublist(
                  hyperLinkIndex + 1,
                  hyperLinkIndex + 1 == wordArray.length
                      ? null
                      : wordArray.length)
              .join();

          addNormalText(lastWord + " ");
          newText = "";
        }
      } else {
        newText += word + " ";
      }
    }

    if (!hasLink) {
      return GestureDetector(
        onTap: onTextTab == null ? null :() => onTextTab(),
          child: Text(text,
              style: TextStyle(color: textColor, fontSize: fontsize)));
    }

    if (newText.isNotEmpty) {
      addNormalText(newText);
    }

    return RichText(text: TextSpan(children: textSpanList));

     */
  }


}
