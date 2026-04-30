import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:proco/constants/app_constants.dart';

class ImageNotifier extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();

  File? selectedImage;
  bool isLoading = false;
  String? errorMessage;

  Future<bool> _requestPermission(ImageSource source) async {
    final permission = source == ImageSource.camera
        ? Permission.camera
        : (Platform.isAndroid
            ? Permission.photos
            : Permission.photos);

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

      // Reject files larger than 2 MB
      final fileSize = await pickedFile.length();
      if (fileSize > 2 * 1024 * 1024) {
        _setError('Image must be under 2 MB. Please choose a smaller photo.');
        _setLoading(false);
        return;
      }

      final XFile? croppedFile = await _cropImage(pickedFile);

      if (croppedFile == null) {
        _setLoading(false);
        return;
      }

      selectedImage = File(croppedFile.path);

      notifyListeners();
    } catch (e) {
      _setError('Something went wrong: ${e.toString()}');
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
        compressQuality: 70,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: kLightBlue,
            toolbarWidgetColor: kLight,
            initAspectRatio: CropAspectRatioPreset.ratio5x4,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Crop Image', aspectRatioLockEnabled: true),
        ],
      );

      if (cropped == null) return null;

      return XFile(cropped.path);
    } catch (e) {
      _setError('Cropping failed: ${e.toString()}');
      return null;
    }
  }

  void clearImage() {
    selectedImage = null;
    notifyListeners();
  }

  bool get hasImage => selectedImage != null;

  File? get imageFile => selectedImage;

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
