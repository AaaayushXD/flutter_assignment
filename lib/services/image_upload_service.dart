import 'dart:io';
import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  // 1. Sign up at https://cloudinary.com/
  // 2. Get your cloud name from the dashboard
  // 3. Create an unsigned upload preset in Settings > Upload
  static const String _cloudName =
      'dqhffsxtk'; // Replace with your Cloudinary cloud name
  static const String _uploadPreset =
      'playlist'; // Replace with your upload preset

  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    _cloudName,
    _uploadPreset,
  );

  // Random playlist images for fallback
  static const List<String> _randomPlaylistImages = [
    'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=300&h=300&fit=crop',
    'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=300&h=300&fit=crop',
    'https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?w=300&h=300&fit=crop',
    'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=300&h=300&fit=crop',
    'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=300&h=300&fit=crop',
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=300&h=300&fit=crop',
    'https://images.unsplash.com/photo-1471478331149-c72f17e33c73?w=300&h=300&fit=crop',
    'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=300&h=300&fit=crop',
    'https://images.unsplash.com/photo-1445985543470-41fba5c3144a?w=300&h=300&fit=crop',
    'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=300&h=300&fit=crop',
  ];

  /// Upload image to Cloudinary
  Future<String> uploadImage(XFile imageFile) async {
    try {
      CloudinaryResponse response;

      if (kIsWeb) {
        // For web, read as bytes
        final bytes = await imageFile.readAsBytes();
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            bytes,
            identifier: 'playlist_${DateTime.now().millisecondsSinceEpoch}',
            folder: 'playlists',
          ),
        );
      } else {
        // For mobile, use file path
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(imageFile.path, folder: 'playlists'),
        );
      }

      return response.secureUrl;
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      rethrow;
    }
  }

  /// Upload image from File (mobile) or Uint8List (web)
  Future<String> uploadImageData(dynamic imageData) async {
    try {
      CloudinaryResponse response;

      if (imageData is Uint8List) {
        // Web - bytes data
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            imageData,
            identifier: 'playlist_${DateTime.now().millisecondsSinceEpoch}',
            folder: 'playlists',
          ),
        );
      } else if (imageData is File) {
        // Mobile - file
        response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(imageData.path, folder: 'playlists'),
        );
      } else {
        throw Exception('Unsupported image data type');
      }

      return response.secureUrl;
    } catch (e) {
      print('Error uploading image data to Cloudinary: $e');
      rethrow;
    }
  }

  /// Get a random playlist image URL
  String getRandomPlaylistImage() {
    final random =
        DateTime.now().millisecondsSinceEpoch % _randomPlaylistImages.length;
    return _randomPlaylistImages[random];
  }

  /// Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      return await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      return await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Show image picker dialog
  Future<XFile?> showImagePicker(BuildContext context) async {
    return await showDialog<XFile?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await pickImageFromCamera();
                  Navigator.pop(context, image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await pickImageFromGallery();
                  Navigator.pop(context, image);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
