import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 80,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        // Check file size
        final file = File(image.path);
        final fileSizeInBytes = await file.length();
        final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
        
        if (fileSizeInMB > AppConstants.maxImageSizeMB) {
          throw Exception('حجم الصورة كبير جداً. الحد الأقصى ${AppConstants.maxImageSizeMB} ميجابايت');
        }
      }
      
      return image;
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<XFile>?> pickMultipleImages({
    int imageQuality = 80,
    int maxImages = 5,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (images.length > maxImages) {
        throw Exception('يمكنك اختيار حد أقصى $maxImages صور');
      }
      
      // Check total file size
      int totalSize = 0;
      for (final image in images) {
        final file = File(image.path);
        totalSize += await file.length();
      }
      
      final totalSizeInMB = totalSize / (1024 * 1024);
      if (totalSizeInMB > AppConstants.maxImageSizeMB * maxImages) {
        throw Exception('حجم الصور كبير جداً');
      }
      
      return images;
    } catch (e) {
      rethrow;
    }
  }

  static Future<String?> uploadImage(
    XFile image, {
    required String bucket,
    String? folder,
  }) async {
    try {
      final file = File(image.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final filePath = folder != null ? '$folder/$fileName' : fileName;
      
      await _supabase.storage.from(bucket).upload(
        filePath,
        file,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );
      
      return filePath;
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<String>> uploadMultipleImages(
    List<XFile> images, {
    required String bucket,
    String? folder,
  }) async {
    try {
      final List<String> uploadedPaths = [];
      
      for (final image in images) {
        final path = await uploadImage(
          image,
          bucket: bucket,
          folder: folder,
        );
        if (path != null) {
          uploadedPaths.add(path);
        }
      }
      
      return uploadedPaths;
    } catch (e) {
      rethrow;
    }
  }

  static String getImageUrl(String bucket, String path) {
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  static Future<void> deleteImage(String bucket, String path) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      // Ignore errors when deleting images
    }
  }

  static Future<void> showImageSourceDialog(
    BuildContext context, {
    required Function(XFile) onImageSelected,
  }) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('اختيار من المعرض'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final image = await pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    onImageSelected(image);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ في اختيار الصورة: $e')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('التقاط صورة'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final image = await pickImage(source: ImageSource.camera);
                  if (image != null) {
                    onImageSelected(image);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ في التقاط الصورة: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}