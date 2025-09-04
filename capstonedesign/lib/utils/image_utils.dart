import 'package:flutter/material.dart';

/// Utility class for optimized image loading and caching
class ImageUtils {
  static const Map<String, Widget> _cachedImages = {
    // Cache commonly used images with const constructors
    'trashbin': Image(
      image: AssetImage('assets/images/trashbin.png'),
      width: 100,
      fit: BoxFit.contain,
    ),
    'trashbin_small': Image(
      image: AssetImage('assets/images/trashbin.png'),
      width: 60,
      fit: BoxFit.contain,
    ),
  };

  /// Get a cached image or create a new one with optimized parameters
  static Widget getOptimizedImage(
    String assetPath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool useCache = true,
  }) {
    // Check if we have a cached version
    if (useCache) {
      final cachedKey = '${assetPath}_${width}_${height}';
      if (_cachedImages.containsKey(cachedKey)) {
        return _cachedImages[cachedKey]!;
      }
    }

    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      // Add memory optimization
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
    );
  }

  /// Precache important images to reduce loading time
  static Future<void> precacheCommonImages(BuildContext context) async {
    final commonImages = [
      'assets/images/trashbin.png',
      'assets/images/trash_monster.png',
      'assets/images/trash_monster_attacked.png',
      'assets/images/damage_effect.png',
      'assets/images/dog_stage1.gif',
      'assets/images/dog_stage2.png',
      'assets/images/dog_stage3.png',
      'assets/images/dog_stage4.png',
      'assets/images/dog_stage5.png',
    ];

    for (final imagePath in commonImages) {
      try {
        await precacheImage(AssetImage(imagePath), context);
      } catch (e) {
        // Silently continue if image doesn't exist
        debugPrint('Failed to precache image: $imagePath');
      }
    }
  }
}