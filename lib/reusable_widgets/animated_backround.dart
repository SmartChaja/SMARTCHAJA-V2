import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


// usage
//AnimatedBackground
//  isFormValid: _isFormValid,
//         backgroundGradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: isDarkMode
//               ? [
//                   const Color(0xFF1F2833),
//                   const Color(0xFF0B0C10),
//                 ]
//               : [
//                   const Color.fromARGB(232, 0, 78, 203),
//                   Colors.white,
//                 ],
//         ),

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final VoidCallback? onInteraction;
  final bool isFormValid;
  final Gradient? backgroundGradient; // Added background gradient parameter

  const AnimatedBackground({
    super.key,
    required this.child,
    this.primaryColor = const Color(0xFF1E3A8A), // Deep blue
    this.secondaryColor = const Color(0xFF0F2557), // Darker blue
    this.accentColor = const Color(0xFF4F86F7), // Bright blue accent
    this.onInteraction,
    this.isFormValid = false,
    this.backgroundGradient, // Add the gradient parameter
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  // Data structures
  late List<Node> _nodes;
  late List<Hub> _hubs;
  late Offset? _interactionPoint;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _flowController;
  late AnimationController _interactionController;

  // Constants
  final int _nodeCount = 70;
  final int _hubCount = 6;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _interactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _interactionPoint = null;

    // Initialize network structure
    _initializeNetwork();
  }

  void _initializeNetwork() {
    final random = Random();

    // Create hub nodes (connection centers) with wider distribution
    _hubs = List.generate(_hubCount, (index) {
      // Place hubs across the entire screen with better distribution
      return Hub(
        position: Offset(
          random.nextDouble() * 0.9 + 0.05, // x position from 0.05 to 0.95
          random.nextDouble() * 0.9 + 0.05, // y position from 0.05 to 0.95
        ),
        size: 8.0 + random.nextDouble() * 4.0,
        hubType: HubType.values[random.nextInt(HubType.values.length)],
      );
    });

    // Create regular nodes
    _nodes = List.generate(_nodeCount, (index) {
      // Assign each node to a random hub
      final connectToHub = _hubs[random.nextInt(_hubs.length)];

      // Position nodes around their hub with some randomization but wider distribution
      final angle = random.nextDouble() * 2 * pi;
      final distance = 0.05 +
          (random.nextDouble() * 0.2); // Increased distance for wider spread

      Offset position = Offset(
        (connectToHub.position.dx + cos(angle) * distance).clamp(0.05, 0.95),
        (connectToHub.position.dy + sin(angle) * distance).clamp(0.05, 0.95),
      );

      // For some nodes, place them randomly across the screen instead of clustering
      if (random.nextDouble() > 0.7) {
        position = Offset(
          random.nextDouble() * 0.9 + 0.05,
          random.nextDouble() * 0.9 + 0.05,
        );
      }

      return Node(
        position: position,
        size: 2.0 + random.nextDouble() * 2.0,
        connectionStrength: 0.5 + random.nextDouble() * 0.5,
        connectedHub: connectToHub,
        secondaryConnections: random.nextInt(3),
      );
    });

    // Create secondary connections between nodes
    for (var node in _nodes) {
      if (node.secondaryConnections > 0) {
        for (int i = 0; i < node.secondaryConnections; i++) {
          // Find a node to connect to (preferably from a different hub)
          List<Node> potentialConnections = _nodes
              .where((n) => n != node && n.connectedHub != node.connectedHub)
              .toList();

          if (potentialConnections.isNotEmpty) {
            potentialConnections.shuffle();
            node.secondaryNodes.add(potentialConnections.first);
          }
        }
      }
    }
  }

  void _updateInteraction(Offset? position) {
    if (position != null && _interactionPoint == null) {
      _interactionController.forward(from: 0.0);
    } else if (position == null && _interactionPoint != null) {
      _interactionController.reverse(from: 1.0);
    }

    setState(() {
      _interactionPoint = position;
    });

    if (widget.onInteraction != null) {
      widget.onInteraction!();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flowController.dispose();
    _interactionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _updateInteraction(details.localPosition),
      onTapUp: (_) => _updateInteraction(null),
      onPanUpdate: (details) => _updateInteraction(details.localPosition),
      onPanEnd: (_) => _updateInteraction(null),
      child: MouseRegion(
        onHover:
            kIsWeb ? (event) => _updateInteraction(event.localPosition) : null,
        onExit: kIsWeb ? (_) => _updateInteraction(null) : null,
        child: Stack(
          children: [
            // Background and network visualization
            CustomPaint(
              size: Size.infinite,
              painter: NetworkPainter(
                nodes: _nodes,
                hubs: _hubs,
                pulseAnimation: _pulseController,
                flowAnimation: _flowController,
                interactionPoint: _interactionPoint,
                interactionStrength: _interactionController,
                isFormValid: widget.isFormValid,
                primaryColor: widget.primaryColor,
                secondaryColor: widget.secondaryColor,
                accentColor: widget.accentColor,
                backgroundGradient: widget
                    .backgroundGradient, // Pass the gradient to the painter
              ),
            ),
            widget.child,
          ],
        ),
      ),
    );
  }
}

// Hub types for different visual representations
enum HubType {
  distribution,
  sales,
  logistics,
  warehouse,
}

// Hub node - represents major connection points
class Hub {
  final Offset position;
  final double size;
  final HubType hubType;
  final List<Offset> orbitPoints = [];

  Hub({
    required this.position,
    required this.size,
    required this.hubType,
  }) {
    // Generate orbit path points
    final random = Random();
    final orbitCount = 12 + random.nextInt(12);
    for (int i = 0; i < orbitCount; i++) {
      final angle = (i / orbitCount) * 2 * pi;
      final variation = random.nextDouble() * 0.2 + 0.9; // Slightly elliptical
      orbitPoints.add(Offset(
        cos(angle) * variation,
        sin(angle),
      ));
    }
  }

  Color getColor(Color baseColor) {
    switch (hubType) {
      case HubType.distribution:
        return HSLColor.fromColor(baseColor).withLightness(0.6).toColor();
      case HubType.sales:
        return HSLColor.fromColor(baseColor).withLightness(0.5).toColor();
      case HubType.logistics:
        return HSLColor.fromColor(baseColor).withLightness(0.45).toColor();
      case HubType.warehouse:
        return HSLColor.fromColor(baseColor).withLightness(0.4).toColor();
    }
  }

  String getLabel() {
    switch (hubType) {
      case HubType.distribution:
        return "D";
      case HubType.sales:
        return "S";
      case HubType.logistics:
        return "L";
      case HubType.warehouse:
        return "W";
    }
  }
}

// Node - represents individual points in the network
class Node {
  final Offset position;
  final double size;
  final double connectionStrength;
  final Hub connectedHub;
  final int secondaryConnections;
  final List<Node> secondaryNodes = [];

  // Animation state
  Offset velocity = Offset.zero;
  double activityLevel = 0.0;
  double pulse = 0.0;

  Node({
    required this.position,
    required this.size,
    required this.connectionStrength,
    required this.connectedHub,
    required this.secondaryConnections,
  });
}

// CustomPainter for rendering the network
class NetworkPainter extends CustomPainter {
  final List<Node> nodes;
  final List<Hub> hubs;
  final Animation<double> pulseAnimation;
  final Animation<double> flowAnimation;
  final Animation<double> interactionStrength;
  final Offset? interactionPoint;
  final bool isFormValid;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Gradient? backgroundGradient; // Add gradient parameter

  NetworkPainter({
    required this.nodes,
    required this.hubs,
    required this.pulseAnimation,
    required this.flowAnimation,
    required this.interactionStrength,
    required this.interactionPoint,
    required this.isFormValid,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    this.backgroundGradient, // Make gradient optional
  }) : super(
            repaint: Listenable.merge(
                [pulseAnimation, flowAnimation, interactionStrength]));

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background gradient
    _drawBackground(canvas, size);

    // Draw grid lines
    _drawGrid(canvas, size);

    // Draw connections first (behind nodes)
    _drawConnections(canvas, size);

    // Draw data flow animations
    _drawDataFlow(canvas, size);

    // Draw nodes
    _drawNodes(canvas, size);

    // Draw hubs (on top of nodes)
    _drawHubs(canvas, size);

    // Draw interaction effects
    if (interactionPoint != null) {
      _drawInteraction(canvas, size);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    if (backgroundGradient != null) {
      // Use the provided background gradient
      final Paint bgPaint = Paint()
        ..shader = backgroundGradient!
            .createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    } else {
      // Use the default radial gradient background
      final Paint bgPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.1, -0.3),
          radius: 1.2,
          colors: [
            secondaryColor.withOpacity(0.9),
            secondaryColor,
          ],
          stops: const [0.1, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = primaryColor.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final bigGridPaint = Paint()
      ..color = primaryColor.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Draw horizontal grid lines
    final horizontalCount = (size.height / 40).ceil();
    for (int i = 0; i <= horizontalCount; i++) {
      final y = i * 40.0;
      final paint = i % 4 == 0 ? bigGridPaint : gridPaint;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw vertical grid lines
    final verticalCount = (size.width / 40).ceil();
    for (int i = 0; i <= verticalCount; i++) {
      final x = i * 40.0;
      final paint = i % 4 == 0 ? bigGridPaint : gridPaint;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  void _drawConnections(Canvas canvas, Size size) {
    // Draw primary connections (node to hub)
    for (final node in nodes) {
      final nodePos =
          Offset(node.position.dx * size.width, node.position.dy * size.height);
      final hubPos = Offset(node.connectedHub.position.dx * size.width,
          node.connectedHub.position.dy * size.height);

      // Calculate connection strength with animation
      final baseOpacity = node.connectionStrength * 0.5;
      final animatedOpacity =
          baseOpacity + (sin(pulseAnimation.value * 2 * pi) * 0.1);

      // Primary connection line
      final primaryPaint = Paint()
        ..color = accentColor.withOpacity(animatedOpacity.clamp(0.1, 0.7))
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawLine(nodePos, hubPos, primaryPaint);
    }

    // Draw secondary connections (node to node)
    for (final node in nodes) {
      if (node.secondaryNodes.isEmpty) continue;

      final nodePos =
          Offset(node.position.dx * size.width, node.position.dy * size.height);

      for (final secondaryNode in node.secondaryNodes) {
        final secondaryPos = Offset(secondaryNode.position.dx * size.width,
            secondaryNode.position.dy * size.height);

        // Animate opacity for secondary connection
        final distance = (nodePos - secondaryPos).distance;
        final normalizedDistance = (distance / size.width).clamp(0.0, 0.3);
        final lineOpacity = 0.15 -
            normalizedDistance * 0.2 +
            sin(pulseAnimation.value * 2 * pi + node.hashCode) * 0.05;

        final secondaryPaint = Paint()
          ..color = accentColor.withOpacity(lineOpacity)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;

        // Draw curved line for secondary connections
        final controlPoint = Offset(
          (nodePos.dx + secondaryPos.dx) / 2 +
              sin(pulseAnimation.value * pi) * 15,
          (nodePos.dy + secondaryPos.dy) / 2 +
              cos(pulseAnimation.value * pi) * 15,
        );

        final path = Path()
          ..moveTo(nodePos.dx, nodePos.dy)
          ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, secondaryPos.dx,
              secondaryPos.dy);

        canvas.drawPath(path, secondaryPaint);
      }
    }
  }

  void _drawDataFlow(Canvas canvas, Size size) {
    // Draw animated data packets flowing through the connections
    final flowOffset = flowAnimation.value;
    final random = Random(42); // Fixed seed for consistency

    // Only animate some connections for less visual noise
    for (int i = 0; i < nodes.length; i += 3) {
      if (i >= nodes.length) continue;
      final node = nodes[i];

      // Skip nodes that aren't actively animating
      if (random.nextDouble() > 0.7) continue;

      final nodePos =
          Offset(node.position.dx * size.width, node.position.dy * size.height);
      final hubPos = Offset(node.connectedHub.position.dx * size.width,
          node.connectedHub.position.dy * size.height);

      // Calculate flow position (0.0 to 1.0 along the line)
      final flowPosition = (flowOffset + (i / nodes.length)) % 1.0;
      final flowPoint = Offset.lerp(nodePos, hubPos, flowPosition) ?? nodePos;

      // Draw animated data packet
      final dataPacketPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill;

      // Pulse size based on animation
      final packetSize = 3.0 + sin(pulseAnimation.value * 2 * pi) * 1.0;

      canvas.drawCircle(flowPoint, packetSize, dataPacketPaint);

      // Draw glow effect
      final glowPaint = Paint()
        ..color = accentColor.withOpacity(0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(flowPoint, packetSize * 2, glowPaint);
    }
  }

  void _drawNodes(Canvas canvas, Size size) {
    for (final node in nodes) {
      final pos =
          Offset(node.position.dx * size.width, node.position.dy * size.height);

      // Calculate animated opacity
      final pulseValue =
          0.7 + sin(pulseAnimation.value * 2 * pi + node.hashCode) * 0.2;

      // Node glow
      final glowPaint = Paint()
        ..color = accentColor.withOpacity(0.3 * pulseValue)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      canvas.drawCircle(pos, node.size * 1.8, glowPaint);

      // Node core
      final nodePaint = Paint()
        ..color = accentColor.withOpacity(0.8 * pulseValue)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pos, node.size, nodePaint);
    }
  }

  void _drawHubs(Canvas canvas, Size size) {
    for (final hub in hubs) {
      final pos =
          Offset(hub.position.dx * size.width, hub.position.dy * size.height);

      // Draw orbital ring around hub
      final orbitPaint = Paint()
        ..color = accentColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final orbitPath = Path();

      for (int i = 0; i < hub.orbitPoints.length; i++) {
        final orbitPoint = hub.orbitPoints[i];
        // Scale orbit points based on hub size
        final scaledPoint = Offset(
          pos.dx + orbitPoint.dx * hub.size * 2.5,
          pos.dy + orbitPoint.dy * hub.size * 2.5,
        );

        if (i == 0) {
          orbitPath.moveTo(scaledPoint.dx, scaledPoint.dy);
        } else {
          orbitPath.lineTo(scaledPoint.dx, scaledPoint.dy);
        }
      }

      orbitPath.close();
      canvas.drawPath(orbitPath, orbitPaint);

      // Hub glow
      final hubGlowPaint = Paint()
        ..color = hub.getColor(accentColor).withOpacity(0.4)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(pos, hub.size * 2, hubGlowPaint);

      // Hub core
      final hubPaint = Paint()
        ..color = hub.getColor(accentColor)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pos, hub.size, hubPaint);

      // Hub icon/label
      final textPainter = TextPainter(
        text: TextSpan(
          text: hub.getLabel(),
          style: TextStyle(
            color: Colors.white,
            fontSize: hub.size * 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          pos.dx - textPainter.width / 2,
          pos.dy - textPainter.height / 2,
        ),
      );
    }
  }

  void _drawInteraction(Canvas canvas, Size size) {
    if (interactionPoint == null) return;

    final strength = interactionStrength.value;

    // Highlight nodes and hubs near the interaction point
    _highlightNearbyElements(canvas, size, strength);

    // Interaction point highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3 * strength)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Pulse effect
    final pulseSize = 30.0 + sin(pulseAnimation.value * 4 * pi) * 8.0;
    canvas.drawCircle(interactionPoint!, pulseSize * strength, highlightPaint);

    // Inner circle
    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.2 * strength)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(interactionPoint!, 8.0 * strength, innerPaint);

    // Draw scanning lines
    _drawScanLines(canvas, size, strength);
  }

  void _highlightNearbyElements(Canvas canvas, Size size, double strength) {
    if (interactionPoint == null) return;

    const highlightRadius = 150.0;

    // Highlight nearby nodes
    for (final node in nodes) {
      final nodePos =
          Offset(node.position.dx * size.width, node.position.dy * size.height);
      final distance = (nodePos - interactionPoint!).distance;

      if (distance < highlightRadius) {
        final highlightIntensity = 1.0 - (distance / highlightRadius);
        final highlightPaint = Paint()
          ..color =
              Colors.white.withOpacity(0.5 * highlightIntensity * strength)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        canvas.drawCircle(nodePos, node.size * 3, highlightPaint);
      }
    }

    // Highlight nearby hubs
    for (final hub in hubs) {
      final hubPos =
          Offset(hub.position.dx * size.width, hub.position.dy * size.height);
      final distance = (hubPos - interactionPoint!).distance;

      if (distance < highlightRadius * 1.5) {
        final highlightIntensity = 1.0 - (distance / (highlightRadius * 1.5));
        final highlightPaint = Paint()
          ..color = hub
              .getColor(accentColor)
              .withOpacity(0.6 * highlightIntensity * strength)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;

        canvas.drawCircle(hubPos, hub.size * 3.5, highlightPaint);

        // Draw connection to interaction point
        final connectionPaint = Paint()
          ..color = hub
              .getColor(accentColor)
              .withOpacity(0.3 * highlightIntensity * strength)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

        // Animated dashed line - simplified approach without using PathMetrics/Tangent
        final dashPath = Path();
        dashPath.moveTo(hubPos.dx, hubPos.dy);
        dashPath.lineTo(interactionPoint!.dx, interactionPoint!.dy);

        // Draw dashed line manually
        final dashWidth = 5.0;
        final dashSpace = 5.0;
        final dashCount = (distance / (dashWidth + dashSpace)).floor();
        final dashOffset =
            (pulseAnimation.value * (dashWidth + dashSpace) * 2) %
                (dashWidth + dashSpace);

        // Draw dashes manually using Offset.lerp instead of path extraction
        for (int i = 0; i < dashCount; i++) {
          final startFraction =
              i * (dashWidth + dashSpace) / distance - dashOffset / distance;
          final endFraction = startFraction + dashWidth / distance;

          if (startFraction < 0) continue;
          if (startFraction > 1.0) break;

          final startPoint = Offset.lerp(
              hubPos, interactionPoint!, startFraction.clamp(0.0, 1.0))!;
          final endPoint = Offset.lerp(
              hubPos, interactionPoint!, endFraction.clamp(0.0, 1.0))!;

          canvas.drawLine(startPoint, endPoint, connectionPaint);
        }
      }
    }
  }

  void _drawScanLines(Canvas canvas, Size size, double strength) {
    if (interactionPoint == null) return;

    final scanPaint = Paint()
      ..color = Colors.white.withOpacity(0.15 * strength)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Horizontal scan line
    final horizontalScanY = interactionPoint!.dy +
        sin(pulseAnimation.value * 4 * pi) * 40.0 * strength;
    canvas.drawLine(
      Offset(0, horizontalScanY),
      Offset(size.width, horizontalScanY),
      scanPaint,
    );

    // Vertical scan line
    final verticalScanX = interactionPoint!.dx +
        cos(pulseAnimation.value * 4 * pi) * 40.0 * strength;
    canvas.drawLine(
      Offset(verticalScanX, 0),
      Offset(verticalScanX, size.height),
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
