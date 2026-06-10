import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:proco/constants/app_colors.dart';
import 'package:proco/models/response/jobs/public_job.dart';
import 'package:proco/services/config.dart';
import 'package:proco/services/helpers/jobs_helper.dart';
import 'package:proco/services/token_store.dart';
import 'package:proco/views/common/lagoon_app_bar.dart';
import 'package:proco/views/ui/auth/login.dart';
import 'package:proco/views/ui/jobs/job_card_swiper.dart';
import 'package:proco/views/ui/mainscreen.dart';
import 'package:url_launcher/url_launcher.dart';

/// Public, read-only view of a single opportunity, opened from a shared link.
///
/// Instagram-style: anyone (not logged in, nothing installed) can see the
/// opportunity exactly as it looks in the app, but can't act on it. A
/// persistent bar prompts them to open the full web app (later: download the
/// app — see [_ShareCtaBar]).
class OpportunityShareScreen extends StatefulWidget {
  final String opportunityId;

  const OpportunityShareScreen({super.key, required this.opportunityId});

  @override
  State<OpportunityShareScreen> createState() => _OpportunityShareScreenState();
}

class _OpportunityShareScreenState extends State<OpportunityShareScreen> {
  PublicJob? _data;
  String? _error;
  bool _loading = true;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await JobsHelper.getPublicJob(widget.opportunityId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.data != null) {
        _data = res.data;
      } else {
        _error = res.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: const LagoonAppBar(showDrawer: false),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kThemeColor))
            : _error != null
            ? _buildError()
            : _buildLoaded(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off_rounded, size: 48.w, color: Colors.grey),
            SizedBox(height: 16.h),
            Text(
              'This opportunity is unavailable',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'It may have been removed or the link is invalid.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 13.sp, color: Colors.grey),
            ),
            SizedBox(height: 20.h),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaded() {
    final data = _data!;
    final imageCacheWidth =
        (MediaQuery.of(context).size.width * 1.2).toInt();

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400.w),
                child: FlippableJobCard(
                  job: data.job,
                  imageCacheWidth: imageCacheWidth,
                  ownerName: data.ownerName,
                  isExpanded: _expanded,
                  onToggleExpanded: () =>
                      setState(() => _expanded = !_expanded),
                ),
              ),
            ),
          ),
        ),
        const _ShareCtaBar(),
      ],
    );
  }
}

/// Persistent prompt at the bottom of the shared view.
///
/// This is the single place to change when the native app is published: flip
/// [Config.appStoreLive] to true and fill the store URLs in [Config]. The
/// wording and action below switch automatically.
class _ShareCtaBar extends StatelessWidget {
  const _ShareCtaBar();

  Future<void> _onPressed() async {
    if (Config.appStoreLive) {
      final url = _storeUrl();
      if (url.isNotEmpty) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        return;
      }
    }
    // Default (no store listing yet): open the full web app.
    final token = await TokenStore.getToken();
    if (token != null && token.isNotEmpty) {
      Get.offAll(() => const MainScreen());
    } else {
      Get.offAll(() => const LoginPage(drawer: false));
    }
  }

  String _storeUrl() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return Config.appStoreUrl;
      default:
        return Config.playStoreUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloadMode = Config.appStoreLive;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            downloadMode
                ? 'Get the Lagoon app to apply and chat'
                : 'Open Lagoon to apply, bookmark and chat',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 12.sp,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: kThemeColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: Text(
                downloadMode ? 'Download the app' : 'Open in Lagoon Web',
                style: GoogleFonts.dmSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
