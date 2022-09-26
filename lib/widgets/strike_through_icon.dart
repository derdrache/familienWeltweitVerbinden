import 'package:flutter/material.dart';
import 'dart:math' as math;

class StrikeThroughIcon extends StatelessWidget {
  Icon child;

  StrikeThroughIcon({Key key, @required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 10,
          child: Transform.rotate(
            angle:  -math.pi / 4,
            child: Container(
                width: 25,
                height: 3,
                color: Colors.red
            ),
          ),
        )
      ],
    );
  }
}