import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/services/helpers/notification_helper.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/common/lagoon_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late List<NotificationItem> _notifications;
  int _selectedTab = 0;
  bool _initialized = false;

  static const List<String> _tabLabels = ['All', 'Matches', 'Messages'];

  @override
  void initState() {
    super.initState();
    _notifications = List.from(NotificationHelper.notifications);
    NotificationHelper.addListener(_onUpdated);
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    if (_initialized) return;
    await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final token = prefs.getString('token') ?? '';
    if (userId.isNotEmpty && token.isNotEmpty) {
      await NotificationHelper.initialize(userId, token);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    NotificationHelper.removeListener(_onUpdated);
    super.dispose();
  }

  void _onUpdated() {
    if (mounted) {
      setState(() {
        _notifications = List.from(NotificationHelper.notifications);
      });
    }
  }

  String _typeOf(NotificationItem n) {
    final type = n.data['type'] as String? ?? '';
    if (type == 'match') return 'match';
    if (type == 'chat') return 'chat';
    final title = n.title.toLowerCase();
    if (title.contains('match')) return 'match';
    if (title.contains('message')) return 'chat';
    return 'other';
  }

  List<NotificationItem> get _filtered {
    switch (_selectedTab) {
      case 1:
        return _notifications.where((n) => _typeOf(n) == 'match').toList();
      case 2:
        return _notifications.where((n) => _typeOf(n) == 'chat').toList();
      default:
        return _notifications;
    }
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return '1d ago';
    return '${diff.inDays}d ago';
  }

  void _markRead(NotificationItem n) {
    final globalIndex = NotificationHelper.notifications.indexOf(n);
    if (globalIndex >= 0) {
      NotificationHelper.markAsRead(globalIndex);
      setState(() {
        _notifications = List.from(NotificationHelper.notifications);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      drawer: const LagoonDrawer(),
      appBar: const LagoonAppBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 0),
              child: Text(
                'Notifications',
                style: GoogleFonts.montserrat(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Filter tabs
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: List.generate(_tabLabels.length, (i) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: i < _tabLabels.length - 1 ? 8.w : 0,
                    ),
                    child: _TabChip(
                      label: _tabLabels[i],
                      selected: _selectedTab == i,
                      onTap: () => setState(() => _selectedTab = i),
                    ),
                  );
                }),
              ),
            ),

            SizedBox(height: 20.h),

            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 90.w,
                            height: 90.w,
                            decoration: BoxDecoration(
                              color: kThemeColor.withOpacity(0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_none_rounded,
                              size: 42.w,
                              color: kThemeColor,
                            ),
                          ),

                          SizedBox(height: 18.h),

                          Text(
                            'No notifications yet',
                            style: TextStyle(
                              fontFamily: kFontDMSans,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),

                          SizedBox(height: 6.h),

                          Text(
                            'You’ll see updates and activity here',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: kFontDMSans,
                              fontSize: 13.sp,
                              color: Colors.grey,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                      itemCount: filtered.length,
                      separatorBuilder: (context, i) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final n = filtered[index];

                        return GestureDetector(
                          onTap: () => _markRead(n),
                          child: _NotifCard(
                            title: n.title,
                            body: n.body,
                            timeAgo: _timeAgo(n.time),
                            type: _typeOf(n),
                            isUnread: !n.isRead,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? kThemeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? kThemeColor : Colors.black26,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13.sp,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final String title;
  final String body;
  final String timeAgo;
  final String type;
  final bool isUnread;

  const _NotifCard({
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.type,
    required this.isUnread,
  });

  bool get _isTyped => type == 'match' || type == 'chat';

  IconData get _icon {
    if (type == 'match') return Icons.favorite_rounded;
    if (type == 'chat') return Icons.chat_bubble_rounded;
    final t = title.toLowerCase();
    if (t.contains('application') ||
        t.contains('update') ||
        t.contains('job')) {
      return Icons.business_center_rounded;
    }
    if (t.contains('profile') || t.contains('view')) {
      return Icons.remove_red_eye_rounded;
    }
    return Icons.notifications_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: isUnread ? Border.all(color: kThemeColor, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isUnread ? 0.07 : 0.04),
            blurRadius: isUnread ? 14 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: _isTyped ? kThemeColor : const Color(0xFFEEEEEE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _icon,
              color: _isTyped ? Colors.white : Colors.black54,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  body,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.sp,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6.h),
                Text(
                  timeAgo,
                  style: GoogleFonts.dmSans(
                    fontSize: 11.sp,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
