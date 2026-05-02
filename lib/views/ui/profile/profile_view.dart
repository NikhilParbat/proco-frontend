import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'profile_state.dart';

class ProfileViewTab extends StatelessWidget {
  const ProfileViewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfileEditState>();
    final location = [
      state.city,
      state.state,
      state.country,
    ].where((s) => s.isNotEmpty).join(', ');

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40.w,
            backgroundImage: NetworkImage(state.profileImageUrl),
          ),
          SizedBox(height: 20.h),

          // Abstraction: One function call handles visibility and layout
          _conditionalTile(state.showEmail, Icons.email, "Email", state.email),
          _conditionalTile(state.showPhone, Icons.phone, "Phone", state.phone),
          _conditionalTile(true, Icons.location_on, "Location", location),

          if (state.showSkills && state.skills.isNotEmpty)
            _buildSkills(state.skills),

          if (state.showLinkedIn && state.linkedInUrl.isNotEmpty)
            _socialRow(Icons.link, "LinkedIn", state.linkedInUrl),
        ],
      ),
    );
  }

  Widget _conditionalTile(
    bool show,
    IconData icon,
    String label,
    String value,
  ) {
    if (!show || value.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0BBFCA), size: 18),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkills(List<String> skills) {
    return Wrap(
      spacing: 8,
      children: skills.map((s) => Chip(label: Text(s))).toList(),
    );
  }

  Widget _socialRow(IconData icon, String label, String url) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0BBFCA)),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () => launchUrl(Uri.parse(url)),
    );
  }
}
