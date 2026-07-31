import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget child;
    final trimmedUrl = imageUrl.trim();

    if (trimmedUrl.isEmpty) {
      child = _buildPlaceholder(context);
    } else if (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://')) {
      child = CachedNetworkImage(
        imageUrl: trimmedUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: isDark ? const Color(0xFF1C2333) : const Color(0xFFF1F5F9),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.primary.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(context),
      );
    } else if (trimmedUrl.startsWith('assets/')) {
      child = Image.asset(
        trimmedUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
      );
    } else {
      child = _buildPlaceholder(context);
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }

    return child;
  }

  Widget _buildPlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      color: isDark ? const Color(0xFF1C2333) : const Color(0xFFF8FAFC),
      child: Center(
        child: Icon(
          Icons.devices_other_rounded,
          size: (height != null && height! < 80) ? 24 : 36,
          color: cs.primary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
