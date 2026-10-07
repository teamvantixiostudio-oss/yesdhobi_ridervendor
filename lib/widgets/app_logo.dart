import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum LogoVariant {
  navy,
  white,
}

/// The official Yes Dhobi vector brand logotype.
/// Renders the exact brand identity featuring the signature turquoise wave 'o'
/// and droplet 'i' with vector precision.
class YesDhobiLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final LogoVariant variant;
  final BoxFit fit;

  const YesDhobiLogo({
    super.key,
    this.width,
    this.height = 36.0,
    this.variant = LogoVariant.navy,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = variant == LogoVariant.white
        ? 'assets/images/yes_dhobi_logo_white.svg'
        : 'assets/images/yes_dhobi_logo.svg';

    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
    );
  }
}

/// Standalone Yes Dhobi Icon Mark / Emblem featuring the signature
/// turquoise wave swirl & water droplet in an isolated vector painter.
class YesDhobiEmblemMark extends StatelessWidget {
  final double size;
  final Color waveColor;
  final Color dropColor;

  const YesDhobiEmblemMark({
    super.key,
    this.size = 56.0,
    this.waveColor = const Color(0xFF00D2B4),
    this.dropColor = const Color(0xFF0A0944),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _YesDhobiEmblemPainter(
          waveColor: waveColor,
          dropColor: dropColor,
        ),
      ),
    );
  }
}

class _YesDhobiEmblemPainter extends CustomPainter {
  final Color waveColor;
  final Color dropColor;

  _YesDhobiEmblemPainter({
    required this.waveColor,
    required this.dropColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100.0;
    canvas.save();
    canvas.scale(scale, scale);

    final wavePaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    // Outer ring with inner hole
    final outerPath = Path();
    outerPath.addOval(Rect.fromCircle(center: const Offset(48, 54), radius: 32));
    final innerPath = Path();
    innerPath.addOval(Rect.fromCircle(center: const Offset(48, 54), radius: 18));
    final ringPath = Path.combine(PathOperation.difference, outerPath, innerPath);
    canvas.drawPath(ringPath, wavePaint);

    // Dynamic swirl wave inside the 'o'
    final swirlPath = Path();
    swirlPath.moveTo(34, 54);
    swirlPath.cubicTo(35, 42, 42, 38, 51, 38);
    swirlPath.cubicTo(60, 38, 64, 44, 63, 50);
    swirlPath.cubicTo(62, 55, 57, 57, 52, 54);
    swirlPath.cubicTo(48, 51, 47, 47, 50, 44);
    swirlPath.cubicTo(51, 43, 50, 42, 48, 42);
    swirlPath.cubicTo(42, 43, 38, 48, 38, 54);
    swirlPath.close();
    canvas.drawPath(swirlPath, wavePaint);

    // Water droplet on top right
    final dropPaint = Paint()
      ..color = dropColor
      ..style = PaintingStyle.fill;

    final dropletPath = Path();
    dropletPath.moveTo(76, 26);
    dropletPath.cubicTo(74, 21, 68, 14, 68, 8);
    dropletPath.cubicTo(68, 2, 73, -1, 78, -1);
    dropletPath.cubicTo(83, -1, 87, 2, 87, 8);
    dropletPath.cubicTo(87, 15, 78, 22, 76, 26);
    dropletPath.close();
    canvas.drawPath(dropletPath, dropPaint);

    // Droplet white shine highlight
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final shinePath = Path();
    shinePath.moveTo(73, 8);
    shinePath.cubicTo(73, 4, 75, 1.5, 78, 1);
    canvas.drawPath(shinePath, shinePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _YesDhobiEmblemPainter oldDelegate) =>
      oldDelegate.waveColor != waveColor || oldDelegate.dropColor != dropColor;
}

/// Backward-compatible AppLogo badge that renders the official Yes Dhobi emblem mark
class AppLogo extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final double borderRadius;
  final double iconSize;

  const AppLogo({
    super.key,
    this.size = 80,
    this.backgroundColor = const Color(0xFF0A0944),
    this.iconColor = Colors.white,
    this.borderRadius = 20,
    this.iconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D2B4).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: YesDhobiEmblemMark(
          size: iconSize > 0 ? iconSize : size * 0.58,
          waveColor: const Color(0xFF00D2B4),
          dropColor: iconColor == Colors.white ? Colors.white : const Color(0xFF0A0944),
        ),
      ),
    );
  }
}
