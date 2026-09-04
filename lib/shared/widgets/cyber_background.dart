import 'dart:math';
import 'package:flutter/material.dart';

class CyberBackground extends StatefulWidget {
  final Widget? child;
  const CyberBackground({Key? key, this.child}) : super(key: key);

  @override
  _CyberBackgroundState createState() => _CyberBackgroundState();
}

class _CyberBackgroundState extends State<CyberBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  final List<_CyberParticle> _particles = [];

  // Nombre de particules borné pour garantir la stabilité des performances (Anti-DoS CPU)
  static const int _maxParticles = 35;

  @override
  void initState() {
    super.initState();
    // Contrôleur d'animation unique géré de manière sécurisée
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialisation sécurisée du pool de particules
    for (int i = 0; i < _maxParticles; i++) {
      _particles.add(_CyberParticle(_random));
    }
  }

  @override
  void dispose() {
    // EMPLACEMENT EXACT DE LA CORRECTION : Libération rigoureuse des ressources graphiques
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: CyberPainter(_particles, _controller.value),
          child: widget.child ?? Container(),
        );
      },
    );
  }
}

class _CyberParticle {
  late double x, y, speed, opacity;
  _CyberParticle(Random random) {
    reset(random);
  }

  void reset(Random random) {
    x = random.nextDouble();
    y = random.nextDouble();
    speed = 0.002 + random.nextDouble() * 0.004;
    opacity = 0.2 + random.nextDouble() * 0.6;
  }
}

class CyberPainter extends CustomPainter {
  final List<_CyberParticle> particles;
  final double progress;

  CyberPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Fond global ultra-sombre typique des interfaces SecOps
    final bgPaint = Paint()..color = const Color(0xFF070B19);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final linePaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.1)
      ..strokeWidth = 1.0;

    // Rendu géométrique optimisé
    for (var particle in particles) {
      particle.y -= particle.speed;
      if (particle.y < 0) particle.y = 1.0;

      double px = particle.x * size.width;
      double py = particle.y * size.height;

      // Dessin d'un nœud lumineux de grille cyber
      final particlePaint = Paint()
        ..color = Colors.cyanAccent.withOpacity(particle.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

      canvas.drawCircle(Offset(px, py), 2.0, particlePaint);

      // Connexion matricielle subtile entre points proches
      for (var other in particles) {
        double ox = other.x * size.width;
        double oy = other.y * size.height;
        double distance = (Offset(px, py) - Offset(ox, oy)).distance;

        if (distance < 80) {
          canvas.drawLine(Offset(px, py), Offset(ox, oy), linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CyberPainter oldDelegate) {
    // Rafraîchissement conditionnel strict piloté par l'animation
    return oldDelegate.progress != progress;
  }
}