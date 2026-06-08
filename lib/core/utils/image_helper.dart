import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageHelper {
  // Check if string is base64 image
  static bool isBase64Image(String? imageString) {
    if (imageString == null || imageString.isEmpty) return false;
    return imageString.startsWith('data:image') || imageString.contains(',');
  }

  // Convert base64 string to ImageProvider
  static ImageProvider? getImageProvider(String? imageString) {
    if (imageString == null || imageString.isEmpty) return null;

    try {
      if (isBase64Image(imageString)) {
        final base64Data = imageString.split(',').last;
        final bytes = base64.decode(base64Data);
        return MemoryImage(bytes);
      } else {
        return NetworkImage(imageString);
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
      return null;
    }
  }

  // Get decoded bytes from base64 string
  static Uint8List? getImageBytes(String? imageString) {
    if (imageString == null || imageString.isEmpty) return null;

    try {
      if (isBase64Image(imageString)) {
        final base64Data = imageString.split(',').last;
        return base64.decode(base64Data);
      }
      return null;
    } catch (e) {
      debugPrint('Error decoding base64: $e');
      return null;
    }
  }
}