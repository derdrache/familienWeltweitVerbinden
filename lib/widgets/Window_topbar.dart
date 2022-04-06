import 'package:flutter/material.dart';

class WindowTopbar extends StatelessWidget {
  var title;

  WindowTopbar({Key key,this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold

                  ),
                )
            ),
          )
        ],
      ),
    );
  }
}