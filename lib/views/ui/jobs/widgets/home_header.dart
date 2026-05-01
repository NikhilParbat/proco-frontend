import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Figma canvas: 678 × 1440
const double _dw = 678.0;
const double _dh = 1440.0;

double _fw(BuildContext context, double v) =>
    MediaQuery.of(context).size.width * v / _dw;

double _fh(BuildContext context, double v) =>
    MediaQuery.of(context).size.height * v / _dh;

class CardBackground extends StatelessWidget {
  const CardBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/Card Background.svg',
      width: _fw(context, 609),
      height: _fh(context, 1222),
      fit: BoxFit.contain,
    );
  }
}

class TopNavbarGroup extends StatelessWidget {
  const TopNavbarGroup({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _fw(context, 584),
      height: _fh(context, 61),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: SvgPicture.asset(
              'assets/Lagcon.svg',
              width: _fw(context, 205),
              height: _fh(context, 61),
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: _fw(context, 473),
            top: _fh(context, 16),
            child: SvgPicture.asset(
              'assets/filters.svg',
              width: _fw(context, 35),
              height: _fh(context, 32),
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: _fw(context, 548),
            top: _fh(context, 12),
            child: SvgPicture.asset(
              'assets/noti.svg',
              width: _fw(context, 36),
              height: _fh(context, 39),
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
