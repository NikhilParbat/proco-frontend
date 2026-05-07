import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/views/common/lagoon_drawer.dart';
import 'package:proco/views/common/phone_field.dart';
import 'package:provider/provider.dart';
import 'profile_state.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ScrollController _scrollController = ScrollController();
  // Keys to identify section positions for scrolling
  final GlobalKey _identityKey = GlobalKey();
  final GlobalKey _personalKey = GlobalKey();
  final GlobalKey _educationKey = GlobalKey();
  final GlobalKey _professionalKey = GlobalKey();
  final GlobalKey _attributesKey = GlobalKey();

  void _scrollToSection(GlobalKey key) {
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileEditState(),
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        drawer: const LagoonDrawer(),
        appBar: AppBar(
          backgroundColor: kLight, // Matches design header
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: kDark, size: 18),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Back',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 14.sp,
              color: kDark,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(50.h),
            child: _CustomNavBar(
              onTap: (index) {
                if (index == 0) _scrollToSection(_identityKey);
                if (index == 1) _scrollToSection(_personalKey);
                if (index == 2) _scrollToSection(_educationKey);
                if (index == 3) _scrollToSection(_professionalKey);
                if (index == 4) _scrollToSection(_attributesKey);
              },
            ),
          ),
        ),
        // Floating Action Button as requested
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Consumer<ProfileEditState>(
          builder: (context, s, _) => Container(
            width: double.infinity,
            height: 52.h,
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            child: ElevatedButton(
              onPressed: s.isSaving ? null : () => s.saveProfile(null),
              style: ElevatedButton.styleFrom(
                backgroundColor: kDark, // Matches "Save Changes" black background
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                elevation: 4,
              ),
              child: s.isSaving
                  ? const CircularProgressIndicator(color: kLight)
                  : Text(
                      'Save Changes',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: kLight,
                      ),
                    ),
            ),
          ),
        ),
        body: Consumer<ProfileEditState>(
          builder: (context, state, _) {
            if (state.isLoading) return const Center(child: CircularProgressIndicator(color: kThemeColor));
            return ListView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 100.h),
              children: [
                _buildIdentitySection(state),
                _buildPersonalSection(state),
                _buildEducationSection(state),
                _buildProfessionalSection(state),
                _buildAttributesSection(state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildIdentitySection(ProfileEditState state) {
    return Column(
      key: _identityKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Identity'),
        Center(
          child: Stack(
            children: [
              CircleAvatar(radius: 45.r, backgroundColor: Colors.grey[200], child: Icon(Icons.camera_alt_outlined, color: kDarkGrey)),
              Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 12.r, backgroundColor: kDark, child: Icon(Icons.edit, size: 12, color: kLight))),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        _Field(label: 'Name', init: state.username, onChanged: (v) => state.username = v),
        _Field(label: 'Bio', init: '', onChanged: (v) {}, maxLines: 3),
        _Field(label: 'Location', init: state.city, onChanged: (v) => state.city = v),
      ],
    );
  }

  Widget _buildPersonalSection(ProfileEditState state) {
    return Column(
      key: _personalKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Personal & Security'),
        _Field(label: 'Email', init: 'alex@example.com', onChanged: (v) {}),
        PhoneInputField(initialValue: state.phone, onChanged: (v) => state.phone = v),
        Row(
          children: [
            Expanded(child: _Field(label: 'Gender', init: state.gender, onChanged: (v) => state.gender = v)),
            SizedBox(width: 15.w),
            Expanded(child: _Field(label: 'Age', init: '24', onChanged: (v) {})),
          ],
        ),
      ],
    );
  }

  Widget _buildEducationSection(ProfileEditState state) {
    return Container(
      key: _educationKey,
      margin: EdgeInsets.only(top: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Education'),
          _Field(label: 'College', init: state.college, onChanged: (v) => state.college = v),
          _Field(label: 'Branch', init: state.branch, onChanged: (v) => state.branch = v),
          Row(
            children: [
              Expanded(child: _Field(label: 'Class of', init: '2024', onChanged: (v) {})),
              SizedBox(width: 15.w),
              Expanded(child: _Field(label: 'CGPA', init: '3.9 / 4.0', onChanged: (v) {})),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalSection(ProfileEditState state) {
    return Column(
      key: _professionalKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Professional'),
        Text("Experience", style: TextStyle(fontSize: 12.sp, color: kDarkGrey, fontWeight: FontWeight.bold)),
        _ExpandableEditCard(
          title: "Senior Product Manager",
          subtitle: "Stripe • 2022 - Present",
          children: [
            _Field(label: 'Title', init: 'Senior Product Manager', onChanged: (v) {}),
            _Field(label: 'Company', init: 'Stripe', onChanged: (v) {}),
          ],
        ),
        _ExpandableEditCard(
          title: "Software Engineer II",
          subtitle: "Vercel Inc. • 2021 - 2022",
          children: [
            _Field(label: 'Title', init: 'Software Engineer II', onChanged: (v) {}),
            _Field(label: 'Company', init: 'Vercel Inc.', onChanged: (v) {}),
            Row(
              children: [
                Expanded(child: _Field(label: 'Start', init: '2021', onChanged: (v) {})),
                SizedBox(width: 10.w),
                Expanded(child: _Field(label: 'End', init: '2022', onChanged: (v) {})),
              ],
            ),
          ],
        ),
        _AddButton(label: "Add New Experience"),
        SizedBox(height: 15.h),
        Text("Projects", style: TextStyle(fontSize: 12.sp, color: kDarkGrey, fontWeight: FontWeight.bold)),
        _ExpandableEditCard(
          title: "Fluid Design System",
          subtitle: "Design System",
          children: [
            _Field(label: 'Project Name', init: 'Fluid Design System', onChanged: (v) {}),
            _Field(label: 'Type', init: 'Design System', onChanged: (v) {}),
            _Field(label: 'Description', init: '', onChanged: (v) {}, maxLines: 3),
          ],
        ),
        _AddButton(label: "Add New Project"),
      ],
    );
  }

  Widget _buildAttributesSection(ProfileEditState state) {
    return Column(
      key: _attributesKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Interests & Attributes'),
        _ChipInputField(label: "Skills", tags: ["React", "TypeScript", "Node.js"]),
        _ChipInputField(label: "Work Style", tags: ["Remote", "Collaborative"]),
        _ChipInputField(label: "Hobbies", tags: ["Photography", "Hiking"]),
      ],
    );
  }
}

// ── CUSTOM NAVBAR ────────────────────────────────────────────────────────────

class _CustomNavBar extends StatelessWidget {
  final Function(int) onTap;
  const _CustomNavBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = ['Identity', 'Personal', 'Education', 'Professional', 'Attributes'];
    return Container(
      height: 50.h,
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0)))),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          bool isActive = index == 0; // Simplified for UI; can be stateful
          return GestureDetector(
            onTap: () => onTap(index),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isActive ? kDark : Colors.transparent, width: 2)),
              ),
              child: Text(
                items[index],
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13.sp,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? kDark : kDarkGrey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── EXPANDABLE EDIT CARD ─────────────────────────────────────────────────────

class _ExpandableEditCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _ExpandableEditCard({required this.title, required this.subtitle, required this.children});

  @override
  State<_ExpandableEditCard> createState() => _ExpandableEditCardState();
}

class _ExpandableEditCardState extends State<_ExpandableEditCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(8.r)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          trailing: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.edit, size: 20, color: kDarkGrey),
          onExpansionChanged: (val) => setState(() => isExpanded = val),
          title: Text(widget.title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: kDark)),
          subtitle: Text(widget.subtitle, style: TextStyle(fontSize: 11.sp, color: kDarkGrey)),
          children: [Padding(padding: EdgeInsets.all(12.w), child: Column(children: widget.children))],
        ),
      ),
    );
  }
}

// ── REUSABLE UI COMPONENTS ───────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Text(title, style: TextStyle(fontFamily: 'DMSans', fontSize: 18.sp, fontWeight: FontWeight.w700, color: kDark)),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String init;
  final ValueChanged<String> onChanged;
  final int maxLines;
  const _Field({required this.label, required this.init, required this.onChanged, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12.sp, color: kDarkGrey, fontWeight: FontWeight.w500)),
          SizedBox(height: 4.h),
          TextFormField(
            initialValue: init,
            onChanged: onChanged,
            maxLines: maxLines,
            decoration: InputDecoration(
              filled: true,
              fillColor: kLight,
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: Colors.grey[300]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: Colors.grey[300]!)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipInputField extends StatelessWidget {
  final String label;
  final List<String> tags;
  const _ChipInputField({required this.label, required this.tags});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12.h),
        Text(label, style: TextStyle(fontSize: 12.sp, color: kDarkGrey, fontWeight: FontWeight.w500)),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8,
          children: tags.map((t) => Chip(
            label: Text(t, style: TextStyle(fontSize: 12.sp)),
            backgroundColor: Colors.grey[100],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
            side: BorderSide.none,
          )).toList(),
        ),
        Row(
          children: [
            Expanded(child: _Field(label: "", init: "", onChanged: (v) {})),
            SizedBox(width: 10.w),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: kDark, minimumSize: Size(60.w, 45.h)),
              child: Text("Add", style: TextStyle(color: kLight)),
            )
          ],
        ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  const _AddButton({required this.label});
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add, size: 18, color: kDarkGrey),
      label: Text(label, style: TextStyle(color: kDarkGrey, fontSize: 13.sp)),
    );
  }
}