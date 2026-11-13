import 'package:flutter/material.dart';

/// WhatsApp brand outline from Font Awesome Free 6.7.2 (CC BY 4.0).
/// Copyright Fonticons, Inc. https://fontawesome.com/license/free
class WhatsAppIcon extends StatelessWidget {
  const WhatsAppIcon({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: const _WhatsAppPainter(),
    ),
  );
}

class _WhatsAppPainter extends CustomPainter {
  const _WhatsAppPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 448, size.height / 448);
    canvas.translate(0, -32);
    final path = Path()
      ..moveTo(380.9, 97.1)
      ..cubicTo(339, 55.1, 283.2, 32, 223.9, 32)
      ..relativeCubicTo(-122.4, 0, -222, 99.6, -222, 222)
      ..relativeCubicTo(0, 39.1, 10.2, 77.3, 29.6, 111)
      ..lineTo(0, 480)
      ..relativeLineTo(117.7, -30.9)
      ..relativeCubicTo(32.4, 17.7, 68.9, 27, 106.1, 27)
      ..relativeLineTo(.1, 0)
      ..relativeCubicTo(122.3, 0, 224.1, -99.6, 224.1, -222)
      ..relativeCubicTo(0, -59.3, -25.2, -115, -67.1, -157)
      ..close()
      ..relativeMoveTo(-157, 341.6)
      ..relativeCubicTo(-33.2, 0, -65.7, -8.9, -94, -25.7)
      ..relativeLineTo(-6.7, -4)
      ..relativeLineTo(-69.8, 18.3)
      ..lineTo(72, 359.2)
      ..relativeLineTo(-4.4, -7)
      ..relativeCubicTo(-18.5, -29.4, -28.2, -63.3, -28.2, -98.2)
      ..relativeCubicTo(0, -101.7, 82.8, -184.5, 184.6, -184.5)
      ..relativeCubicTo(49.3, 0, 95.6, 19.2, 130.4, 54.1)
      ..relativeCubicTo(34.8, 34.9, 56.2, 81.2, 56.1, 130.5)
      ..relativeCubicTo(0, 101.8, -84.9, 184.6, -186.6, 184.6)
      ..close()
      ..relativeMoveTo(101.2, -138.2)
      ..relativeCubicTo(-5.5, -2.8, -32.8, -16.2, -37.9, -18)
      ..relativeCubicTo(-5.1, -1.9, -8.8, -2.8, -12.5, 2.8)
      ..relativeCubicTo(-3.7, 5.6, -14.3, 18, -17.6, 21.8)
      ..relativeCubicTo(-3.2, 3.7, -6.5, 4.2, -12, 1.4)
      ..relativeCubicTo(-32.6, -16.3, -54, -29.1, -75.5, -66)
      ..relativeCubicTo(-5.7, -9.8, 5.7, -9.1, 16.3, -30.3)
      ..relativeCubicTo(1.8, -3.7, .9, -6.9, -.5, -9.7)
      ..relativeCubicTo(-1.4, -2.8, -12.5, -30.1, -17.1, -41.2)
      ..relativeCubicTo(-4.5, -10.8, -9.1, -9.3, -12.5, -9.5)
      ..relativeCubicTo(-3.2, -.2, -6.9, -.2, -10.6, -.2)
      ..relativeCubicTo(-3.7, 0, -9.7, 1.4, -14.8, 6.9)
      ..relativeCubicTo(-5.1, 5.6, -19.4, 19, -19.4, 46.3)
      ..relativeCubicTo(0, 27.3, 19.9, 53.7, 22.6, 57.4)
      ..relativeCubicTo(2.8, 3.7, 39.1, 59.7, 94.8, 83.8)
      ..relativeCubicTo(35.2, 15.2, 49, 16.5, 66.6, 13.9)
      ..relativeCubicTo(10.7, -1.6, 32.8, -13.4, 37.4, -26.4)
      ..relativeCubicTo(4.6, -13, 4.6, -24.1, 3.2, -26.4)
      ..relativeCubicTo(-1.3, -2.5, -5, -3.9, -10.5, -6.6)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_WhatsAppPainter oldDelegate) => false;
}
