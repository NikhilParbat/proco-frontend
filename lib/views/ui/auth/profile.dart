import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
import 'package:proco/controllers/profile_provider.dart';
import 'package:proco/models/response/auth/profile_model.dart';
import 'package:proco/views/common/app_bar.dart';
import 'package:proco/views/common/drawer/drawer_widget.dart';
import 'package:proco/views/ui/auth/profile_update.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color _bg = Color(0xFF040326);
  static const Color _card = Color(0xFF08979F);
  static const Color _accent = Color(0xFF0BBFCA);
  static const Color _white = Colors.white;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ProfileNotifier>().getProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0.065.sh),
        child: CustomAppBar(
          text: 'Profile',
          child: Padding(
            padding: EdgeInsets.only(left: 0.010.sh),
            child: const DrawerWidget(),
          ),
        ),
      ),
      body: Consumer<ProfileNotifier>(
        builder: (context, profileNotifier, child) {
          return FutureBuilder<ProfileRes?>(
            future: profileNotifier.profile,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: _accent),
                );
              } else if (snapshot.hasError) {
                return _buildErrorView('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data == null) {
                return _buildErrorView('No profile data available');
              }
              return _buildProfile(snapshot.data!);
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 60,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(ProfileRes userData) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(userData),
          SizedBox(height: 24.h),

          _sectionLabel('Personal Info'),
          SizedBox(height: 12.h),
          _infoTile(Icons.email_outlined, 'Email', userData.email),
          SizedBox(height: 12.h),
          _infoTile(
            Icons.phone_outlined,
            'Phone',
            userData.phone.isEmpty ? 'Not set' : userData.phone,
          ),
          SizedBox(height: 12.h),
          _infoTile(
            Icons.wc_outlined,
            'Gender',
            userData.gender.isEmpty ? 'Not set' : userData.gender,
          ),
          SizedBox(height: 20.h),

          // Location — reads from the nested location.city/state/country fields
          _sectionLabel('Location'),
          SizedBox(height: 12.h),
          _buildLocationSection(userData),
          SizedBox(height: 20.h),

          _sectionLabel('Education'),
          SizedBox(height: 12.h),
          _infoTile(
            Icons.apartment_outlined,
            'College',
            userData.college.isEmpty ? 'Not set' : userData.college,
          ),
          SizedBox(height: 12.h),
          _infoTile(
            Icons.school_outlined,
            'Branch',
            userData.branch.isEmpty ? 'Not set' : userData.branch,
          ),
          SizedBox(height: 20.h),

          _sectionLabel('Skills'),
          SizedBox(height: 12.h),
          _buildSkillsSection(userData.skills),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  /// Renders city / state / country individually, or a single "Not set" tile.
  Widget _buildLocationSection(ProfileRes userData) {
    final bool hasCity = userData.city.isNotEmpty;
    final bool hasState = userData.state.isNotEmpty;
    final bool hasCountry = userData.country.isNotEmpty;

    if (!hasCity && !hasState && !hasCountry) {
      return _infoTile(Icons.location_on_outlined, 'Location', 'Not set');
    }

    return Column(
      children: [
        if (hasCity) ...[
          _infoTile(Icons.location_city_outlined, 'City', userData.city),
          SizedBox(height: 12.h),
        ],
        if (hasState) ...[
          _infoTile(Icons.map_outlined, 'State', userData.state),
          SizedBox(height: 12.h),
        ],
        if (hasCountry)
          _infoTile(Icons.flag_outlined, 'Country', userData.country),
      ],
    );
  }

  Widget _buildProfileHeader(ProfileRes userData) {
    final locationString = [
      userData.city,
      userData.state,
      userData.country,
    ].where((p) => p.isNotEmpty).join(', ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _accent, width: 2),
          ),
          child: ClipOval(
            child: userData.profile == 'null' || userData.profile.isEmpty
                ? Image.asset('assets/images/user.png', fit: BoxFit.cover)
                : CachedNetworkImage(
                    imageUrl: userData.profile,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/images/user.png',
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                userData.username,
                style: TextStyle(
                  color: _white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (locationString.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: _accent, size: 13),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        locationString,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: 8.w),
        GestureDetector(
          onTap: () => Get.to(() => const UpdateProfilePage()),
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: _card.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _card.withValues(alpha: 0.4)),
            ),
            child: const Icon(Feather.edit, color: _white, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            color: _accent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 4.h),
        Container(height: 1, color: _card.withValues(alpha: 0.5)),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: _card.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _card.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(icon, color: _accent, size: 20),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'Not set' : value,
                  style: const TextStyle(
                    color: _white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(List<String> skills) {
    if (skills.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.h),
        decoration: BoxDecoration(
          color: _card.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _card.withValues(alpha: 0.3)),
        ),
        child: const Text(
          'No skills added yet',
          style: TextStyle(color: Colors.white38, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.h),
      decoration: BoxDecoration(
        color: _card.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _card.withValues(alpha: 0.3)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: skills.map((skill) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              skill,
              style: const TextStyle(
                color: _white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
