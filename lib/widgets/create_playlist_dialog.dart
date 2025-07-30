import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/playlist_service.dart';
import '../services/image_upload_service.dart';

class CreatePlaylistDialog extends StatefulWidget {
  const CreatePlaylistDialog({super.key});

  @override
  State<CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<CreatePlaylistDialog> {
  final _playlistController = TextEditingController();
  final _playlistService = PlaylistService();
  final _imageUploadService = ImageUploadService();

  bool _isLoading = false;
  bool _isUploadingImage = false;
  XFile? _selectedImage;
  dynamic _imageData; // File for mobile, Uint8List for web
  String? _uploadedImageUrl;

  @override
  void dispose() {
    _playlistController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Playlist'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Playlist Name Field
            TextField(
              controller: _playlistController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 20),

            // Image Selection Section
            const Text(
              'Playlist Image (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),

            // Image Preview or Placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.grey.shade100,
              ),
              child: _buildImagePreview(),
            ),
            const SizedBox(height: 10),

            // Image Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: _isUploadingImage ? null : _pickImageFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                TextButton.icon(
                  onPressed: _isUploadingImage ? null : _pickImageFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
                if (_selectedImage != null)
                  TextButton.icon(
                    onPressed: _isUploadingImage ? null : _removeImage,
                    icon: const Icon(Icons.clear),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
              ],
            ),

            // Upload Status
            if (_isUploadingImage)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Uploading image...'),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading || _isUploadingImage ? null : _createPlaylist,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_isUploadingImage) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedImage != null && _imageData != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: kIsWeb
            ? Image.memory(
                _imageData as Uint8List,
                fit: BoxFit.cover,
                width: 120,
                height: 120,
              )
            : Image.file(
                _imageData as File,
                fit: BoxFit.cover,
                width: 120,
                height: 120,
              ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.playlist_play, size: 40, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text(
          'No image selected',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final image = await _imageUploadService.pickImageFromCamera();
      if (image != null) {
        await _processSelectedImage(image);
      }
    } catch (e) {
      _showErrorSnackBar('Error taking photo: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final image = await _imageUploadService.pickImageFromGallery();
      if (image != null) {
        await _processSelectedImage(image);
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _processSelectedImage(XFile image) async {
    setState(() {
      _selectedImage = image;
      _isUploadingImage = true;
    });

    try {
      // Load image data for preview
      if (kIsWeb) {
        _imageData = await image.readAsBytes();
      } else {
        _imageData = File(image.path);
      }

      // Upload to Cloudinary
      _uploadedImageUrl = await _imageUploadService.uploadImage(image);

      setState(() {
        _isUploadingImage = false;
      });
    } catch (e) {
      setState(() {
        _selectedImage = null;
        _imageData = null;
        _uploadedImageUrl = null;
        _isUploadingImage = false;
      });
      _showErrorSnackBar('Error uploading image: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageData = null;
      _uploadedImageUrl = null;
    });
  }

  Future<void> _createPlaylist() async {
    if (_playlistController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a playlist name');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use uploaded image URL or get random image if none selected
      String? finalImageUrl = _uploadedImageUrl;
      if (finalImageUrl == null) {
        finalImageUrl = _imageUploadService.getRandomPlaylistImage();
      }

      await _playlistService.createPlaylist(
        _playlistController.text.trim(),
        imageUrl: finalImageUrl,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Playlist "${_playlistController.text.trim()}" created!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error creating playlist: $error');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}
