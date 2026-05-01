import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/controllers/exports.dart';
import 'package:proco/models/response/jobs/swipe_res_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_swipe_page.dart';
import 'widgets/parallax_user_card.dart';

class InterestedUsersScreen extends StatefulWidget {
  const InterestedUsersScreen({super.key});

  @override
  State<InterestedUsersScreen> createState() => _InterestedUsersScreenState();
}

class _InterestedUsersScreenState extends State<InterestedUsersScreen> {
  static const Color _bg = Color(0xFFF7F7F7);
  static const Color _navy = Color(0xFF040326);
  static const Color _teal = Color(0xFF08979F);

  late final PageController _pageController;
  String _jobId = '';
  List<SwipedRes> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // viewportFraction < 1 lets adjacent cards peek from the sides,
    // which is required for the parallax offset to be visible.
    _pageController = PageController(viewportFraction: 0.82);
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _jobId = prefs.getString('currentJobId') ?? '';
    if (!mounted) return;
    final notifier = Provider.of<JobsNotifier>(context, listen: false);
    await notifier.getSwipedUsersId(_jobId);
    if (!mounted) return;
    setState(() {
      _users = List.from(notifier.swipedUsers);
      _loading = false;
    });
  }

  void _openSwipePage(SwipedRes user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserSwipePage(user: user, jobId: _jobId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? _buildLoader()
                  : _users.isEmpty
                      ? _buildEmpty()
                      : _buildParallaxCarousel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(6.w, 10.h, 20.w, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _navy,
              size: 20,
            ),
          ),
          SizedBox(width: 2.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Interested Users',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                _loading
                    ? 'Loading...'
                    : '${_users.length} interested in your query',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParallaxCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: PageView.builder(
            // Clip.none lets peeking cards render outside the PageView bounds.
            clipBehavior: Clip.none,
            controller: _pageController,
            itemCount: _users.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, _) {
                  double pageOffset = 0;
                  if (_pageController.position.haveDimensions) {
                    pageOffset = _pageController.page! - index;
                  }
                  return ParallaxUserCard(
                    user: _users[index],
                    pageOffset: pageOffset,
                    onTap: () => _openSwipePage(_users[index]),
                  );
                },
              );
            },
          ),
        ),
        SizedBox(height: 12.h),
        Center(
          child: Text(
            'Tap a card to view · swipe right to match',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoader() => const Center(
        child: CircularProgressIndicator(color: _teal, strokeWidth: 2.5),
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 60,
              color: _teal.withValues(alpha: 0.25),
            ),
            SizedBox(height: 16.h),
            Text(
              'No interested users yet.\nCheck back soon.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.grey,
                fontFamily: 'Poppins',
                height: 1.5,
              ),
            ),
          ],
        ),
      );
}
