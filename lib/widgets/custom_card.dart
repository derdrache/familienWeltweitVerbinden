import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final double sizeRefactor;
  final Widget? likeButton;
  final Widget child;
  final double? height;
  final double? width;
  final EdgeInsets? margin;
  final Function()? onTap;
  final Function(LongPressStartDetails)? onLongPressStart;

  const CustomCard({
    super.key,
    this.sizeRefactor = 1,
    this.likeButton,
    this.height,
    this.width,
    this.margin,
    this.onTap,
    this.onLongPressStart,
    required this.child
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: onLongPressStart,
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.all(0),
        child: Card(
            elevation: 16,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            child: Stack(
              children: [
                Container(
                  width: width ?? 160 * sizeRefactor,
                  height: height ?? 225 * sizeRefactor,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withOpacity(.5),
                            blurRadius: 20.0,
                            spreadRadius: 0.0,
                            offset: const Offset(
                              5.0,
                              5.0,
                            )),
                        const BoxShadow(color: Colors.white,)
                      ]
                  ),
                  child: child,
                ),
                if(likeButton != null) Positioned(top: 8, right: 8, child: likeButton!)
              ],
            )),
      ),
    );
  }
}
