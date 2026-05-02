import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'profile_state.dart';

class ProfileEditTab extends StatelessWidget {
  const ProfileEditTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfileEditState>();

    return ListView(
      padding: EdgeInsets.all(20.w),
      children: [
        _sectionTitle('Basic info'),
        _editField('Username', state.username, (v) => state.username = v),
        _editField('Phone', state.phone, (v) => state.phone = v),
        _editField('Gender', state.gender, (v) => state.gender = v),
        _editField('Date of Birth', state.dob, (v) => state.dob = v),
        _editField('User Type', state.userType, (v) => state.userType = v),
        SizedBox(height: 12.h),
        _sectionTitle('Education'),
        _editField('College', state.college, (v) => state.college = v),
        _editField('Degree / Branch', state.branch, (v) => state.branch = v),
        SizedBox(height: 12.h),
        _sectionTitle('Skills and hobbies'),
        _editListField('Skills', state.skills, (v) => state.skills = v),
        _editListField('Hobbies', state.hobbies, (v) => state.hobbies = v),
        SizedBox(height: 12.h),
        _sectionTitle('Location'),
        _editField('City', state.city, (v) => state.city = v),
        _editField('State', state.state, (v) => state.state = v),
        _editField('Country', state.country, (v) => state.country = v),
        SizedBox(height: 12.h),
        _sectionTitle('Links'),
        _editField(
          'LinkedIn URL',
          state.linkedInUrl,
          (v) => state.linkedInUrl = v,
        ),
        _editField('GitHub URL', state.gitHubUrl, (v) => state.gitHubUrl = v),
        _editField(
          'Twitter URL',
          state.twitterUrl,
          (v) => state.twitterUrl = v,
        ),
        _editField(
          'Portfolio URL',
          state.portfolioUrl,
          (v) => state.portfolioUrl = v,
        ),
        SizedBox(height: 20.h),
        SizedBox(
          height: 48.h,
          child: ElevatedButton(
            onPressed: state.isSaving ? null : () => state.saveProfile(null),
            child: state.isSaving
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Changes'),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 15.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _editField(
    String label,
    String initialValue,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15.h),
      child: TextFormField(
        initialValue: initialValue,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF0BBFCA)),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _editListField(
    String label,
    List<String> values,
    ValueChanged<List<String>> onChanged,
  ) {
    return _editField(
      label,
      values.join(', '),
      (value) => onChanged(
        value
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(),
      ),
    );
  }
}
