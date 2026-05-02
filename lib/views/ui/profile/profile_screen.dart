import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/common/lagoon_drawer.dart';
import 'package:provider/provider.dart';

// Ensure these imports point to your new 'profile' folder
import 'profile_state.dart';
import 'profile_view.dart';
import 'profile_edit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileEditState(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: kBackgroundColor, // Lagoon Navy
          drawer: const LagoonDrawer(),
          appBar: const LagoonAppBar(),
          body: Consumer<ProfileEditState>(
            builder: (context, state, _) {
              if (state.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: kTeal),
                );
              }

              if (state.error != null) {
                return _buildErrorView(state);
              }

              return Column(
                children: [
                  _buildTabBar(),
                  const Expanded(
                    child: TabBarView(
                      children: [ProfileViewTab(), ProfileEditTab()],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Container(
        height: 44.h,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const TabBar(
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: kTeal,
            borderRadius: BorderRadius.all(Radius.circular(9)),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
          tabs: [
            Tab(text: "View"),
            Tab(text: "Edit"),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(ProfileEditState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
          SizedBox(height: 10.h),
          Text(state.error!, style: const TextStyle(color: Colors.white)),
          TextButton(
            onPressed: () => state.loadProfile(),
            child: const Text("Retry", style: TextStyle(color: kTeal)),
          ),
        ],
      ),
    );
  }
}
