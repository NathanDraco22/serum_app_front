import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget reutilizable y optimizado para el renderizado de imágenes de red en Serum App.
/// Integra `cached_network_image` con caché dual (RAM y disco), transiciones suaves y
/// fallbacks automáticos, evitando parpadeos y retrasos durante la captura o tipeo en formularios.
class AppCachedImage extends StatelessWidget {
  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
    this.fallbackWidget,
    this.fadeInDuration = const Duration(milliseconds: 150),
    this.fadeOutDuration = const Duration(milliseconds: 150),
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final Widget? fallbackWidget;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final int? memCacheWidth;
  final int? memCacheHeight;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return fallbackWidget ?? const SizedBox.shrink();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: placeholder ??
          (context, url) => SizedBox(
                width: width,
                height: height,
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
      errorWidget: errorWidget ??
          (context, url, error) =>
              fallbackWidget ??
              Icon(
                Icons.broken_image_outlined,
                size: (height != null && height! < 32) ? height : 28,
                color: Theme.of(context).colorScheme.error,
              ),
    );
  }
}
