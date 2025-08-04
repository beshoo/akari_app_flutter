import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/models/apartment_model.dart';
import '../services/image_service.dart';
import '../utils/logger.dart';

class CustomImagePicker extends StatefulWidget {
  final List<File> selectedImages;
  final List<Uint8List> processedImages;
  final List<Media> existingImages;
  final Function(List<File>) onImagesSelected;
  final Function(List<Uint8List>) onImagesProcessed;
  final Function(List<Media>) onExistingImagesChanged;
  final Function(int) onPhotoDeleted; // Callback when a photo is deleted
  final int maxImages;
  final bool isEnabled;

  const CustomImagePicker({
    super.key,
    required this.selectedImages,
    required this.processedImages,
    this.existingImages = const [],
    required this.onImagesSelected,
    required this.onImagesProcessed,
    required this.onExistingImagesChanged,
    required this.onPhotoDeleted,
    this.maxImages = 6,
    this.isEnabled = true,
  });

  @override
  State<CustomImagePicker> createState() => _CustomImagePickerState();
}

class _CustomImagePickerState extends State<CustomImagePicker> {
  bool _isProcessing = false;

  int get totalImageCount => widget.existingImages.length + widget.selectedImages.length;
  int get remainingSlots => widget.maxImages - totalImageCount;

  Future<void> _pickImages() async {
    if (!widget.isEnabled || remainingSlots <= 0) return;

    try {
      final List<File> pickedImages = await ImageService.pickImages(
        maxImages: remainingSlots,
      );

      if (pickedImages.isNotEmpty) {
        // Filter out duplicate images
        final List<File> uniqueImages = <File>[];
        final Set<String> existingPaths = <String>{};
        
        // Add existing image paths to the set
        for (final File existingImage in widget.selectedImages) {
          existingPaths.add(existingImage.path);
        }
        
        // Add new images only if they're not duplicates
        for (final File newImage in pickedImages) {
          if (!existingPaths.contains(newImage.path)) {
            uniqueImages.add(newImage);
            existingPaths.add(newImage.path);
          }
        }

        if (uniqueImages.isNotEmpty) {
          // Add new unique images to the list
          final List<File> updatedImages = [...widget.selectedImages, ...uniqueImages];
          widget.onImagesSelected(updatedImages);

          // Process images for upload
          setState(() {
            _isProcessing = true;
          });

          final List<Uint8List> processedImages = await ImageService.processImagesForUpload(updatedImages);
          
          setState(() {
            _isProcessing = false;
          });

          widget.onImagesProcessed(processedImages);
        } else {
          // Show a message that all selected images were duplicates
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'تم تجاهل الصور المكررة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('Error picking images: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _removeNewImage(int index) {
    final List<File> updatedImages = List.from(widget.selectedImages);
    updatedImages.removeAt(index);
    widget.onImagesSelected(updatedImages);

    // Reprocess remaining images
    _reprocessImages(updatedImages);
  }

  void _removeExistingImage(int index) {
    final List<Media> updatedExistingImages = List.from(widget.existingImages);
    final removedImage = updatedExistingImages[index];
    updatedExistingImages.removeAt(index);
    Logger.log('Removing existing image: ID ${removedImage.id}');
    Logger.log('Updated existing images count: ${updatedExistingImages.length}');
    widget.onExistingImagesChanged(updatedExistingImages);
    widget.onPhotoDeleted(removedImage.id); // Notify parent about deleted photo
  }

  Future<void> _reprocessImages(List<File> images) async {
    setState(() {
      _isProcessing = true;
    });

    final List<Uint8List> processedImages = await ImageService.processImagesForUpload(images);
    
    setState(() {
      _isProcessing = false;
    });

    widget.onImagesProcessed(processedImages);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          'صور العقار (اختياري)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'Cairo',
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Image grid
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Images grid
              if (widget.existingImages.isNotEmpty || widget.selectedImages.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: widget.existingImages.length + widget.selectedImages.length,
                  itemBuilder: (context, index) {
                    if (index < widget.existingImages.length) {
                      return _buildExistingImageItem(index);
                    } else {
                      final newImageIndex = index - widget.existingImages.length;
                      return _buildNewImageItem(newImageIndex);
                    }
                  },
                ),
              
              // Add image button
              if (remainingSlots > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: _buildAddImageButton(),
                ),
            ],
          ),
        ),
        
        // Processing indicator
        if (_isProcessing)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'جاري معالجة الصور...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        
        // Info text
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'يمكنك إضافة حتى ${widget.maxImages} صور. سيتم ضغط الصور تلقائياً إلى 1000 بكسل عرض.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildExistingImageItem(int index) {
    final media = widget.existingImages[index];
    return Stack(
      children: [
        // Image
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: CachedNetworkImage(
              imageUrl: media.originalUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade200,
                child: const Icon(
                  Icons.error,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ),
        
        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeExistingImage(index),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewImageItem(int index) {
    return Stack(
      children: [
        // Image
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.file(
              widget.selectedImages[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        
        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeNewImage(index),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: widget.isEnabled ? _pickImages : null,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: widget.isEnabled ? Colors.grey.shade600 : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'إضافة صورة',
              style: TextStyle(
                fontSize: 12,
                color: widget.isEnabled ? Colors.grey.shade600 : Colors.grey.shade400,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
} 