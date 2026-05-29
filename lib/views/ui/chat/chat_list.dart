import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_assets.dart';
import 'package:proco/constants/app_colors.dart';
import 'package:proco/constants/app_text_styles.dart';
import 'package:proco/controllers/exports.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/common/lagoon_drawer.dart';
import 'package:proco/views/ui/chat/chat_page.dart';
import 'package:provider/provider.dart';

class ChatsList extends StatefulWidget {
  const ChatsList({super.key});

  @override
  State<ChatsList> createState() => _ChatsListState();
}

class _ChatsListState extends State<ChatsList> {
  @override
  void initState() {
    super.initState();

    final chatNotifier = context.read<ChatNotifier>();

    chatNotifier.getChats();
    chatNotifier.getPrefs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      drawer: const LagoonDrawer(),
      appBar: const LagoonAppBar(),

      body: Consumer<ChatNotifier>(
        builder: (context, chatNotifier, child) {
          if (chatNotifier.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: kThemeColor,
                strokeWidth: 2.6,
              ),
            );
          }

          if (chatNotifier.chats.isEmpty) {
            return _buildEmpty();
          }

          final chats = [...chatNotifier.chats]
            ..sort((a, b) {
              final aPinned = chatNotifier.isPinned(a.id) ? 0 : 1;

              final bPinned = chatNotifier.isPinned(b.id) ? 0 : 1;

              if (aPinned != bPinned) {
                return aPinned.compareTo(bPinned);
              }

              return b.updatedAt.compareTo(a.updatedAt);
            });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ── Header ─────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 16.h),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Messages',

                      style: TextStyle(
                        fontFamily: kFontMontserrat,

                        fontSize: 24.sp,

                        fontWeight: FontWeight.w700,

                        color: Colors.black87,
                      ),
                    ),

                    SizedBox(height: 4.h),

                    Text(
                      'Stay connected with your matches and opportunities.',

                      style: TextStyle(
                        fontFamily: kFontDMSans,

                        fontSize: 13.sp,

                        color: Colors.grey.shade600,

                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Chat List ───────────────────
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 24.h),

                  itemCount: chats.length,

                  separatorBuilder: (context, index) => SizedBox(height: 12.h),

                  itemBuilder: (context, index) {
                    final chat = chats[index];

                    final other = chat.users.isNotEmpty ? chat.users[0] : null;

                    final String name = other?.username ?? 'Unknown User';

                    final String profile = other?.profile ?? kDefaultImage;

                    final String preview =
                        chat.latestMessage?.isNotEmpty == true
                        ? chat.latestMessage!
                        : 'No messages yet';

                    final String time = chatNotifier.msgTime(
                      chat.createdAt.toString(),
                    );

                    final bool isOutgoing =
                        chat.chatName == chatNotifier.userId;

                    return GestureDetector(
                      onTap: () => Get.to(
                        () => ChatPage(
                          id: chat.id,
                          title: name,
                          profile: profile,
                          user: chat.users.map((u) => u.id).toList(),
                          isUnmatched: chat.isUnmatched,
                        ),
                      ),

                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),

                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 14.h,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.white,

                          borderRadius: BorderRadius.circular(24.r),

                          border: Border.all(
                            color: kThemeColor.withValues(alpha: 0.06),
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.035),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),

                        child: Row(
                          children: [
                            // ── Avatar ─────────────────────────
                            Stack(
                              children: [
                                Container(
                                  width: 62.w,
                                  height: 62.w,

                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,

                                    gradient: LinearGradient(
                                      colors: [
                                        kThemeColor.withValues(alpha: 0.14),
                                        kThemeColor.withValues(alpha: 0.06),
                                      ],
                                    ),
                                  ),

                                  padding: EdgeInsets.all(2.2.w),

                                  child: ClipOval(
                                    child: Image.network(
                                      profile,
                                      fit: BoxFit.cover,

                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: Colors.white,

                                                child: Icon(
                                                  Icons.person_rounded,
                                                  color: kThemeColor,
                                                  size: 28.sp,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),

                                // ── Online Dot ─────────────────
                                if (chatNotifier.online.contains(other?.id))
                                  Positioned(
                                    right: 3,
                                    bottom: 3,

                                    child: Container(
                                      width: 13.w,
                                      height: 13.w,

                                      decoration: BoxDecoration(
                                        color: const Color(0xFF25D366),
                                        shape: BoxShape.circle,

                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            SizedBox(width: 14.w),

                            // ── Main Content ───────────────────
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  // ── Name + Time ──────────────
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,

                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,

                                          style: TextStyle(
                                            fontFamily: kFontDMSans,
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),

                                      SizedBox(width: 8.w),

                                      Text(
                                        time,

                                        style: TextStyle(
                                          fontFamily: kFontDMSans,
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 8.h),

                                  // ── Message Preview ──────────
                                  Row(
                                    children: [
                                      Container(
                                        width: 20.w,
                                        alignment: Alignment.centerLeft,

                                        child: Icon(
                                          isOutgoing
                                              ? Icons.north_east_rounded
                                              : Icons.south_west_rounded,

                                          size: 15.sp,

                                          color: isOutgoing
                                              ? kThemeColor
                                              : Colors.grey.shade400,
                                        ),
                                      ),

                                      Expanded(
                                        child: Text(
                                          preview,

                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,

                                          style: TextStyle(
                                            fontFamily: kFontDMSans,
                                            fontSize: 12.8.sp,
                                            color: Colors.grey.shade700,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: 12.w),

                            // ── Right Actions ─────────────────
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [
                                if (chatNotifier.isPinned(chat.id))
                                  Container(
                                    padding: EdgeInsets.all(7.w),

                                    decoration: BoxDecoration(
                                      color: kThemeColor.withValues(
                                        alpha: 0.10,
                                      ),

                                      shape: BoxShape.circle,
                                    ),

                                    child: Icon(
                                      Icons.push_pin_rounded,
                                      size: 14.sp,
                                      color: kThemeColor,
                                    ),
                                  ),

                                SizedBox(height: 14.h),

                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 13.sp,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              width: 92.w,
              height: 92.w,

              decoration: BoxDecoration(
                color: kThemeColor.withValues(alpha: 0.10),

                shape: BoxShape.circle,
              ),

              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 42.w,
                color: kThemeColor,
              ),
            ),

            SizedBox(height: 20.h),

            Text(
              'No chats yet',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: 8.h),

            Text(
              'Start a conversation by applying to an opportunity.',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 13.sp,
                color: Colors.grey.shade600,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
