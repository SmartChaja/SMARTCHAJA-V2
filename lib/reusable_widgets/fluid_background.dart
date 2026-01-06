import 'dart:math';
import 'package:flutter/material.dart';

class HopeUnionBackground extends StatefulWidget {
  final Widget child;

  const HopeUnionBackground({Key? key, required this.child}) : super(key: key);

  @override
  _HopeUnionBackgroundState createState() => _HopeUnionBackgroundState();
}

class _HopeUnionBackgroundState extends State<HopeUnionBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ShootingStar> stars = [];
  final int starCount = 5; // Reduced from 20 to 5

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
          seconds: 60), // Increased duration from 30 to 60 seconds
    )..repeat();

    for (int i = 0; i < starCount; i++) {
      stars.add(ShootingStar());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          painter: HopeUnionPainter(stars, _controller),
          child: Container(),
        ),
        widget.child,
      ],
    );
  }
}

class ShootingStar {
  late Offset start;
  late Offset end;
  late Color color;
  late double speed;
  late double progress;

  ShootingStar() {
    _init();
  }

  void _init() {
    Random random = Random();
    double angle = random.nextDouble() * 2 * pi / 3 -
        pi / 6; // Angle between -30 and 30 degrees
    double length = 300 + random.nextDouble() * 500; // Increased length

    start = Offset(-100, random.nextDouble() * 800); // Start off-screen
    end =
        Offset(start.dx + cos(angle) * length, start.dy + sin(angle) * length);

    color = Color.lerp(
      Color(0xFF6A11CB), // Deep purple
      Color(0xFF2575FC), // Bright blue
      random.nextDouble(),
    )!
        .withOpacity(0.4); // Reduced opacity

    speed = 0.09 + random.nextDouble() * 0.1; // Reduced speed further
    progress = 0.0;
  }

  void update(double delta) {
    progress += speed * delta;
    if (progress > 1.0) {
      _init();
    }
  }
}

class HopeUnionPainter extends CustomPainter {
  final List<ShootingStar> stars;
  final Animation<double> animation;

  HopeUnionPainter(this.stars, this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      star.update(animation.value);

      final paint = Paint()
        ..color = star.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 // Reduced stroke width
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2);

      final path = Path()
        ..moveTo(star.start.dx, star.start.dy)
        ..lineTo(
          star.start.dx + (star.end.dx - star.start.dx) * star.progress,
          star.start.dy + (star.end.dy - star.start.dy) * star.progress,
        );

      // Draw the tail
      for (int i = 1; i <= 20; i++) {
        // Further increased tail length
        double tailProgress = star.progress - i * 0.015; // Slower fade
        if (tailProgress > 0) {
          paint.color = star.color
              .withOpacity(0.4 - i * 0.02); // Slower opacity reduction
          canvas.drawLine(
            Offset(
              star.start.dx + (star.end.dx - star.start.dx) * tailProgress,
              star.start.dy + (star.end.dy - star.start.dy) * tailProgress,
            ),
            Offset(
              star.start.dx +
                  (star.end.dx - star.start.dx) * (tailProgress + 0.02),
              star.start.dy +
                  (star.end.dy - star.start.dy) * (tailProgress + 0.02),
            ),
            paint,
          );
        }
      }

      // Draw the main star
      canvas.drawPath(path, paint);

      // Draw a glowing head
      final headPaint = Paint()
        ..color = star.color.withOpacity(0.6)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(
        Offset(
          star.start.dx + (star.end.dx - star.start.dx) * star.progress,
          star.start.dy + (star.end.dy - star.start.dy) * star.progress,
        ),
        2, // Reduced head size
        headPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
