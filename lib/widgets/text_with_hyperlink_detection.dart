import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';


bool _isLink(String input) {
  final matcher = RegExp(
      r"(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)");
  return matcher.hasMatch(input);
}

class TextWithHyperlinkDetection extends StatelessWidget {
  String text;
  double fontsize;
  var hasLink = false;
  List<InlineSpan> textSpanList = [];

  TextWithHyperlinkDetection({Key key, this.text, this.fontsize = 14}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    var beschreibungsList = text.split(" ");

    for(var word in beschreibungsList){
      if(_isLink(word)){
        if(!word.contains("http")) word = "http://" + word;

        textSpanList.add(TextSpan(
            text: word + " ", style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: fontsize),
            recognizer: TapGestureRecognizer()..onTap = () => launch(word)
        ));

        hasLink = true;
      }else{
        textSpanList.add(TextSpan(text: word + " ", style: TextStyle(color: Colors.black, fontSize: fontsize)));
      }
    }

    if(!hasLink) return Text(text);

    return RichText(text: TextSpan(children: textSpanList));
  }
}


