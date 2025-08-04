import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../utils/logger.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick images from gallery or camera
  static Future<List<File>> pickImages({
    int maxImages = 6,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1000,
        imageQuality: 70,
      );

      if (pickedFiles.isEmpty) return [];

      // Limit to maxImages
      final limitedFiles = pickedFiles.take(maxImages).toList();
      
      // Convert to File objects
      final List<File> files = limitedFiles.map((xFile) => File(xFile.path)).toList();
      
      Logger.log('Picked ${files.length} images');
      return files;
    } catch (e) {
      Logger.error('Error picking images: $e');
      return [];
    }
  }

  /// Resize and compress image to 1000px width with 70% JPEG quality
  static Future<Uint8List?> resizeAndCompressImage(File imageFile) async {
    try {
      // Read the image file
      final Uint8List bytes = await imageFile.readAsBytes();
      
      // Decode the image
      final img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        Logger.error('Failed to decode image');
        return null;
      }

      // Calculate new height maintaining aspect ratio
      final int originalWidth = originalImage.width;
      final int originalHeight = originalImage.height;
      final int targetWidth = 1000;
      
      final double aspectRatio = originalWidth / originalHeight;
      final int targetHeight = (targetWidth / aspectRatio).round();

      // Resize the image
      final img.Image resizedImage = img.copyResize(
        originalImage,
        width: targetWidth,
        height: targetHeight,
      );

      // Encode as JPEG with 70% quality
      final Uint8List compressedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: 70),
      );

      Logger.log('Image resized from ${originalWidth}x${originalHeight} to ${targetWidth}x${targetHeight}');
      return compressedBytes;
    } catch (e) {
      Logger.error('Error resizing image: $e');
      return null;
    }
  }

  /// Process multiple images for upload
  static Future<List<Uint8List>> processImagesForUpload(List<File> imageFiles) async {
    final List<Uint8List> processedImages = [];
    
    for (final File imageFile in imageFiles) {
      final Uint8List? processedImage = await resizeAndCompressImage(imageFile);
      if (processedImage != null) {
        processedImages.add(processedImage);
      }
    }
    
    Logger.log('Processed ${processedImages.length} images for upload');
    return processedImages;
  }

  /// Get file size in MB
  static double getFileSizeInMB(Uint8List bytes) {
    return bytes.length / (1024 * 1024);
  }

  /// Validate image file size (max 5MB per image)
  static bool isValidImageSize(Uint8List bytes) {
    final double sizeInMB = getFileSizeInMB(bytes);
    return sizeInMB <= 5.0;
  }
} 