import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:proco/controllers/exports.dart';
import 'package:proco/services/helpers/user_helper.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  static const Color _navy = Color(0xFF040326);
  static const Color _card = Color(0xFF0D1B2A);
  static const Color _red = Color(0xFFD23838);

  bool _deleting = false;

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'Delete Account',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.white60,
            fontFamily: 'Poppins',
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white54,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: _red,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    final response = await UserHelper.deleteAccount();
    if (!mounted) return;
    setState(() => _deleting = false);

    if (response.success) {
      context.read<LoginNotifier>().logout();
    } else {
      Get.snackbar(
        'Error',
        response.message,
        backgroundColor: _red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Account',
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          child: GestureDetector(
            onTap: _deleting ? null : _confirmDelete,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: _red.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: _red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: _deleting
                        ? Padding(
                            padding: EdgeInsets.all(10.r),
                            child: const CircularProgressIndicator(
                              color: _red,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.delete_forever_rounded,
                            color: _red,
                            size: 22,
                          ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delete Account',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: _red,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          'Permanently remove your account and all data',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white38,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _red.withValues(alpha: 0.4),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
