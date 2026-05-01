import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

// Figma canvas reference: W=678, H=1440
const double _dw = 678.0;
const double _dh = 1440.0;

class HomeCardLayout extends StatelessWidget {
  final String opportunityType;
  final String domain;
  final String location;
  final String imageUrl;

  const HomeCardLayout({
    super.key,
    this.opportunityType = 'INTERNSHIP',
    this.domain = 'Web Development',
    this.location = 'Remote – Austin, TX',
    this.imageUrl = '',
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    double fw(double v) => sw * v / _dw;
    double fh(double v) => sh * v / _dh;

    return SizedBox(
      width: sw,
      height: sh,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Card background  canvas X=44, Y=0 ──────────────────────────
          Positioned(
            left: fw(44),
            top: 0,
            child: SvgPicture.asset(
              'assets/Card Background.svg',
              width: fw(609),
              height: fh(1222),
              fit: BoxFit.fill,
            ),
          ),

          // ── Placeholder / job image  canvas X=94, Y=39 ─────────────────
          Positioned(
            left: fw(94),
            top: fh(39),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(fw(10)),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: fw(580),
                      height: fh(498),
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'assets/images/default-placeholder.png',
                      width: fw(580),
                      height: fh(498),
                      fit: BoxFit.cover,
                    ),
            ),
          ),

          // ── Opportunity-type badge (ot.svg)  canvas X=103, Y=53 ────────
          Positioned(
            left: fw(103),
            top: fh(53),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SvgPicture.asset(
                  'assets/ot.svg',
                  width: fw(170),
                  height: fh(41),
                  fit: BoxFit.fill,
                ),
                Text(
                  opportunityType.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: fw(14),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // ── Userbox (creator badge)  canvas X=444, Y=39 ────────────────
          Positioned(
            left: fw(444),
            top: fh(39),
            child: SvgPicture.asset(
              'assets/userbox.svg',
              width: fw(230),
              height: fh(140),
              fit: BoxFit.fill,
            ),
          ),

          // ── Top navbar  logo at canvas X=82, Y=42 ──────────────────────
          Positioned(
            left: fw(82),
            top: fh(42),
            child: SizedBox(
              width: fw(584),
              height: fh(61),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: SvgPicture.asset(
                      'assets/Lagcon.svg',
                      width: fw(205),
                      height: fh(61),
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    left: fw(473),
                    top: fh(16),
                    child: SvgPicture.asset(
                      'assets/filters.svg',
                      width: fw(35),
                      height: fh(32),
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    left: fw(548),
                    top: fh(12),
                    child: SvgPicture.asset(
                      'assets/noti.svg',
                      width: fw(36),
                      height: fh(39),
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Location row  canvas X=107, Y=765 ──────────────────────────
          Positioned(
            left: fw(107),
            top: fh(765),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/location.svg',
                  width: fw(18),
                  height: fh(24),
                  fit: BoxFit.contain,
                ),
                SizedBox(width: fw(8)),
                Text(
                  'Opportunity Location: $location',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF555555),
                    fontSize: fw(20),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // ── Button Group  canvas X=92, Y=1272 ──────────────────────────
          Positioned(
            left: fw(92),
            top: fh(1272),
            child: SvgPicture.asset(
              'assets/Button Group.svg',
              width: fw(582),
              height: fh(133),
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
  }
}
