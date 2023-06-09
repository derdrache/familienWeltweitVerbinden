import 'package:flutter/material.dart';

class BadgeIcon extends StatelessWidget {
  var icon;
  var text;
  var color;
  double? size;

  BadgeIcon({Key? key, this.icon, this.text, this.color, this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon,
          size: size,
          color: color
        ),
        if(text.length > 0) Positioned(
          top: -10,
          right: -10,
          child: Container(
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle
              ),
              child: Center(
                child: FittedBox(
                  child: Text(
                    text,
                    style: const TextStyle(fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              )
          ),
        )
      ],
    );
  }
}
