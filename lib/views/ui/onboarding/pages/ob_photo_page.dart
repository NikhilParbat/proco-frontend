import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/onboarding_flow_provider.dart';
import 'package:proco/views/ui/onboarding/widgets/ob_scaffold.dart';
import 'package:provider/provider.dart';

class ObPhotoPage extends StatefulWidget {
  const ObPhotoPage({super.key});

  @override
  State<ObPhotoPage> createState() => _ObPhotoPageState();
}

class _ObPhotoPageState extends State<ObPhotoPage> {
  File? _pickedFile;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _pickedFile = context.read<OnboardingFlowProvider>().profilePhoto;
  }

  Future<void> _pick(ImageSource source) async {
    final permission =
        source == ImageSource.camera ? Permission.camera : Permission.photos;
    final status = await permission.request();
    if (!status.isGranted && !status.isLimited) {
      if (status.isPermanentlyDenied) openAppSettings();
      return;
    }

    setState(() => _picking = true);
    try {
      final result = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (result != null && mounted) {
        setState(() => _pickedFile = File(result.path));
        context.read<OnboardingFlowProvider>().profilePhoto = _pickedFile;
      }
    } finally {
      setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OnboardingFlowProvider>();

    return ObScaffold(
      title: "Add a profile\nphoto",
      subtitle: "A photo helps people recognise you. You can skip this for now.",
      nextLabel: _pickedFile != null ? 'Continue' : 'Skip for now',
      body: Center(
        child: Column(
          children: [
            // ── Avatar preview ───────────────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                    border: Border.all(
                      color: _pickedFile != null ? kTeal : Colors.white24,
                      width: 2.5,
                    ),
                    image: _pickedFile != null
                        ? DecorationImage(
                            image: FileImage(_pickedFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _pickedFile == null
                      ? Icon(
                          Icons.person_rounded,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.2),
                        )
                      : null,
                ),
                if (_picking)
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: kTeal,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Picker buttons ───────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PickerButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: _picking ? null : () => _pick(ImageSource.gallery),
                ),
                const SizedBox(width: 16),
                _PickerButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onTap: _picking ? null : () => _pick(ImageSource.camera),
                ),
              ],
            ),

            if (_pickedFile != null) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  setState(() => _pickedFile = null);
                  provider.profilePhoto = null;
                },
                child: const Text(
                  'Remove photo',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white38,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      onNext: () => provider.nextPage(),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: onTap != null
              ? kTeal.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: onTap != null ? kTeal.withValues(alpha: 0.5) : Colors.white12,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: onTap != null ? kTeal : Colors.white24, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: onTap != null ? Colors.white70 : Colors.white24,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
