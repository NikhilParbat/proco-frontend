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
        _editField("Username", state.username, (v) => state.username = v),
        _editField("Phone", state.phone, (v) => state.phone = v),
        _editField("College", state.college, (v) => state.college = v),
        SizedBox(height: 20.h),
        ElevatedButton(
          onPressed: state.isSaving ? null : () => state.saveProfile(null),
          child: state.isSaving
              ? const CircularProgressIndicator()
              : const Text("Save Changes"),
        ),
      ],
    );
  }

  Widget _editField(
    String label,
    String initialValue,
    Function(String) onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15.h),
      child: TextFormField(
        initialValue: initialValue,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
