import 'package:flutter/material.dart';

class OwnIconButton extends StatelessWidget {
  IconData? icon;
  var image;
  var color;
  double size;
  String badgeText;
  bool withBox;
  var margin;
  Function? onPressed;
  bool bigButton;
  String tooltipText;

  OwnIconButton(
      {Key? key,
      this.icon,
      this.image,
      this.badgeText = "",
      this.color,
      this.size = 24,
      this.margin = const EdgeInsets.all(15),
      this.withBox = false, this.onPressed,
      this.bigButton = false,
      this.tooltipText = ""
      })
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if(bigButton) size = 32;

    return InkWell(
      onTap: onPressed != null ? () => onPressed!() : null,
      child: Container(
        margin: margin,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Container(
                padding: withBox ? EdgeInsets.all(5) : null,
                decoration: withBox ? BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.all(Radius.circular(8))
                ): null,
                child: Tooltip(
                  message: tooltipText,
                  child: image != null
                      ? Image.asset(
                          image,
                          width: size,
                          height: size,
                        )
                      : Icon(icon, size: size, color: color),
                ),
              ),
            ),
            if (badgeText.isNotEmpty)
              Positioned(
                top: -10,
                right: image != null ? -10 : 10,
                child: Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle),
                    child: Center(
                      child: FittedBox(
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    )),
              )

          ],
        ),
      ),
    );
  }
}
