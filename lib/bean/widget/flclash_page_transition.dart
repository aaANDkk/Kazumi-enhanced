import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';

/// Critically damped spring tuned for secondary page card transitions so that
/// push (375ms) and pop (350ms) balance crisp initial velocity with smooth
/// settling deceleration.
final SpringDescription _pushSpring = SpringDescription.withDurationAndBounce(
  duration: const Duration(milliseconds: 360),
);
const double _pushSpeed = 6.1;
const double _springSeconds = 0.36;

final SpringSimulation _pushSimulation = SpringSimulation(
  _pushSpring,
  0,
  1,
  _pushSpeed,
);
final double _springResidual = 1.0 - _pushSimulation.x(_springSeconds);

double _springTransform(double t) {
  if (t <= 0.0) {
    return 0.0;
  }
  if (t >= 1.0) {
    return 1.0;
  }
  final value = _pushSimulation.x(t * _springSeconds) + _springResidual * t;
  return value.clamp(0.0, 1.0);
}

const double _coveredSlide = 0.3;
const Color _coveredDim = Color.from(alpha: 0.1, red: 0, green: 0, blue: 0);

/// What a 4% black Gaussian of sigma 12 casts past the card's leading edge.
const double _cardShadowSigma = 12.0;
const List<double> _cardShadowStops = [0.0, 1 / 6, 1 / 3, 1 / 2, 2 / 3, 1.0];
final List<Color> _cardShadowColors = [
  for (final share in const [0.5, 0.3085, 0.1587, 0.0668, 0.0228, 0.0])
    Color.from(alpha: 0.04 * share, red: 0, green: 0, blue: 0),
];

BorderRadius _displayRadiusOf(BuildContext context) =>
    MediaQuery.displayCornerRadiiOf(context) ?? BorderRadius.zero;

/// Direction-aware iOS 27 spring animation adapter for standard 300ms
/// [PageRoute] controllers.
///
/// On push ([AnimationStatus.forward]), launches immediately at [_pushSpeed]
/// and decelerates to `1.0`. On pop ([AnimationStatus.reverse]), launches
/// immediately from the current position toward `0.0` at [ _pushSpeed ] rather
/// than playing the forward curve backwards. While a user back gesture is in
/// progress, tracks the finger linearly (`1:1`).
class _SpringPageAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  _SpringPageAnimation({required this.parent, this.navigator});

  @override
  final Animation<double> parent;
  final NavigatorState? navigator;

  AnimationStatus? _lastDirection;
  double _rawStart = 0.0;
  double _transformedStart = 0.0;

  double _computeValue() {
    final raw = parent.value;
    if (raw <= 0.0) {
      _lastDirection = null;
      _rawStart = 0.0;
      _transformedStart = 0.0;
      return 0.0;
    }
    if (raw >= 1.0) {
      _lastDirection = null;
      _rawStart = 1.0;
      _transformedStart = 1.0;
      return 1.0;
    }
    if (navigator?.userGestureInProgress ?? false) {
      _lastDirection = null;
      _rawStart = raw;
      _transformedStart = raw;
      return raw;
    }

    final status = parent.status;
    if (status == AnimationStatus.reverse) {
      if (_lastDirection != AnimationStatus.reverse) {
        if (_lastDirection == AnimationStatus.forward) {
          final span = 1.0 - _rawStart;
          final localT = span > 1e-6 ? (raw - _rawStart) / span : 1.0;
          _transformedStart =
              _transformedStart +
              (1.0 - _transformedStart) * _springTransform(localT);
          _rawStart = raw;
        } else {
          _rawStart = 1.0;
          _transformedStart = 1.0;
        }
        _lastDirection = AnimationStatus.reverse;
      }
      final span = _rawStart;
      if (span <= 1e-6) {
        return 0.0;
      }
      final localT = ((_rawStart - raw) / span).clamp(0.0, 1.0);
      return (_transformedStart * (1.0 - _springTransform(localT))).clamp(
        0.0,
        1.0,
      );
    }

    if (_lastDirection != AnimationStatus.forward) {
      if (_lastDirection == AnimationStatus.reverse) {
        final span = _rawStart;
        final localT = span > 1e-6 ? (_rawStart - raw) / span : 1.0;
        _transformedStart =
            _transformedStart * (1.0 - _springTransform(localT));
        _rawStart = raw;
      } else {
        _rawStart = 0.0;
        _transformedStart = 0.0;
      }
      _lastDirection = AnimationStatus.forward;
    }
    final span = 1.0 - _rawStart;
    if (span <= 1e-6) {
      return 1.0;
    }
    final localT = ((raw - _rawStart) / span).clamp(0.0, 1.0);
    return (_transformedStart +
            (1.0 - _transformedStart) * _springTransform(localT))
        .clamp(0.0, 1.0);
  }

  @override
  double get value => _computeValue();
}

/// FlClash (prism_ui) iOS 27 spring card page transition builder.
class FlClashPageTransitionsBuilder extends PageTransitionsBuilder {
  const FlClashPageTransitionsBuilder();

  static final Animatable<double> _rootFadeTween = CurveTween(
    curve: const Interval(0.0, 70 / 375),
  );

  @override
  Duration get transitionDuration => const Duration(milliseconds: 375);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 350);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final isFirst = route.isFirst;
    final navigator = route.navigator;
    final effectiveSecondary = _SpringPageAnimation(
      parent: secondaryAnimation,
      navigator: navigator,
    );

    if (isFirst) {
      return _CardTransition(
        animation: kAlwaysCompleteAnimation,
        secondaryAnimation: effectiveSecondary,
        radius: _displayRadiusOf(context),
        settledFill: Colors.transparent,
        child: FadeTransition(
          opacity: animation.drive(_rootFadeTween),
          child: _TransitionSnapshot(
            route: route,
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          ),
        ),
      );
    }

    final effectivePrimary = _SpringPageAnimation(
      parent: animation,
      navigator: navigator,
    );

    return _CardTransition(
      animation: effectivePrimary,
      secondaryAnimation: effectiveSecondary,
      radius: _displayRadiusOf(context),
      settledFill: Colors.transparent,
      child: _TransitionSnapshot(
        route: route,
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
      ),
    );
  }
}

/// A retained display list does not freeze image fades, ink effects or child
/// repaints. Move one rasterized page during the transition instead. Start
/// after the first frame so HeroController can install its placeholders first.
class _TransitionSnapshot extends StatefulWidget {
  const _TransitionSnapshot({
    required this.route,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final PageRoute<dynamic> route;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  State<_TransitionSnapshot> createState() => _TransitionSnapshotState();
}

class _TransitionSnapshotState extends State<_TransitionSnapshot> {
  final _controller = SnapshotController();

  void _listen(_TransitionSnapshot widget) {
    widget.animation.addListener(_updateSnapshot);
    widget.secondaryAnimation.addListener(_updateSnapshot);
  }

  void _unlisten(_TransitionSnapshot widget) {
    widget.animation.removeListener(_updateSnapshot);
    widget.secondaryAnimation.removeListener(_updateSnapshot);
  }

  bool _inFlight(Animation<double> animation) =>
      animation.isAnimating && animation.value > 0 && animation.value < 1;

  void _updateSnapshot() {
    _controller.allowSnapshotting =
        !kIsWeb &&
        widget.route.allowSnapshotting &&
        !widget.route.offstage &&
        (_inFlight(widget.animation) || _inFlight(widget.secondaryAnimation));
  }

  @override
  void initState() {
    super.initState();
    _listen(widget);
    _updateSnapshot();
  }

  @override
  void didUpdateWidget(covariant _TransitionSnapshot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation ||
        oldWidget.secondaryAnimation != widget.secondaryAnimation) {
      _unlisten(oldWidget);
      _listen(widget);
    }
    _updateSnapshot();
  }

  @override
  void dispose() {
    _unlisten(widget);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SnapshotWidget(
    controller: _controller,
    mode: SnapshotMode.permissive,
    autoresize: true,
    child: RepaintBoundary(child: widget.child),
  );
}

/// Moves the page by painting alone, so it is neither rebuilt nor laid out
/// again while it moves.
class _CardTransition extends SingleChildRenderObjectWidget {
  const _CardTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.radius,
    required this.settledFill,
    super.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final BorderRadius radius;
  final Color settledFill;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return _RenderCardTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      radius: radius,
      settledFill: settledFill,
      surface: colorScheme.surface,
      backdrop: colorScheme.surfaceContainerLowest,
      shadow: colorScheme.brightness == Brightness.light,
      textDirection: Directionality.of(context),
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderCardTransition renderObject,
  ) {
    final colorScheme = ColorScheme.of(context);
    renderObject
      ..animation = animation
      ..secondaryAnimation = secondaryAnimation
      ..radius = radius
      ..settledFill = settledFill
      ..surface = colorScheme.surface
      ..backdrop = colorScheme.surfaceContainerLowest
      ..shadow = colorScheme.brightness == Brightness.light
      ..textDirection = Directionality.of(context)
      ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
  }
}

class _RenderCardTransition extends RenderProxyBox {
  _RenderCardTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required BorderRadius radius,
    required Color settledFill,
    required Color surface,
    required Color backdrop,
    required bool shadow,
    required TextDirection textDirection,
    required double devicePixelRatio,
  }) : _animation = animation,
       _secondaryAnimation = secondaryAnimation,
       _radius = radius,
       _settledFill = settledFill,
       _surface = surface,
       _backdrop = backdrop,
       _shadow = shadow,
       _textDirection = textDirection,
       _devicePixelRatio = devicePixelRatio;

  Animation<double> _animation;
  set animation(Animation<double> value) {
    if (identical(value, _animation)) {
      return;
    }
    if (attached) {
      _unlisten();
    }
    _animation = value;
    if (attached) {
      _listen();
    }
    markNeedsPaint();
  }

  Animation<double> _secondaryAnimation;
  set secondaryAnimation(Animation<double> value) {
    if (identical(value, _secondaryAnimation)) {
      return;
    }
    if (attached) {
      _unlisten();
    }
    _secondaryAnimation = value;
    if (attached) {
      _listen();
    }
    markNeedsPaint();
  }

  BorderRadius _radius;
  set radius(BorderRadius value) {
    if (value == _radius) {
      return;
    }
    _radius = value;
    markNeedsPaint();
  }

  Color _settledFill;
  set settledFill(Color value) {
    if (value == _settledFill) {
      return;
    }
    _settledFill = value;
    markNeedsPaint();
  }

  Color _surface;
  set surface(Color value) {
    if (value == _surface) {
      return;
    }
    _surface = value;
    markNeedsPaint();
  }

  Color _backdrop;
  set backdrop(Color value) {
    if (value == _backdrop) {
      return;
    }
    _backdrop = value;
    markNeedsPaint();
  }

  bool _shadow;
  set shadow(bool value) {
    if (value == _shadow) {
      return;
    }
    _shadow = value;
    markNeedsPaint();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) {
      return;
    }
    _textDirection = value;
    markNeedsPaint();
  }

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) {
      return;
    }
    _devicePixelRatio = value;
    markNeedsPaint();
  }

  final _clipRSuperellipseLayer = LayerHandle<ClipRSuperellipseLayer>();
  final _clipRectLayer = LayerHandle<ClipRectLayer>();

  bool get _moving =>
      !_animation.isCompleted || !_secondaryAnimation.isDismissed;

  double get _covered => _secondaryAnimation.value;

  double get _dx {
    final width = size.width;
    final slide = _coveredSlide * width * _covered;
    final dx = (1.0 - _animation.value) * width - slide;
    // On whole physical pixels a snapshot is drawn as sharp as the page.
    final snapped =
        (dx * _devicePixelRatio).roundToDouble() / _devicePixelRatio;
    return _textDirection == TextDirection.rtl ? -snapped : snapped;
  }

  Rect get _card => (Offset.zero & size).shift(Offset(_dx, 0));

  Matrix4 _childTransform(Rect card) =>
      Matrix4.translationValues(card.left, card.top, 0);

  void _handleStatus(AnimationStatus _) => markNeedsSemanticsUpdate();

  void _listen() {
    for (final animation in [_animation, _secondaryAnimation]) {
      animation
        ..addListener(markNeedsPaint)
        ..addStatusListener(_handleStatus);
    }
  }

  void _unlisten() {
    for (final animation in [_animation, _secondaryAnimation]) {
      animation
        ..removeListener(markNeedsPaint)
        ..removeStatusListener(_handleStatus);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _listen();
  }

  @override
  void detach() {
    _unlisten();
    super.detach();
  }

  @override
  void dispose() {
    _clipRSuperellipseLayer.layer = null;
    _clipRectLayer.layer = null;
    super.dispose();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) {
      return;
    }
    if (!_moving) {
      _clipRSuperellipseLayer.layer = null;
      _clipRectLayer.layer = null;
      if (_settledFill.a > 0) {
        context.canvas.drawRect(offset & size, Paint()..color = _settledFill);
      }
      context.paintChild(child, offset);
      return;
    }

    final screenBounds = Offset.zero & size;
    void paintAnimatedContent(PaintingContext context, Offset offset) {
      final covered = _covered;
      final card = _card;
      if (covered > 0 && _animation.isCompleted) {
        _paintBesideCard(context.canvas, offset & size, card.shift(offset));
      }
      if (_shadow && !_animation.isCompleted) {
        _paintShadow(context.canvas, card.shift(offset));
      }

      void paintCard(PaintingContext context, Offset offset) {
        context.canvas.drawRect(card.shift(offset), Paint()..color = _surface);
        context.paintChild(child, offset + card.topLeft);
      }

      if (_radius == BorderRadius.zero) {
        _clipRSuperellipseLayer.layer = null;
        paintCard(context, offset);
      } else {
        _clipRSuperellipseLayer.layer = context.pushClipRSuperellipse(
          needsCompositing,
          offset,
          card,
          _radius.toRSuperellipse(card),
          paintCard,
          oldLayer: _clipRSuperellipseLayer.layer,
        );
      }

      if (covered > 0) {
        context.canvas.drawRect(
          offset & size,
          Paint()
            ..color = _coveredDim.withValues(
              alpha: _coveredDim.a * math.min(covered, 1.0),
            ),
        );
      }
    }

    // Clip to the route's viewport bounds while moving so embedded navigators
    // (such as the right-hand pane of SettingsPage on wide screens) never
    // bleed across adjacent panes.
    _clipRectLayer.layer = context.pushClipRect(
      needsCompositing,
      offset,
      screenBounds,
      paintAnimatedContent,
      oldLayer: _clipRectLayer.layer,
    );
  }

  void _paintShadow(Canvas canvas, Rect card) {
    final rtl = _textDirection == TextDirection.rtl;
    final edge = rtl ? card.right : card.left;
    final end = edge + (rtl ? 3 : -3) * _cardShadowSigma;
    final top = card.top + (rtl ? _radius.topRight.y : _radius.topLeft.y);
    final bottom =
        card.bottom - (rtl ? _radius.bottomRight.y : _radius.bottomLeft.y);
    if (bottom <= top) {
      return;
    }
    canvas.drawRect(
      Rect.fromLTRB(math.min(edge, end), top, math.max(edge, end), bottom),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(edge, 0),
          Offset(end, 0),
          _cardShadowColors,
          _cardShadowStops,
        ),
    );
  }

  /// Only the uncovered strip and corners take the backdrop; each piece reaches
  /// a pixel under the card so its antialiased edge stays off the root.
  void _paintBesideCard(Canvas canvas, Rect screen, Rect card) {
    final paint = Paint()..color = _backdrop;
    final radius = _radius;
    for (final rect in [
      Rect.fromLTRB(screen.left, screen.top, card.left + 1, screen.bottom),
      Rect.fromLTRB(card.right - 1, screen.top, screen.right, screen.bottom),
      Rect.fromLTWH(
        card.left,
        card.top,
        radius.topLeft.x + 1,
        radius.topLeft.y + 1,
      ),
      Rect.fromLTRB(
        card.right - radius.topRight.x - 1,
        card.top,
        card.right,
        card.top + radius.topRight.y + 1,
      ),
      Rect.fromLTRB(
        card.left,
        card.bottom - radius.bottomLeft.y - 1,
        card.left + radius.bottomLeft.x + 1,
        card.bottom,
      ),
      Rect.fromLTRB(
        card.right - radius.bottomRight.x - 1,
        card.bottom - radius.bottomRight.y - 1,
        card.right,
        card.bottom,
      ),
    ]) {
      final visible = rect.intersect(screen);
      if (!visible.isEmpty) {
        canvas.drawRect(visible, paint);
      }
    }
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    if (_moving) {
      transform.multiply(_childTransform(_card));
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) {
      return false;
    }
    return result.addWithPaintTransform(
      transform: _moving ? _childTransform(_card) : null,
      position: position,
      hitTest: (result, position) => child.hitTest(result, position: position),
    );
  }
}
