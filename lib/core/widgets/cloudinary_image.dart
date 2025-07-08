import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/cloudinary_service.dart';

class CloudinaryImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool isGrid;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final BorderRadius? borderRadius;

  const CloudinaryImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isGrid = false,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final cloudinaryService = CloudinaryService();

    // Get optimized image URL
    final optimizedUrl = cloudinaryService.getProductImageUrl(
      imageUrl,
      isGrid: isGrid,
    );

    Widget imageWidget = CachedNetworkImage(
      imageUrl: optimizedUrl ?? '',
      width: width,
      height: height,
      fit: fit,
      placeholder:
          placeholder ??
          (context, url) => Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.orange.withOpacity(0.7),
                ),
              ),
            ),
          ),
      errorWidget:
          errorWidget ??
          (context, url, error) => Container(
            color: Colors.grey[200],
            child: Icon(
              Icons.image_not_supported,
              color: Colors.grey[400],
              size: isGrid ? 32 : 48,
            ),
          ),
    );

    // Apply border radius if specified
    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }
}

class ProductImagePlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final bool isGrid;
  final String text;
  final VoidCallback? onTap;

  const ProductImagePlaceholder({
    super.key,
    this.width,
    this.height,
    this.isGrid = false,
    this.text = 'No Image',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget placeholder = Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, color: Colors.grey[400], size: isGrid ? 32 : 48),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isGrid ? 12 : 14,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      placeholder = InkWell(onTap: onTap, child: placeholder);
    }

    return placeholder;
  }
}

class CloudinaryImageWithFallback extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool isGrid;
  final String placeholderText;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const CloudinaryImageWithFallback({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isGrid = false,
    this.placeholderText = 'No Image',
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return ProductImagePlaceholder(
        width: width,
        height: height,
        isGrid: isGrid,
        text: placeholderText,
        onTap: onTap,
      );
    }

    Widget imageWidget = CloudinaryImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      isGrid: isGrid,
      borderRadius: borderRadius,
      errorWidget:
          (context, url, error) => ProductImagePlaceholder(
            width: width,
            height: height,
            isGrid: isGrid,
            text: 'Failed to load',
            onTap: onTap,
          ),
    );

    if (onTap != null) {
      imageWidget = InkWell(onTap: onTap, child: imageWidget);
    }

    return imageWidget;
  }
}
