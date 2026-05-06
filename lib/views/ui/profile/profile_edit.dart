import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/views/common/lagoon_drawer.dart';
import 'package:provider/provider.dart';

import 'profile_state.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileEditState(),
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        drawer: const LagoonDrawer(),
        appBar: AppBar(
          backgroundColor: kThemeColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: kLight, size: 18),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Edit Profile',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: kLight,
            ),
          ),
        ),
        body: Consumer<ProfileEditState>(
          builder: (context, state, _) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: kThemeColor),
              );
            }
            return _EditForm(state: state);
          },
        ),
      ),
    );
  }
}

class _EditForm extends StatelessWidget {
  const _EditForm({required this.state});
  final ProfileEditState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 40.h),
      children: [
        // ── Basic Info ────────────────────────────────────────────────────────
        _SectionTitle(title: 'Basic Info'),
        _Field(label: 'Full Name', init: state.username, onChanged: (v) => state.username = v),
        _Field(label: 'Phone Number', init: state.phone, onChanged: (v) => state.phone = v, keyboard: TextInputType.phone),
        _Field(label: 'Gender', init: state.gender, onChanged: (v) => state.gender = v),
        _Field(label: 'Date of Birth', init: state.dob, onChanged: (v) => state.dob = v, hint: 'YYYY-MM-DD'),

        SizedBox(height: 8.h),

        // ── Education ─────────────────────────────────────────────────────────
        _SectionTitle(title: 'Education'),
        _Field(label: 'Institution / College', init: state.college, onChanged: (v) => state.college = v),
        _Field(label: 'Degree / Branch', init: state.branch, onChanged: (v) => state.branch = v),

        SizedBox(height: 8.h),

        // ── Location ──────────────────────────────────────────────────────────
        _SectionTitle(title: 'Location'),
        _Field(label: 'City', init: state.city, onChanged: (v) => state.city = v),
        _Field(label: 'State', init: state.state, onChanged: (v) => state.state = v),
        _Field(label: 'Country', init: state.country, onChanged: (v) => state.country = v),

        SizedBox(height: 8.h),

        // ── Skills, Interests, Hobbies ────────────────────────────────────────
        _SectionTitle(title: 'Skills & Interests'),
        _ListField(label: 'Skills', values: state.skills, onChanged: (v) => state.skills = v),
        _ListField(label: 'Interests', values: state.interests, onChanged: (v) => state.interests = v),
        _ListField(label: 'Hobbies', values: state.hobbies, onChanged: (v) => state.hobbies = v),

        SizedBox(height: 8.h),

        // ── Social Links ──────────────────────────────────────────────────────
        _SectionTitle(title: 'Social Links'),
        _Field(label: 'LinkedIn URL', init: state.linkedInUrl, onChanged: (v) => state.linkedInUrl = v, keyboard: TextInputType.url),
        _Field(label: 'GitHub URL', init: state.gitHubUrl, onChanged: (v) => state.gitHubUrl = v, keyboard: TextInputType.url),
        _Field(label: 'Twitter / X URL', init: state.twitterUrl, onChanged: (v) => state.twitterUrl = v, keyboard: TextInputType.url),
        _Field(label: 'Portfolio / Behance URL', init: state.portfolioUrl, onChanged: (v) => state.portfolioUrl = v, keyboard: TextInputType.url),

        SizedBox(height: 28.h),

        // ── Save button ───────────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: Consumer<ProfileEditState>(
            builder: (context, s, _) => ElevatedButton(
              onPressed: s.isSaving
                  ? null
                  : () async {
                      final ok = await s.saveProfile(null);
                      if (ok && context.mounted) {
                        Get.snackbar(
                          'Profile Saved',
                          'Your profile has been updated.',
                          backgroundColor: kTeal,
                          colorText: kLight,
                          duration: const Duration(seconds: 3),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: kThemeColor,
                disabledBackgroundColor: kThemeColor.withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: s.isSaving
                  ? SizedBox(
                      width: 22.w,
                      height: 22.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: kLight,
                      ),
                    )
                  : Text(
                      'SAVE CHANGES',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: kLight,
                        letterSpacing: 1.2,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reusable form widgets ──────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, top: 4.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: kDarkGrey,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.init,
    required this.onChanged,
    this.hint,
    this.keyboard,
  });

  final String label;
  final String init;
  final ValueChanged<String> onChanged;
  final String? hint;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: TextFormField(
        initialValue: init,
        keyboardType: keyboard,
        onChanged: onChanged,
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 14.sp,
          color: kDark,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 13.sp,
            color: kDarkGrey,
          ),
          hintStyle: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 13.sp,
            color: const Color(0xFFBBBBBB),
          ),
          filled: true,
          fillColor: kLight,
          contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: kThemeColor, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _ListField extends StatelessWidget {
  const _ListField({
    required this.label,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Field(
      label: '$label (comma-separated)',
      init: values.join(', '),
      onChanged: (v) => onChanged(
        v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      ),
    );
  }
}
