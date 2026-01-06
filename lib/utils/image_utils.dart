import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as path;
import 'package:smart_chaja/app_constants/app_constants.dart';

class ImageUtils {
  // Crop Image Method with Aspect Ratio Locking Option
  static Future<File?> cropImage(
    File imageFile,
    BuildContext context, {
    bool lockAspectRatio = false,
  }) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: AppColors.primaryColor,
          toolbarWidgetColor: Colors.white,
          hideBottomControls: false,
          lockAspectRatio: lockAspectRatio,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(
          title: 'Crop Image',
          minimumAspectRatio: 1.0,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        WebUiSettings(
          context: context,
        ),
      ],
    );

    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }

  // Validate Image File (no compression anymore)
  static Future<File?> processImage(File file) async {
    try {
      print('Processing image: ${file.path}');
      final String ext = path.extension(file.path).toLowerCase();
      print('Original file extension: $ext');

      // Check if it's a valid image file
      if (!['.png', '.jpg', '.jpeg', '.webp', '.gif'].contains(ext)) {
        print('Unsupported format, skipping image processing');
        return null;
      }

      if (!await file.exists()) {
        print('File does not exist: ${file.path}');
        return null;
      }

      // Just return original file now
      return file;
    } catch (e) {
      print('Error processing image: $e');
      return null;
    }
  }

  // Get MIME Type Based on File Extension
  static Future<String> getMimeType(File file) async {
    final String ext = path.extension(file.path).toLowerCase();

    if (!['.jpg', '.jpeg', '.png', '.webp', '.gif'].contains(ext)) {
      print('Unsupported file type: $ext');
      return 'application/octet-stream';
    }

    switch (ext) {
      case '.jpeg':
      case '.jpg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }
}
