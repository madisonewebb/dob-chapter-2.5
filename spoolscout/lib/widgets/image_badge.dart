import 'package:flutter/material.dart';

class ImageBadgeWidget extends StatelessWidget {
  final String imageUrl;
  final Color backgroundColor;

  const ImageBadgeWidget({
    Key? key,
    required this.imageUrl,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150, // Same size as BadgeWidget
      height: 150, // Same size as BadgeWidget
      margin: const EdgeInsets.symmetric(horizontal: 10), // Consistent margin
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Solid outer circle
          CustomPaint(
            size: const Size(150, 150),
            painter: SolidCirclePainter(
              color: Colors.black,
              strokeWidth: 4.5,
            ),
          ),
          // Solid circle for background
          Container(
            width: 135,
            height: 135,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
          ),
          // Dashed inner circle
          CustomPaint(
            size: const Size(150, 150),
            painter: DashedCirclePainter(
              color: Colors.black,
              strokeWidth: 3,
              dashLength: 7.5,
              radiusFactor: 0.85,
            ),
          ),
          // Image in the center
          Positioned(
            child: ClipOval(
              child: Image.network(
                imageUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image_not_supported,
                  size: 50,
                  color: Colors.grey,
                ),
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
    this.strokeWidth = 4.5,
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
    this.strokeWidth = 3.0,
    this.dashLength = 7.5,
    this.radiusFactor = 0.85,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final double radius = (size.width / 2) * radiusFactor - strokeWidth;
    const double gapSize = 7.5;

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
