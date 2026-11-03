import 'package:flutter/material.dart';

/// Defers expensive content until a route has really entered. Hero measurement
/// temporarily reports a completed route animation while the route is offstage.
class RouteEntrance extends StatefulWidget {
  const RouteEntrance({
    super.key,
    required this.onEntered,
    required this.builder,
  });

  final VoidCallback onEntered;
  final Widget Function(BuildContext context, bool hasEntered) builder;

  @override
  State<RouteEntrance> createState() => _RouteEntranceState();
}

class _RouteEntranceState extends State<RouteEntrance> {
  ModalRoute<dynamic>? _route;
  Animation<double>? _animation;
  bool _hasEntered = false;
  bool _scheduled = false;

  bool get _moving =>
      (_route?.offstage ?? false) ||
      (_animation != null && !_animation!.isCompleted);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    final animation = _route?.animation;
    if (!identical(animation, _animation)) {
      _animation?.removeStatusListener(_onStatus);
      _animation = animation;
      animation?.addStatusListener(_onStatus);
    }
    _scheduleEntered();
  }

  void _onStatus(AnimationStatus status) {
    setState(() {});
    _scheduleEntered();
  }

  void _scheduleEntered() {
    if (_hasEntered || _scheduled || _moving) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted || _hasEntered || _moving) return;
      setState(() => _hasEntered = true);
      widget.onEntered();
    });
  }

  @override
  void dispose() {
    _animation?.removeStatusListener(_onStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TickerMode(
    enabled: !_moving,
    child: Builder(builder: (context) => widget.builder(context, _hasEntered)),
  );
}
