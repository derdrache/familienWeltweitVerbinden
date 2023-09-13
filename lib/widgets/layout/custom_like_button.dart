import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';

class CustomLikeButton extends StatelessWidget {
  final bool isLiked;
  final Future<bool?> Function(bool)? onLikeButtonTapped;

  const CustomLikeButton({super.key, required this.isLiked, this.onLikeButtonTapped});

  @override
  Widget build(BuildContext context) {
    return LikeButton(
      isLiked: isLiked,
      likeBuilder: (bool hasIntereset) {
        return Icon(
          Icons.favorite,
          color: hasIntereset ? Colors.red : Colors.black,
          size: 26,
        );
      },
      onTap: onLikeButtonTapped,
    );
  }
}
