import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../global/style.dart' as Style;

class ColorfulBackground extends StatelessWidget {
  ColorfulBackground({
    Key? key,
    this.width = double.infinity,
    this.height = double.infinity,
    this.child,
    this.colors = const [Colors.orange, Colors.orangeAccent]
  });

  Widget? child;
  double width;
  double height;
  List colors;


  @override
  Widget build(BuildContext context) {

    List<Widget> decoratorsList(){
      return [
        Positioned(
          bottom: 0,
          right: 0,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              height: height / 3 * 2,
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Style.roundedCorners),
                color: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
        ) ,
        Positioned(
          top: 0,
          right: -70,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              height: height / 3,
              width: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Style.roundedCorners),
                color: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
        ) ,
        Positioned(
          top: 0,
          left: -100,
          child: Transform.rotate(
            angle: -math.pi / 4,
            child: Container(
              height: height / 3 * 2,
              width: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Style.roundedCorners),
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: -140,
          child: Transform.rotate(
            angle: -math.pi / 4,
            child: Container(
              height: height / 3 * 2,
              width: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Style.roundedCorners),
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),
        ) ,
      ];
    }
    
    return SizedBox(
      height: height,
      width: width,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.orange, Colors.orangeAccent]
              )
            ),
          ),
          for(var decoration in decoratorsList()) decoration,
          Positioned.fill(child: child ?? const SizedBox())
        ],
      ),
    );
  }
}

