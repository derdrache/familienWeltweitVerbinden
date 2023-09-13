import 'dart:math' as math;

import 'package:flutter/material.dart';


class StrikeThroughIcon extends StatelessWidget {
  final Icon child;

  const StrikeThroughIcon({Key? key, required this.child}) : super(key: key);

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