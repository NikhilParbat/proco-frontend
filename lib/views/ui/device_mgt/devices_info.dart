import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/login_provider.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceManagement extends StatefulWidget {
  const DeviceManagement({super.key});

  @override
  State<DeviceManagement> createState() => _DeviceManagementState();
}

class _DeviceManagementState extends State<DeviceManagement> {
  String _currentSessionId = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentSession();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoginNotifier>().loadDeviceSessions();
    });
  }

  Future<void> _loadCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentSessionId = prefs.getString('deviceSessionId') ?? '';
      });
    }
  }

  IconData _deviceIcon(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('ios') || p.contains('iphone') || p.contains('ipad')) {
      return Icons.phone_iphone;
    } else if (p.contains('android')) {
      return Icons.phone_android;
    } else if (p.contains('mac') || p.contains('windows') || p.contains('linux')) {
      return Icons.computer;
    } else if (p.contains('web')) {
      return Icons.language;
    }
    return Icons.devices;
  }

  String _formatLastActive(String date) {
    if (date.isEmpty) return 'Unknown';
    try {
      final d = DateTime.parse(date);
      final diff = DateTime.now().difference(d);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
      return '${(diff.inDays / 30).floor()} months ago';
    } catch (_) {
      return date;
    }
  }

  void _showLogoutConfirm(LoginNotifier notifier, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Log Out Device?',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16.sp),
        ),
        content: Text(
          'This device will be signed out of your account.',
          style: GoogleFonts.dmSans(fontSize: 13.sp, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(color: Colors.black45, fontSize: 13.sp),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.removeDeviceSession(index);
            },
            child: Text(
              'Log Out',
              style: GoogleFonts.dmSans(
                color: kThemeColor,
                fontWeight: FontWeight.w700,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutAllConfirm(LoginNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Log Out of All Devices?',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16.sp),
        ),
        content: Text(
          'This will sign you out of all sessions, including this one.',
          style: GoogleFonts.dmSans(fontSize: 13.sp, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(color: Colors.black45, fontSize: 13.sp),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.logout();
            },
            child: Text(
              'Log Out',
              style: GoogleFonts.dmSans(
                color: kThemeColor,
                fontWeight: FontWeight.w700,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: const LagoonAppBar(),
      body: SafeArea(
        child: Consumer<LoginNotifier>(
          builder: (context, notifier, _) {
            final sessions = notifier.deviceSessions;

            DeviceSession? activeSession;
            List<DeviceSession> inactiveSessions = [];
            List<int> inactiveIndices = [];

            for (int i = 0; i < sessions.length; i++) {
              if (sessions[i].sessionId == _currentSessionId && activeSession == null) {
                activeSession = sessions[i];
              } else {
                inactiveSessions.add(sessions[i]);
                inactiveIndices.add(i);
              }
            }

            // Fallback: treat first session as active if current sessionId not matched
            if (activeSession == null && sessions.isNotEmpty) {
              activeSession = sessions.first;
              inactiveSessions = sessions.skip(1).toList();
              inactiveIndices = List.generate(inactiveSessions.length, (i) => i + 1);
            }

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    children: [
                      SizedBox(height: 16.h),

                      // Back button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.07),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chevron_left, size: 18.sp, color: Colors.black87),
                                SizedBox(width: 2.w),
                                Text(
                                  'Back',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Title — Montserrat
                      Text(
                        'Devices & Sessions',
                        style: GoogleFonts.montserrat(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Manage where you\'re logged into your Lagoon account.',
                        style: GoogleFonts.dmSans(
                          fontSize: 13.sp,
                          color: Colors.black45,
                          height: 1.45,
                        ),
                      ),
                      SizedBox(height: 28.h),

                      // Active session
                      if (activeSession != null) ...[
                        _sectionLabel('ACTIVE SESSION'),
                        SizedBox(height: 10.h),
                        Builder(builder: (context) {
                          final active = activeSession!;
                          return _SessionCard(
                            session: active,
                            isActive: true,
                            lastActiveText: '',
                            deviceIcon: _deviceIcon(active.platform),
                            onLogOut: () => _showLogoutConfirm(
                              notifier,
                              sessions.indexOf(active),
                            ),
                          );
                        }),
                        SizedBox(height: 24.h),
                      ],

                      // Inactive sessions
                      if (inactiveSessions.isNotEmpty) ...[
                        _sectionLabel('INACTIVE SESSIONS'),
                        SizedBox(height: 10.h),
                        ...List.generate(inactiveSessions.length, (i) {
                          final session = inactiveSessions[i];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: _SessionCard(
                              session: session,
                              isActive: false,
                              lastActiveText: _formatLastActive(session.date),
                              deviceIcon: _deviceIcon(session.platform),
                              onLogOut: () => _showLogoutConfirm(
                                notifier,
                                inactiveIndices[i],
                              ),
                            ),
                          );
                        }),
                      ],

                      if (sessions.isEmpty) ...[
                        SizedBox(height: 48.h),
                        Center(
                          child: Text(
                            'No device sessions found',
                            style: GoogleFonts.dmSans(
                              fontSize: 14.sp,
                              color: Colors.black38,
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: 20.h),

                      // Footer info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14.sp, color: Colors.black38),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              'Sessions expire automatically after 30 days of inactivity.',
                              style: GoogleFonts.dmSans(
                                fontSize: 12.sp,
                                color: Colors.black38,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),

                // Log Out of All Devices
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showLogoutAllConfirm(notifier),
                          icon: Icon(Icons.logout_rounded, color: Colors.white, size: 18.sp),
                          label: Text(
                            'Log Out of All Devices',
                            style: GoogleFonts.dmSans(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kThemeColor,
                            padding: EdgeInsets.symmetric(vertical: 15.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'This will sign you out of all sessions including this one.',
                        style: GoogleFonts.dmSans(
                          fontSize: 11.sp,
                          color: Colors.black38,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        color: Colors.black38,
        letterSpacing: 0.9,
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final DeviceSession session;
  final bool isActive;
  final String lastActiveText;
  final IconData deviceIcon;
  final VoidCallback onLogOut;

  const _SessionCard({
    required this.session,
    required this.isActive,
    required this.lastActiveText,
    required this.deviceIcon,
    required this.onLogOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(deviceIcon, size: 22.sp, color: Colors.black54),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.device,
                  style: GoogleFonts.dmSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  session.platform,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.sp,
                    color: Colors.black45,
                  ),
                ),
                if (isActive) ...[
                  SizedBox(height: 6.h),
                  _ActiveBadge(),
                ] else ...[
                  SizedBox(height: 3.h),
                  Text(
                    'Last active: $lastActiveText',
                    style: GoogleFonts.dmSans(
                      fontSize: 11.sp,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          OutlinedButton(
            onPressed: onLogOut,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.black26, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Log Out',
              style: GoogleFonts.dmSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF34C759),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 5.w),
        Text(
          'Active Session',
          style: GoogleFonts.dmSans(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Color(0xFF34C759),
          ),
        ),
      ],
    );
  }
}
