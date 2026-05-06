import 'package:flutter/material.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proco/controllers/chat_provider.dart';
import 'package:proco/models/request/messaging/send_message.dart';
import 'package:proco/models/response/messaging/messaging_res.dart';
import 'package:proco/services/config.dart' as cfg;
import 'package:proco/models/response/jobs/swipe_res_model.dart';
import 'package:proco/services/helpers/messaging_helper.dart';
import 'package:proco/views/common/exports.dart';
import 'package:proco/views/ui/interested_users/user_detail_page.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

// Same palette as the onboarding chat
const _kSentBubble = kThemeColor;
const _kRecvBubble = Color.fromARGB(200, 216, 87, 87);

class ChatPage extends StatefulWidget {
  const ChatPage({
    required this.title,
    required this.id,
    required this.profile,
    required this.user,
    this.isUnmatched = false,
    super.key,
  });

  final String title;
  final String id;
  final String profile;
  final List<String> user;
  final bool isUnmatched;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static const Color _bgChat = Color(0xFFF4F6FA);

  int offset = 1;
  io.Socket? socket;
  late Future<List<ReceivedMessage>> msgList;
  List<ReceivedMessage> messages = [];
  final Set<String> _loadedMessageIds = {};
  bool _initialLoadDone = false;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _socketNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _sendingNotifier = ValueNotifier(false);

  String receiver = '';

  @override
  void initState() {
    super.initState();
    getMessages(offset);
    connect();
    joinChat();
    _handlePagination();
  }

  @override
  void dispose() {
    if (socket != null) {
      socket!.emit('leave chat', widget.id);
      socket!.disconnect();
      socket!.dispose();
      socket = null;
    }
    _socketNotifier.value = false;
    _scrollController.dispose();
    _messageController.dispose();
    _sendingNotifier.dispose();
    super.dispose();
  }

  // ─── Data ─────────────────────────────────────────────────────────────────
  void getMessages(int offset) {
    msgList = MesssagingHelper.getMessages(widget.id, offset);
  }

  void _handlePagination() {
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          messages.length >= 12) {
        offset++;
        getMessages(offset);
        setState(() {});
      }
    });
  }

  void _mergeMessages(List<ReceivedMessage> fetched) {
    for (final msg in fetched) {
      if (!_loadedMessageIds.contains(msg.id)) {
        _loadedMessageIds.add(msg.id);
        messages.add(msg);
      }
    }
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  // ─── Socket ───────────────────────────────────────────────────────────────
  void connect() async {
    if (socket != null) {
      socket!.disconnect();
      socket!.dispose();
      socket = null;
    }

    final chatNotifier = context.read<ChatNotifier>();

    socket = io.io(
      cfg.Config.socketUrl(),
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNewConnection()
          .build(),
    );

    socket!.connect();

    socket!.onConnect((_) {
      _socketNotifier.value = true;
      socket!.emit('setup', chatNotifier.userId);
      socket!.on(
        'online-users',
        (users) => chatNotifier.onlineUsers = List<String>.from(users),
      );
      socket!.on('typing', (_) => chatNotifier.typingStatus = true);
      socket!.on('stop typing', (_) => chatNotifier.typingStatus = false);
      socket!.on('message received', (data) {
        final msg = ReceivedMessage.fromJson(data);
        if (msg.senderId != chatNotifier.userId &&
            !_loadedMessageIds.contains(msg.id)) {
          _loadedMessageIds.add(msg.id);
          setState(() {
            messages.add(msg);
            messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          });
          _scrollToBottom();
        }
      });
    });

    socket!.onDisconnect((_) => debugPrint('SOCKET DISCONNECTED'));
    socket!.onError((e) => debugPrint('SOCKET ERROR: $e'));
  }

  // ─── Messaging ────────────────────────────────────────────────────────────
  Future<void> _sendMessage(String content, String chatId, String recv) async {
    if (content.trim().isEmpty) return;
    _sendingNotifier.value = true;

    final result = await MesssagingHelper.sendMessage(
      SendMessage(content: content, chatId: chatId),
    );

    _sendingNotifier.value = false;

    if (result['success']) {
      final message = result['message'] as ReceivedMessage;
      if (!_loadedMessageIds.contains(message.id)) {
        _loadedMessageIds.add(message.id);
        setState(() {
          messages.add(message);
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          _messageController.clear();
        });
      } else {
        setState(() => _messageController.clear());
      }
      _scrollToBottom();
      socket?.emit('new message', message.toJson());
      socket?.emit('stop typing', widget.id);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendTyping() => socket?.emit('typing', widget.id);
  void _stopTyping() => socket?.emit('stop typing', widget.id);
  void joinChat() => socket?.emit('join chat', widget.id);

  // ─── Options menu ─────────────────────────────────────────────────────────
  void _showOptions(BuildContext context) {
    final chatNotifier = context.read<ChatNotifier>();
    final pinned = chatNotifier.isPinned(widget.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
              child: Text(
                'Chat Options',
                style: GoogleFonts.dmSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            const Divider(height: 1),

            // Pin / Unpin
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kThemeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: kThemeColor,
                  size: 20,
                ),
              ),
              title: Text(
                pinned ? 'Unpin Chat' : 'Pin Chat',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF040326),
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                pinned ? 'Remove from pinned conversations' : 'Keep this chat at the top',
                style: GoogleFonts.dmSans(fontSize: 12, color: Colors.grey.shade400),
              ),
              onTap: () {
                Navigator.pop(context);
                chatNotifier.togglePin(widget.id);
              },
            ),

            // Clear Chat
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cleaning_services_rounded, color: Colors.orange, size: 20),
              ),
              title: Text(
                'Clear Chat',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: Colors.orange, fontSize: 15),
              ),
              subtitle: Text(
                'Delete all messages for both users',
                style: GoogleFonts.dmSans(fontSize: 12, color: Colors.grey.shade400),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmClear(context);
              },
            ),

            // Unmatch
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_remove_outlined, color: Colors.redAccent, size: 20),
              ),
              title: Text(
                'Unmatch',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: Colors.redAccent, fontSize: 15),
              ),
              subtitle: Text(
                'Remove this match and block messaging',
                style: GoogleFonts.dmSans(fontSize: 12, color: Colors.grey.shade400),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear Chat', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Text(
          'All messages will be permanently deleted for both users. This cannot be undone.',
          style: GoogleFonts.dmSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: Colors.grey.shade500)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<ChatNotifier>().clearChat(widget.id);
              setState(() => messages.clear());
            },
            child: Text('Clear', style: GoogleFonts.dmSans(color: Colors.orange, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Unmatch', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Text(
          'This will remove your match. They will no longer be able to message you.',
          style: GoogleFonts.dmSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: Colors.grey.shade500)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context);
              await context.read<ChatNotifier>().unmatchChat(widget.id);
            },
            child: Text('Unmatch', style: GoogleFonts.dmSans(color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<ChatNotifier>(
      builder: (context, chatNotifier, child) {
        receiver = widget.user.isNotEmpty ? widget.user[0] : '';
        final isOnline = chatNotifier.online.contains(receiver);

        return Scaffold(
          backgroundColor: _bgChat,
          appBar: _buildAppBar(chatNotifier, isOnline),
          body: SafeArea(
            child: Column(
              children: [
                // ── Messages ────────────────────────────────────────────────
                Expanded(
                  child: FutureBuilder<List<ReceivedMessage>>(
                    future: msgList,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: kThemeColor),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error ${snapshot.error}',
                            style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 14.sp),
                          ),
                        );
                      } else {
                        if (!_initialLoadDone && snapshot.data != null) {
                          _initialLoadDone = true;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() => _mergeMessages(snapshot.data!));
                          });
                        } else if (snapshot.data != null) {
                          _mergeMessages(snapshot.data!);
                        }

                        if (messages.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 52,
                                  color: kThemeColor.withValues(alpha: 0.25),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  'No messages yet',
                                  style: GoogleFonts.dmSans(fontSize: 15.sp, color: Colors.grey),
                                ),
                                Text(
                                  'Say hello 👋',
                                  style: GoogleFonts.dmSans(fontSize: 13.sp, color: Colors.grey.shade400),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 6.h),
                          itemCount: messages.length,
                          reverse: true,
                          controller: _scrollController,
                          itemBuilder: (context, index) {
                            if (messages.isEmpty) return const SizedBox();

                            final reversedIndex = messages.length - 1 - index;
                            if (reversedIndex < 0 || reversedIndex >= messages.length) {
                              return const SizedBox();
                            }

                            final data = messages[reversedIndex];
                            final isMine = data.senderId == chatNotifier.userId;

                            bool showTime = index == messages.length - 1;
                            if (!showTime && index < messages.length - 1) {
                              final prev = messages[messages.length - 2 - index];
                              showTime = data.createdAt.difference(prev.createdAt).inMinutes.abs() > 5;
                            }

                            return _buildBubble(data, isMine, chatNotifier, showTime);
                          },
                        );
                      }
                    },
                  ),
                ),

                // ── Unmatched banner / Input bar ────────────────────────────
                if (widget.isUnmatched)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border(top: BorderSide(color: Colors.red.shade100)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.block_rounded, size: 16, color: Colors.red.shade400),
                        SizedBox(width: 8.w),
                        Text(
                          'You cannot message this person anymore',
                          style: GoogleFonts.dmSans(
                            fontSize: 13.sp,
                            color: Colors.red.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ValueListenableBuilder<bool>(
                    valueListenable: _socketNotifier,
                    builder: (context, connected, child) {
                      if (!connected) {
                        return const SizedBox(
                          height: 3,
                          child: LinearProgressIndicator(color: kThemeColor),
                        );
                      }
                      return _buildInputBar();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Profile navigation ───────────────────────────────────────────────────
  void _openProfile() {
    final userId = widget.user.isNotEmpty ? widget.user[0] : receiver;
    if (userId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserDetailPage(
          user: SwipedRes(
            id: userId,
            username: widget.title,
            profile: widget.profile,
            location: '',
            skills: const [],
          ),
          jobId: '',
          onMatch: () async {},
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(ChatNotifier chatNotifier, bool isOnline) {
    return PreferredSize(
      preferredSize: Size.fromHeight(64.h),
      child: AppBar(
        backgroundColor: kThemeColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                  ),
                ),
                SizedBox(width: 10.w),

                // Avatar + name — tappable to view profile
                Expanded(
                  child: GestureDetector(
                    onTap: _openProfile,
                    child: Row(
                      children: [
                        // Avatar with online dot
                        Stack(
                          children: [
                            CircleAvatar(radius: 20.r, backgroundImage: NetworkImage(widget.profile)),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: isOnline ? const Color(0xFF4ADE80) : Colors.white38,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: kThemeColor, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 10.w),

                        // Name + typing / online status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.title,
                                style: GoogleFonts.dmSans(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                chatNotifier.typing ? 'typing...' : (isOnline ? 'Online' : 'Offline'),
                                style: GoogleFonts.dmSans(
                                  fontSize: 11.sp,
                                  color: chatNotifier.typing
                                      ? Colors.white70
                                      : (isOnline ? const Color(0xFF4ADE80) : Colors.white54),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Three-dot menu
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                  onPressed: () => _showOptions(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Message bubble ───────────────────────────────────────────────────────
  Widget _buildBubble(
    ReceivedMessage data,
    bool isMine,
    ChatNotifier chatNotifier,
    bool showTime,
  ) {
    return Column(
      children: [
        if (showTime)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                chatNotifier.msgTime(data.createdAt.toString()),
                style: GoogleFonts.dmSans(fontSize: 11.sp, color: Colors.grey.shade600),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(bottom: 4.h),
          child: Row(
            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine) ...[
                CircleAvatar(
                  radius: 13.r,
                  backgroundImage: NetworkImage(widget.profile),
                ),
                SizedBox(width: 6.w),
              ],

              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isMine ? _kSentBubble : _kRecvBubble,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  data.content,
                  style: GoogleFonts.dmSans(
                    fontSize: 14.sp,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ),

              if (isMine) SizedBox(width: 6.w),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Input bar ────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _bgChat,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kThemeColor.withValues(alpha: 0.25), width: 1),
              ),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.dmSans(fontSize: 14.sp, color: const Color(0xFF040326)),
                maxLines: null,
                maxLength: 1000,
                inputFormatters: [noEmojiFormatter],
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(_messageController.text, widget.id, receiver),
                onChanged: (_) => _sendTyping(),
                onTapOutside: (_) => _stopTyping(),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: GoogleFonts.dmSans(fontSize: 14.sp, color: Colors.grey.shade400),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),

          ValueListenableBuilder<bool>(
            valueListenable: _sendingNotifier,
            builder: (context, sending, child) => GestureDetector(
              onTap: sending
                  ? null
                  : () => _sendMessage(_messageController.text, widget.id, receiver),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: sending ? kThemeColor.withValues(alpha: 0.5) : kThemeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kThemeColor.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
