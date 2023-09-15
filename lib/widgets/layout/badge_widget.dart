import 'package:flutter/material.dart';

import '../../global/style.dart' as style;

class BadgeWidget extends StatelessWidget {
  final Widget child;
  final int number;

  const BadgeWidget({super.key, required this.child, required this.number});

  @override
  Widget build(BuildContext context) {
    double badgeSize = 35;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (number != 0)
          Positioned(
              top: -10,
              right: -10,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(style.roundedCorners)),
                  color: Theme.of(context).colorScheme.secondary,
                ),
                child: Center(
                    child: Text(
                      number.toString(),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    )),
              ))
      ],
    );
  }
}

