import 'package:flutter/material.dart';

class LoadingButton extends StatelessWidget {
  final Color color;

  const LoadingButton({Key? key, this.color = Colors.white}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.all(10),
        child: CircularProgressIndicator(
          color: color,
        ));
  }
}
