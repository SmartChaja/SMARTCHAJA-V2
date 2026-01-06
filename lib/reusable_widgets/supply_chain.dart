import 'dart:math';
import 'package:flutter/material.dart';

// --- Data Structures for the Animation ---

enum SupplyChainRole {
  producer,
  salesOfficer,
  distributor,
  retailer,
  foreman, // Assuming foreman is involved in final preparation/customization before client
  client
}

class StageNode {
  final SupplyChainRole role;
  final String label;
  final IconData icon;
  Offset position; // Will be calculated based on screen size
  double baseSize;
  double currentPulse = 0.0; // For activation animation
  DateTime? lastActivated; // To manage pulse duration

  StageNode({
    required this.role,
    required this.label,
    required this.icon,
    this.position = Offset.zero,
    this.baseSize = 20.0, // Base radius of the node
  });
}

class FlowOrb {
  int currentStageIndex;
  double progressToNextStage; // 0.0 to 1.0
  final double speed;
  final Color color;
  final double size;
  List<Offset> trail = []; // For the comet tail

  FlowOrb({
    this.currentStageIndex = 0,
    this.progressToNextStage = 0.0,
    required this.speed,
    required this.color,
    required this.size,
  });

  void update(double deltaTime, int totalStages) {
    progressToNextStage += speed * deltaTime;
    if (progressToNextStage >= 1.0) {
      if (currentStageIndex < totalStages -1) {
        currentStageIndex++;
        progressToNextStage = 0.0;
      } else {
        // Orb has reached the client, mark for removal or reset
        currentStageIndex = -1; // Mark as completed
      }
    }
  }

  void addTrailPoint(Offset point) {
    trail.add(point);
    if (trail.length > 15) { // Max trail length
      trail.removeAt(0);
    }
  }
}

// --- Animated Widget ---

class SupplyChainFlowAnimation extends StatefulWidget {
  final Widget child;
  final Color primaryColor; // Darker part of gradient
  final Color secondaryColor; // Lighter part of gradient / Node base
  final Color accentColor; // Orb and activation color

  const SupplyChainFlowAnimation({
    super.key,
    required this.child,
    this.primaryColor = const Color(0xFF0D1B4C),    // Very Dark Blue
    this.secondaryColor = const Color(0xFF1A237E), // Deep Indigo
    this.accentColor = const Color(0xFF4FC3F7),     // Bright Sky Blue
  });

  @override
  State<SupplyChainFlowAnimation> createState() => _SupplyChainFlowAnimationState();
}

class _SupplyChainFlowAnimationState extends State<SupplyChainFlowAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  List<StageNode> _stages = [];
  final List<FlowOrb> _orbs = [];
  final Random _random = Random();
  DateTime _lastFrameTime = DateTime.now();

  // Orb spawning logic
  Duration _orbSpawnInterval = const Duration(seconds: 2);
  DateTime _lastOrbSpawnTime = DateTime.now();


  @override
  void initState() {
    super.initState();
    _initializeStages();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // General animation cycle (can be arbitrary)
    )..addListener(() {
      final now = DateTime.now();
      final deltaTime = now.difference(_lastFrameTime).inMilliseconds / 1000.0;
      _lastFrameTime = now;

      _updateOrbs(deltaTime);
      _spawnOrbs();
      _updateStagePulses(deltaTime);

      if (mounted) {
        setState(() {});
      }
    })..repeat();


    // Spawn initial orb
    _spawnNewOrb();
  }

  void _initializeStages() {
    _stages = [
      StageNode(role: SupplyChainRole.producer, label: "Producer", icon: Icons.factory_outlined, baseSize: 22),
      StageNode(role: SupplyChainRole.salesOfficer, label: "Sales", icon: Icons.handshake_outlined, baseSize: 18),
      StageNode(role: SupplyChainRole.distributor, label: "Distributor", icon: Icons.local_shipping_outlined, baseSize: 20),
      StageNode(role: SupplyChainRole.retailer, label: "Retailer", icon: Icons.storefront_outlined, baseSize: 18),
      StageNode(role: SupplyChainRole.foreman, label: "Foreman", icon: Icons.build_circle_outlined, baseSize: 18),
      StageNode(role: SupplyChainRole.client, label: "Client", icon: Icons.person_outline, baseSize: 22),
    ];
  }

  void _spawnOrbs() {
    if (DateTime.now().difference(_lastOrbSpawnTime) > _orbSpawnInterval) {
      _spawnNewOrb();
      _lastOrbSpawnTime = DateTime.now();
      _orbSpawnInterval = Duration(milliseconds: 1500 + _random.nextInt(2000)); // Randomize next spawn
    }
  }

  void _spawnNewOrb() {
     if (_orbs.length < 5) { // Limit concurrent orbs
      _orbs.add(FlowOrb(
        speed: 0.2 + _random.nextDouble() * 0.2, // Orbs per second (moves 1 stage in X seconds)
        color: widget.accentColor.withOpacity(0.8 + _random.nextDouble()*0.2),
        size: 5.0 + _random.nextDouble() * 3.0,
      ));
    }
  }

  void _updateOrbs(double deltaTime) {
    List<FlowOrb> orbsToRemove = [];
    for (var orb in _orbs) {
      int previousStageIndex = orb.currentStageIndex;
      orb.update(deltaTime, _stages.length);

      if (orb.currentStageIndex == -1) { // Reached client
        orbsToRemove.add(orb);
        // Optionally, trigger a final effect at the client stage
        _stages.last.currentPulse = 1.0; // Start a strong pulse
        _stages.last.lastActivated = DateTime.now();

      } else if (orb.currentStageIndex != previousStageIndex && orb.currentStageIndex < _stages.length) {
        // Orb arrived at a new stage
        _stages[orb.currentStageIndex].currentPulse = 1.0; // Start pulse
        _stages[orb.currentStageIndex].lastActivated = DateTime.now();
      }
    }
    _orbs.removeWhere((orb) => orbsToRemove.contains(orb));
  }

 void _updateStagePulses(double deltaTime) {
    for (var stage in _stages) {
      if (stage.currentPulse > 0) {
        stage.currentPulse -= 2.0 * deltaTime; // Pulse decay rate (e.g., fades in 0.5s)
        if (stage.currentPulse < 0) stage.currentPulse = 0;
      }
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
          size: Size.infinite,
          painter: _SupplyChainPainter(
            stages: _stages,
            orbs: _orbs,
            animationValue: _controller.value, // General value if needed for background
            primaryColor: widget.primaryColor,
            secondaryColor: widget.secondaryColor,
            accentColor: widget.accentColor,
          ),
        ),
        widget.child,
      ],
    );
  }
}

// --- Custom Painter ---
class _SupplyChainPainter extends CustomPainter {
  final List<StageNode> stages;
  final List<FlowOrb> orbs;
  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  final Paint _nodePaint = Paint();
  final Paint _orbPaint = Paint();
  final Paint _trailPaint = Paint();
  final Paint _pathPaint = Paint();
  final TextPainter _textPainter = TextPainter(textDirection: TextDirection.ltr);

  _SupplyChainPainter({
    required this.stages,
    required this.orbs,
    required this.animationValue,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _calculateStagePositions(size); // Ensure positions are updated if size changes
    _drawPaths(canvas, size);
    _drawStageNodes(canvas, size);
    _drawOrbs(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [primaryColor, secondaryColor.withOpacity(0.8)],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle distant stars (optional)
    // Add a simple star drawing loop here if desired, different from stardust
  }

  void _calculateStagePositions(Size size) {
    final double verticalPadding = size.height * 0.1;
    final double availableHeight = size.height - 2 * verticalPadding;
    final double yIncrement = availableHeight / (stages.length -1);
    final double xMid = size.width / 2;

    for (int i = 0; i < stages.length; i++) {
      double xOffset = 0;
      // Create a gentle arc or zigzag for visual interest
      if (stages.length > 1) {
         xOffset = (sin(i / (stages.length -1) * pi * 1.5 - pi/4) * size.width * 0.15);
      }

      stages[i].position = Offset(
        xMid + xOffset,
        verticalPadding + i * yIncrement,
      );
    }
  }

  void _drawPaths(Canvas canvas, Size size) {
    if (stages.length < 2) return;

    _pathPaint
      ..color = accentColor.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    Path path = Path();
    path.moveTo(stages.first.position.dx, stages.first.position.dy);
    for (int i = 1; i < stages.length; i++) {
        final p2 = stages[i].position;
        // Simple line, could be quadratic bezier for curves if positions were more complex
        path.lineTo(p2.dx, p2.dy);
    }
    canvas.drawPath(path, _pathPaint);

     // Animate dashes along the path (more complex, example for one segment)
    for (int i = 0; i < stages.length -1; i++) {
        final p1 = stages[i].position;
// Corrected: should be stages[i+1].position
        if (i + 1 >= stages.length) continue;
        final nextStagePos = stages[i+1].position;

        // Check if any orb is on this segment
        bool isActiveSegment = orbs.any((orb) => orb.currentStageIndex == i && orb.progressToNextStage > 0);

        _pathPaint.color = accentColor.withOpacity(isActiveSegment ? 0.4 : 0.15);
        _pathPaint.strokeWidth = isActiveSegment ? 2.5 : 1.5;

        // Simple dashed line effect, can be improved with PathDashPathMetric
        const double dashWidth = 5.0;
        const double dashSpace = 3.0;
        double distance = (nextStagePos - p1).distance;
        double start = (animationValue * 200) % (dashWidth + dashSpace) ; // Animate offset

        for (double d = start - (dashWidth + dashSpace); d < distance; d += (dashWidth + dashSpace)) {
            if (d + dashWidth > 0 && d < distance) {
                final startPoint = Offset.lerp(p1, nextStagePos, d / distance)!;
                final endPoint = Offset.lerp(p1, nextStagePos, min(d + dashWidth, distance) / distance)!;
                canvas.drawLine(startPoint, endPoint, _pathPaint);
            }
        }
    }

  }


  void _drawStageNodes(Canvas canvas, Size size) {
    for (var stage in stages) {
      final pos = stage.position;
      final pulseAmount = stage.currentPulse; // 0.0 to 1.0

      // Pulsing effect
      final currentSize = stage.baseSize + pulseAmount * stage.baseSize * 0.5;
      final currentOpacity = 0.6 + pulseAmount * 0.4;

      // Outer Glow for pulse
      if (pulseAmount > 0.05) {
        _nodePaint
          ..color = accentColor.withOpacity(0.4 * pulseAmount)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, currentSize * 0.8 * pulseAmount);
        canvas.drawCircle(pos, currentSize * 1.5, _nodePaint);
      }

      // Node fill
      _nodePaint
        ..color = secondaryColor.withOpacity(currentOpacity)
        ..style = PaintingStyle.fill
        ..maskFilter = null; // Remove blur for core
      canvas.drawCircle(pos, currentSize, _nodePaint);

      // Node border
      _nodePaint
        ..color = accentColor.withOpacity(0.5 + pulseAmount * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 + pulseAmount * 1.0;
      canvas.drawCircle(pos, currentSize, _nodePaint);

      // Icon
      _textPainter.text = TextSpan(
        text: String.fromCharCode(stage.icon.codePoint),
        style: TextStyle(
          fontFamily: stage.icon.fontFamily,
          package: stage.icon.fontPackage,
          fontSize: currentSize * 0.9,
          color: Colors.white.withOpacity(0.8 + pulseAmount * 0.2),
        ),
      );
      _textPainter.layout();
      _textPainter.paint(canvas, pos - Offset(_textPainter.width / 2, _textPainter.height / 2));

      // Label
      _textPainter.text = TextSpan(
        text: stage.label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 10, // Fixed size for readability
          fontWeight: FontWeight.w500,
        ),
      );
      _textPainter.layout();
      _textPainter.paint(canvas, pos + Offset(-_textPainter.width / 2, currentSize + 5));
    }
  }

  void _drawOrbs(Canvas canvas, Size size) {
    for (var orb in orbs) {
      if (orb.currentStageIndex < 0 || orb.currentStageIndex >= stages.length -1) continue;

      final startNode = stages[orb.currentStageIndex];
      final endNode = stages[orb.currentStageIndex + 1];

      Offset orbPos = Offset.lerp(startNode.position, endNode.position, orb.progressToNextStage)!;
      orb.addTrailPoint(orbPos); // Add current position to trail

      // Draw Trail
      _trailPaint.style = PaintingStyle.fill;
      for(int i = 0; i < orb.trail.length; i++) {
        double trailFraction = i / orb.trail.length;
        _trailPaint.color = orb.color.withOpacity(0.5 * trailFraction * trailFraction); // Fade out trail
        _trailPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, (orb.size * 0.8) * trailFraction);
        canvas.drawCircle(orb.trail[i], orb.size * 0.8 * trailFraction, _trailPaint);
      }


      // Draw Orb Core
      _orbPaint
        ..color = orb.color
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, orb.size * 0.5); // Soft glow
      canvas.drawCircle(orbPos, orb.size, _orbPaint);
      
      _orbPaint
        ..color = Colors.white.withOpacity(0.8)
        ..maskFilter = null;
      canvas.drawCircle(orbPos, orb.size * 0.4, _orbPaint); // Inner highlight
    }
  }

  @override
  bool shouldRepaint(covariant _SupplyChainPainter oldDelegate) {
    return true; // Repaint continuously due to animation controller
  }
}