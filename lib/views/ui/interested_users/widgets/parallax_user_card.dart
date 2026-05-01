import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/models/response/jobs/swipe_res_model.dart';

import 'user_card_content.dart';

/// Parallax preview card used inside the PageView carousel.
/// Tapping anywhere on the card calls [onTap] to open the swipe page.
class ParallaxUserCard extends StatelessWidget {
  final SwipedRes user;
  final double pageOffset;
  final VoidCallback onTap;

  static const Color _teal = Color(0xFF08979F);

  const ParallaxUserCard({
    super.key,
    required this.user,
    required this.pageOffset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Gaussian curve peaks when the adjacent card is half-visible,
    // producing the smooth horizontal "push" parallax translation.
    final double gauss = math.exp(
      -(math.pow((pageOffset.abs() - 0.5), 2) / 0.08),
    );

    return Transform.translate(
      offset: Offset(-32 * gauss * pageOffset.sign, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(left: 8, right: 8, bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                offset: const Offset(8, 20),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            children: [
              // Parallax photo — focal point shifts with pageOffset
              ClipRRect(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(32.r)),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  width: double.infinity,
                  child: user.profile.isNotEmpty
                      ? Image.network(
                          user.profile,
                          fit: BoxFit.cover,
                          alignment: Alignment(pageOffset * 0.4, 0),
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              // Name / location / skills preview
              Expanded(child: UserCardContent(user: user)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: _teal.withValues(alpha: 0.10),
        child: const Center(
          child: Icon(Icons.person_rounded, color: _teal, size: 64),
        ),
      );
}
