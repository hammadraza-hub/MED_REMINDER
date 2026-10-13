import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// ============================================================
/// LANGUAGE FLAG — round country flag icon
///
/// Emoji flags ke bajaye CustomPainter se draw hota hai, taake
/// flag circle ko bilkul fill kare (emoji glyph mein padding hoti
/// hai jo round fit ko kharab karti hai).
///
/// Flag 3:2 aspect mein draw hota hai aur square canvas par cover
/// (center-crop) kiya jata hai — phir circle mein clip.
/// ============================================================
class LanguageFlag extends StatelessWidget {
  const LanguageFlag({super.key, required this.code, this.size = 30});

  /// ISO language code — flag isi se chunte hain.
  final String code;

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.flagWhite,
        border: Border.all(color: AppColors.shareBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(painter: _FlagPainter(code)),
    );
  }
}

class _FlagPainter extends CustomPainter {
  _FlagPainter(this.code);

  final String code;

  @override
  void paint(Canvas canvas, Size size) {
    // Cover: 3:2 flag ko square par center-crop karo (bilkul fit).
    final h = size.height;
    final w = h * 1.5;
    final rect = Rect.fromLTWH((size.width - w) / 2, 0, w, h);

    switch (code) {
      case 'fr':
        _france(canvas, rect);
      case 'es':
        _spain(canvas, rect);
      case 'hi':
        _india(canvas, rect);
      case 'ar':
        _saudi(canvas, rect);
      default:
        _usa(canvas, rect);
    }
  }

  void _fill(Canvas canvas, Rect rect, Color color) {
    canvas.drawRect(rect, Paint()..color = color);
  }

  // France — vertical tricolor
  void _france(Canvas canvas, Rect r) {
    final band = r.width / 3;
    _fill(canvas, Rect.fromLTWH(r.left, r.top, band, r.height),
        AppColors.flagFranceBlue);
    _fill(canvas, Rect.fromLTWH(r.left + band, r.top, band, r.height),
        AppColors.flagWhite);
    _fill(canvas, Rect.fromLTWH(r.left + 2 * band, r.top, band, r.height),
        AppColors.flagFranceRed);
  }

  // Spain — horizontal red / yellow / red
  void _spain(Canvas canvas, Rect r) {
    final h = r.height;
    _fill(canvas, Rect.fromLTWH(r.left, r.top, r.width, h * 0.25),
        AppColors.flagSpainRed);
    _fill(canvas, Rect.fromLTWH(r.left, r.top + h * 0.25, r.width, h * 0.5),
        AppColors.flagSpainYellow);
    _fill(canvas, Rect.fromLTWH(r.left, r.top + h * 0.75, r.width, h * 0.25),
        AppColors.flagSpainRed);
  }

  // India — saffron / white / green + navy chakra
  void _india(Canvas canvas, Rect r) {
    final band = r.height / 3;
    _fill(canvas, Rect.fromLTWH(r.left, r.top, r.width, band),
        AppColors.flagIndiaSaffron);
    _fill(canvas, Rect.fromLTWH(r.left, r.top + band, r.width, band),
        AppColors.flagWhite);
    _fill(canvas, Rect.fromLTWH(r.left, r.top + 2 * band, r.width, band),
        AppColors.flagIndiaGreen);

    final center = Offset(r.center.dx, r.top + r.height / 2);
    final radius = band * 0.40;
    final stroke = r.width * 0.012;

    final ring = Paint()
      ..color = AppColors.flagIndiaNavy
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, ring);
    canvas.drawCircle(center, radius * 0.14, Paint()..color = AppColors.flagIndiaNavy);

    for (var i = 0; i < 24; i++) {
      final angle = i * math.pi / 12;
      canvas.drawLine(
        center,
        center + Offset(radius * math.cos(angle), radius * math.sin(angle)),
        ring..strokeWidth = r.width * 0.006,
      );
    }
  }

  // United States — stripes + blue canton with stars
  void _usa(Canvas canvas, Rect r) {
    final stripe = r.height / 13;
    for (var i = 0; i < 13; i++) {
      _fill(
        canvas,
        Rect.fromLTWH(r.left, r.top + i * stripe, r.width, stripe + 0.5),
        i.isEven ? AppColors.flagUsRed : AppColors.flagWhite,
      );
    }

    final canton = Rect.fromLTWH(r.left, r.top, r.width * 0.42, stripe * 7);
    _fill(canvas, canton, AppColors.flagUsBlue);

    const cols = 5;
    const rows = 4;
    final star = Paint()..color = AppColors.flagWhite;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final dx = canton.left +
            (col + 0.5) * canton.width / cols +
            (row.isOdd ? canton.width / (cols * 2) : 0);
        final dy = canton.top + (row + 0.5) * canton.height / rows;
        canvas.drawCircle(Offset(dx, dy), r.width * 0.014, star);
      }
    }
  }

  // Saudi Arabia — green field + white script/sword lines
  void _saudi(Canvas canvas, Rect r) {
    _fill(canvas, r, AppColors.flagSaudiGreen);

    final line = Paint()
      ..color = AppColors.flagWhite
      ..strokeCap = StrokeCap.round;

    final scriptY = r.center.dy - r.height * 0.05;
    canvas.drawLine(
      Offset(r.left + r.width * 0.17, scriptY),
      Offset(r.left + r.width * 0.83, scriptY),
      line..strokeWidth = r.height * 0.05,
    );

    final swordY = r.center.dy + r.height * 0.12;
    canvas.drawLine(
      Offset(r.left + r.width * 0.20, swordY),
      Offset(r.left + r.width * 0.74, swordY),
      line..strokeWidth = r.height * 0.04,
    );
  }

  @override
  bool shouldRepaint(_FlagPainter oldDelegate) => oldDelegate.code != code;
}
