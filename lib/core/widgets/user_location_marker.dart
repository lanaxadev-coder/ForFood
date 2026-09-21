import 'dart:math' as math;
import 'package:flutter/material.dart';

class UserLocationMarker extends StatefulWidget {
  /// Total size of the marker.
  final double size;

  /// Compass heading in degrees.
  /// 0 = North
  /// 90 = East
  /// 180 = South
  /// 270 = West
  final double? heading;

  const UserLocationMarker({
    super.key,
    this.size = 70,
    this.heading,
  });

  @override
  State<UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<UserLocationMarker>
    with SingleTickerProviderStateMixin {
  static const Color _googleBlue = Color(0xFF4285F4);

  late final AnimationController _rotationController;

  double _currentHeading = 0;
  double _startHeading = 0;
  double _targetHeading = 0;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    if (widget.heading != null) {
      _currentHeading = widget.heading!;
      _targetHeading = widget.heading!;
    }
  }

  @override
  void didUpdateWidget(covariant UserLocationMarker oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newHeading = widget.heading;

    if (newHeading == null) {
      return;
    }

    if (oldWidget.heading == null) {
      _currentHeading = newHeading;
      _targetHeading = newHeading;
      return;
    }

    _animateToHeading(newHeading);
  }

  void _animateToHeading(double newHeading) {
    // Normalize heading to 0..360.
    newHeading = newHeading % 360;

    if (newHeading < 0) {
      newHeading += 360;
    }

    // Current displayed angle.
    final current = _currentHeading;

    // Find the SHORTEST rotation.
    double delta = newHeading - (current % 360);

    if (delta > 180) {
      delta -= 360;
    } else if (delta < -180) {
      delta += 360;
    }

    _startHeading = current;
    _targetHeading = current + delta;

    _rotationController
      ..stop()
      ..value = 0
      ..forward();

    _rotationController.addListener(_updateRotation);
  }

  void _updateRotation() {
    final t = Curves.easeOutCubic.transform(
      _rotationController.value,
    );

    setState(() {
      _currentHeading =
          _startHeading +
          (_targetHeading - _startHeading) * t;
    });

    if (_rotationController.isCompleted) {
      _rotationController.removeListener(_updateRotation);
    }
  }

  @override
  void dispose() {
    _rotationController.removeListener(_updateRotation);
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    final coreSize = size * 0.24;
    final ringSize = size * 0.36;
    final coneSize = size * 0.95;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ============================================================
          // DIRECTION CONE
          // ============================================================
          if (widget.heading != null)
            Transform.rotate(
              angle: _currentHeading * math.pi / 180,
              child: CustomPaint(
                size: Size(coneSize, coneSize),
                painter: _HeadingConePainter(
                  color: _googleBlue,
                ),
              ),
            ),

          // ============================================================
          // SOFT BLUE GLOW
          // ============================================================
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _googleBlue.withOpacity(0.20),
                  _googleBlue.withOpacity(0.08),
                  _googleBlue.withOpacity(0.0),
                ],
                stops: const [
                  0.0,
                  0.5,
                  1.0,
                ],
              ),
            ),
          ),

          // ============================================================
          // WHITE RING
          // ============================================================
          Container(
            width: ringSize,
            height: ringSize,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),

          // ============================================================
          // BLUE CENTER DOT
          // ============================================================
          Container(
            width: coreSize,
            height: coreSize,
            decoration: const BoxDecoration(
              color: _googleBlue,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// GOOGLE-STYLE DIRECTION CONE
// ============================================================

class _HeadingConePainter extends CustomPainter {
  final Color color;

  const _HeadingConePainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2;

    // 60° total cone.
    const halfAngle = 30 * math.pi / 180;

    final path = Path()
      ..moveTo(
        center.dx,
        center.dy,
      )
      ..lineTo(
        center.dx + radius * math.sin(-halfAngle),
        center.dy - radius * math.cos(-halfAngle),
      )
      ..arcTo(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        -math.pi / 2 - halfAngle,
        2 * halfAngle,
        false,
      )
      ..close();

    // ============================================================
    // SOFT GRADIENT
    // ============================================================

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.45),
          color.withOpacity(0.18),
          color.withOpacity(0.0),
        ],
        stops: const [
          0.05,
          0.55,
          1.0,
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
      );

    canvas.drawPath(path, paint);

    // ============================================================
    // VERY SUBTLE EDGE
    // ============================================================

    final edgePaint = Paint()
      ..color = color.withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawPath(path, edgePaint);
  }

  @override
  bool shouldRepaint(
    covariant _HeadingConePainter oldDelegate,
  ) {
    return oldDelegate.color != color;
  }
}