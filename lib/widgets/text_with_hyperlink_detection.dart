import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../global/global_functions.dart' as global_func;

class TextWithHyperlinkDetection extends StatelessWidget {
  String text;
  double fontsize;
  var hasLink = false;
  List<InlineSpan> textSpanList = [];
  Function? onTextTab;
  var hyperlinkColor = Colors.blue[700];
  Color textColor;
  bool withoutActiveHyperLink;
  int? maxLines;

  TextWithHyperlinkDetection(
      {Key? key, required this.text, this.fontsize = 15, this.textColor = Colors.black,  this.onTextTab, this.withoutActiveHyperLink = false, this.maxLines})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<TextSpan> newTextList = [];
    var beschreibungsList = text.split(" ");
    var hasLink = false;

    addNormalText(text){
      newTextList.add(TextSpan(
          text: text,
          recognizer: TapGestureRecognizer()..onTap = onTextTab == null ? null :() => onTextTab!(),
          style: TextStyle(fontSize: fontsize, color: textColor)
      ));
    }

    addHyperlinkText(text){


      newTextList.add(TextSpan(
          text: text + " ",
          recognizer: TapGestureRecognizer()..onTap = withoutActiveHyperLink
              ? () => onTextTab!()
              : () => global_func.openURL(text.trim()),
          style: TextStyle(fontSize: fontsize, color: Colors.blue,)
      ));
    }

    for (var word in beschreibungsList) {
      if(global_func.isLink(word) || word.contains("http") || global_func.isPhoneNumber(word)){
        hasLink = true;
        var wordArray = word.split("\n");

        if(wordArray.length == 1){
          addHyperlinkText(word +" ");
        }else{
          for(var line in wordArray){
            if(global_func.isLink(line) || line.contains("http")|| global_func.isPhoneNumber(line)){
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

    return SelectableText.rich(TextSpan(children: newTextList), maxLines: maxLines);

  }


}
