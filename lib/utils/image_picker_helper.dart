import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/utils/registration_validators.dart';

class ImagePickResult {
  final bool isSuccess;
  final String? path;
  final int? sizeInBytes;
  final String? errorMessage;

  ImagePickResult({
    required this.isSuccess,
    this.path,
    this.sizeInBytes,
    this.errorMessage,
  });
}

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Opens the device camera to take a selfie (front camera preferred)
  static Future<ImagePickResult> takeSelfie(BuildContext context) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo == null) {
        return ImagePickResult(
          isSuccess: false,
          errorMessage: 'No photo captured',
        );
      }

      final int size = await photo.length();
      if (size > RegistrationValidators.maxFileSizeInBytes) {
        return ImagePickResult(
          isSuccess: false,
          errorMessage: 'Image exceeds the maximum 5MB limit. Please retake.',
        );
      }

      return ImagePickResult(
        isSuccess: true,
        path: photo.path,
        sizeInBytes: size,
      );
    } catch (e) {
      return ImagePickResult(
        isSuccess: false,
        errorMessage: 'Camera error: ${e.toString()}',
      );
    }
  }

  /// Opens the device camera to take a document photo (rear camera).
  ///
  /// Every identity document and registration photo goes through here or
  /// [takeSelfie]: they have to be live captures, because a photo of a photo
  /// defeats the point of verifying the person. Do not swap these for
  /// [pickFromGallery] or [showSourceSelector].
  static Future<ImagePickResult> captureDocumentPhoto(BuildContext context) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo == null) {
        return ImagePickResult(
          isSuccess: false,
          errorMessage: 'No photo captured',
        );
      }

      final int size = await photo.length();
      if (size > RegistrationValidators.maxFileSizeInBytes) {
        return ImagePickResult(
          isSuccess: false,
          errorMessage: 'Image exceeds the maximum 5MB limit. Please retake.',
        );
      }

      return ImagePickResult(
        isSuccess: true,
        path: photo.path,
        sizeInBytes: size,
      );
    } catch (e) {
      return ImagePickResult(
        isSuccess: false,
        errorMessage: 'Camera error: ${e.toString()}',
      );
    }
  }

  /// Opens the device gallery to pick an image
  /// Gallery picker. NOT for identity documents or registration photos -
  /// those must be live camera captures (see [captureDocumentPhoto]).
  static Future<ImagePickResult> pickFromGallery(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        return ImagePickResult(
          isSuccess: false,
          errorMessage: 'No image selected',
        );
      }

      final int size = await image.length();
      if (size > RegistrationValidators.maxFileSizeInBytes) {
        return ImagePickResult(
          isSuccess: false,
          errorMessage: 'Image exceeds the maximum 5MB limit. Please select another image.',
        );
      }

      return ImagePickResult(
        isSuccess: true,
        path: image.path,
        sizeInBytes: size,
      );
    } catch (e) {
      return ImagePickResult(
        isSuccess: false,
        errorMessage: 'Gallery error: ${e.toString()}',
      );
    }
  }

  /// Shows an image source selection modal (Camera vs Gallery) and returns the picked result
  static Future<ImagePickResult?> showSourceSelector(
    BuildContext context, {
    String title = 'Upload Photo',
  }) async {
    final ImageSource? selectedSource = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                  ),
                  title: const Text(
                    'Take Photo',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  subtitle: const Text('Use camera to take a photo'),
                  onTap: () {
                    Navigator.of(ctx).pop(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library, color: Color(0xFF10B981)),
                  ),
                  title: const Text(
                    'Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  subtitle: const Text('Choose photo from gallery'),
                  onTap: () {
                    Navigator.of(ctx).pop(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedSource == null) {
      return null;
    }

    if (!context.mounted) return null;

    if (selectedSource == ImageSource.camera) {
      return await captureDocumentPhoto(context);
    } else {
      return await pickFromGallery(context);
    }
  }
}
