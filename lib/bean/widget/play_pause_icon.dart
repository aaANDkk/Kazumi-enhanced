import 'package:flutter/material.dart';
import 'package:kazumi/bean/widget/app_icon.dart';

class PlayPauseIcon extends StatelessWidget {
  final bool playing;
  final double iconSize;
  final Color? iconColor;

  const PlayPauseIcon({
    super.key,
    required this.playing,
    this.iconSize = 25,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: AppIcon(
        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
        key: ValueKey<bool>(playing),
        color: iconColor,
        size: iconSize,
      ),
    );
  }
}
