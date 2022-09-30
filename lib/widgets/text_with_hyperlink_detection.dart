import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

bool _isLink(String input) {
  final matcher = RegExp(
      r"(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)");

  if(matcher.hasMatch(input)){
    try{
      if(Uri.parse(input).isAbsolute) return true;
    }catch(_){
      return false;
    }
  }

  return false;
}

class TextWithHyperlinkDetection extends StatelessWidget {
  String text;
  double fontsize;
  var hasLink = false;
  List<InlineSpan> textSpanList = [];
  Function onTextTab;

  TextWithHyperlinkDetection(
      {Key key, this.text, this.fontsize = 15, this.onTextTab})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var beschreibungsList = text.split(" ");
    var hasLink = false;
    var newText = "";

    for (var word in beschreibungsList) {
      if (_isLink(word) || word.contains("http")) {
        hasLink = true;
        var wordArray = word.split("\n");

        if (wordArray.length == 1) {
          textSpanList.add(WidgetSpan(
              child: GestureDetector(
                  onTap: () => launch(word),
                  child: Text(word,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: fontsize)))));
        } else {
          for (var line in wordArray) {
            if (line.isEmpty) continue;

            if (!line.contains("http")) {
              newText += wordArray[0];
              break;
            }
          }

          textSpanList.add(WidgetSpan(
              child: GestureDetector(
                onTap: onTextTab == null ? null :() => onTextTab(),
                child: Text(newText,
                    style: TextStyle(color: Colors.black, fontSize: fontsize)),
              )));

          var hyperLinkIndex = wordArray.indexWhere(
              (checkWord) => _isLink(checkWord) || checkWord.contains("http"));
          var hyperLinkLine = wordArray[hyperLinkIndex];

          textSpanList.add(WidgetSpan(
              child: GestureDetector(
                  onTap: () => launch(hyperLinkLine),
                  child: Row(
                    children: [
                      Text(hyperLinkLine,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: fontsize)),
                    ],
                  ))));

          var lastWord = wordArray
              .sublist(
                  hyperLinkIndex + 1,
                  hyperLinkIndex + 1 == wordArray.length
                      ? null
                      : wordArray.length)
              .join();

          textSpanList.add(WidgetSpan(
              child: GestureDetector(
                onTap: onTextTab == null ? null :() => onTextTab(),
                child: Text(lastWord + " ",
                    style: TextStyle(color: Colors.black, fontSize: fontsize)),
              )));

          newText = "";
          hasLink = true;
        }
      } else {
        newText += word + " ";
      }
    }

    if (!hasLink) {
      return GestureDetector(
        onTap: onTextTab == null ? null :() => onTextTab(),
          child: Text(text,
              style: TextStyle(color: Colors.black, fontSize: fontsize)));
    }

    if (newText.isNotEmpty) {
      textSpanList.add(WidgetSpan(
          child: GestureDetector(onTap: onTextTab == null ? null :() => onTextTab(), child: Text(newText)),
          style: TextStyle(color: Colors.black, fontSize: fontsize)));
    }

    return RichText(text: TextSpan(children: textSpanList));
  }
}
