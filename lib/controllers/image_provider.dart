import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageNotifier extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();

  /// The picked/cropped file. Use [imageBytes] to display it in the UI
  /// (works on both web and native — avoids dart:io dependency in widgets).
  XFile? selectedImage;

  /// Raw bytes of [selectedImage]. Populated whenever [selectedImage] is set.
  Uint8List? imageBytes;

  bool isLoading = false;
  String? errorMessage;

  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color lightPurple = Color(0xFFF3F2FF);

  Future<bool> _requestPermission(ImageSource source) async {
    // Browsers handle permissions natively through their own prompts
    if (kIsWeb) return true;

    final permission =
        source == ImageSource.camera ? Permission.camera : Permission.photos;
    final status = await permission.request();
    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied) await openAppSettings();
    return false;
  }

  Future<void> pickImage({ImageSource source = ImageSource.gallery}) async {
    final granted = await _requestPermission(source);
    if (!granted) return;

    try {
      _setLoading(true);
      _clearError();

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        _setLoading(false);
        return;
      }

      final fileSize = await pickedFile.length();
      if (fileSize > 2 * 1024 * 1024) {
        _setError('Photo is a bit too large (limit 2MB).');
        _setLoading(false);
        return;
      }

      XFile result;
      if (kIsWeb) {
        // image_cropper has no web implementation — use the picked file as-is
        result = pickedFile;
      } else {
        final XFile? cropped = await _cropImage(pickedFile);
        if (cropped == null) {
          _setLoading(false);
          return;
        }
        result = cropped;
      }

      selectedImage = result;
      imageBytes = await result.readAsBytes();
      notifyListeners();
    } catch (e) {
      _setError('Something went wrong. Try again!');
    } finally {
      _setLoading(false);
    }
  }

  Future<XFile?> _cropImage(XFile imageFile) async {
    try {
      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        maxHeight: 800,
        maxWidth: 600,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Adjust your photo',
            toolbarColor: Colors.white,
            toolbarWidgetColor: primaryPurple,
            activeControlsWidgetColor: primaryPurple,
            statusBarLight: true,
            backgroundColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio5x4,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Adjust your photo',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (cropped == null) return null;
      return XFile(cropped.path);
    } catch (e) {
      _setError('Cropping failed. Please try again.');
      return null;
    }
  }

  void clearImage() {
    selectedImage = null;
    imageBytes = null;
    notifyListeners();
  }

  bool get hasImage => selectedImage != null;

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    errorMessage = null;
  }
}
