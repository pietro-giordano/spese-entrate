import 'package:flutter/material.dart';

/// Disegna un bordo tratteggiato arrotondato (Flutter non ne ha uno pronto).
/// Si usa come `painter` o `foregroundPainter` di un [CustomPaint].
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = RRect.fromRectAndRadius((Offset.zero & size).deflate(0.5), Radius.circular(radius));
    // Percorre il contorno alternando tratti da 4 px e spazi da 3 px.
    for (final metric in (Path()..addRRect(rect)).computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 7) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) => oldDelegate.color != color || oldDelegate.radius != radius;
}
