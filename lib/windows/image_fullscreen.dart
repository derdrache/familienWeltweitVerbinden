import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../widgets/dialogWindow.dart';


ImageFullscreen(context, image) {
  showDialog(
      context: context,
      builder: (BuildContext buildContext) {
        return CustomAlertDialog(
          windowPadding: const EdgeInsets.all(30),
          children: [CachedNetworkImage(imageUrl: image,)],
        );
      });
}