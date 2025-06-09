import 'package:flutter/material.dart';

class BadgeWidget extends StatelessWidget {
  final String label;
  final Color backgroundColor;

  const BadgeWidget({
    Key? key,
    required this.label,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150, // Increased size (100 * 1.5)
      height: 150, // Increased size (100 * 1.5)
      margin: const EdgeInsets.symmetric(horizontal: 10), // Adjusted spacing
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Solid outer circle
          CustomPaint(
            size: const Size(150, 150), // Adjust size
            painter: SolidCirclePainter(
              color: Colors.black,
              strokeWidth: 4.5, // Increased stroke width (3 * 1.5)
            ),
          ),
          // Solid circle for background
          Container(
            width: 135, // Increased size (90 * 1.5)
            height: 135, // Increased size (90 * 1.5)
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
          ),
          // Dashed inner circle
          CustomPaint(
            size: const Size(150, 150), // Adjust size
            painter: DashedCirclePainter(
              color: Colors.black,
              strokeWidth: 3, // Increased stroke width (2 * 1.5)
              dashLength: 7.5, // Increased dash length (5 * 1.5)
              radiusFactor: 0.85, // Keep the same radius factor
            ),
          ),
          // Label text with ChickenWonder font
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'ChickenWonder', // Specify the ChickenWonder font
                fontSize: 15, // Increased font size (10 * 1.5)
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SolidCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  SolidCirclePainter({
    required this.color,
    this.strokeWidth = 4.5, // Updated default
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final double radius = size.width / 2 - strokeWidth / 2;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double radiusFactor;

  DashedCirclePainter({
    required this.color,
    this.strokeWidth = 3.0, // Updated default
    this.dashLength = 7.5, // Updated default
    this.radiusFactor = 0.85, // Keep the same
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final double radius = (size.width / 2) * radiusFactor - strokeWidth;
    const double gapSize = 7.5; // Adjusted to match new dashLength

    double totalCircumference = 2 * 3.141592653589793 * radius;
    double dashCount =
        (totalCircumference / (dashLength + gapSize)).floorToDouble();

    double dashSpacingAngle = (2 * 3.141592653589793) / dashCount;

    for (int i = 0; i < dashCount; i++) {
      double startAngle = i * dashSpacingAngle;
      double endAngle = startAngle +
          (dashSpacingAngle * (dashLength / (dashLength + gapSize)));

      canvas.drawArc(
        Rect.fromCircle(
            center: Offset(size.width / 2, size.height / 2), radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
