import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:serum_business/serum_business.dart';

/// Gestor centralizado de caché de imágenes para Serum App.
/// Garantiza que los recursos visuales (como logotipos e isologos institucionales)
/// se descarguen una sola vez, persistan en disco y memoria, y se reutilicen
/// instantáneamente tanto en la UI como en la generación de documentos PDF.
class AppImageCache {
  AppImageCache._();

  static final BaseCacheManager _manager = DefaultCacheManager();

  /// Precarga proactivamente en segundo plano el logotipo e isologo de la sucursal activa.
  /// Puede ejecutarse al arrancar sesión o cambiar de sucursal.
  static Future<void> precacheBranchLogos(BranchInDb branch, [BuildContext? context]) async {
    final logo = branch.effectiveLogo;
    final iso = branch.effectiveIsoLogo;

    final futures = <Future<void>>[];
    if (logo != null && logo.isNotEmpty) {
      futures.add(_precacheUrl(logo, context));
    }
    if (iso != null && iso.isNotEmpty && iso != logo) {
      futures.add(_precacheUrl(iso, context));
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  static Future<void> _precacheUrl(String url, [BuildContext? context]) async {
    try {
      if (context != null && context.mounted) {
        await precacheImage(CachedNetworkImageProvider(url), context);
      } else {
        await _manager.getSingleFile(url);
      }
    } catch (_) {
      // Evitar que fallos de red en la precarga interrumpan la UI
    }
  }

  /// Obtiene los bytes de una imagen desde la caché local en disco o descargándola una sola vez.
  /// Optimizado para la generación de reportes y plantillas PDF sin peticiones HTTP redundantes.
  static Future<Uint8List?> getImageBytes(String url) async {
    if (url.trim().isEmpty) return null;
    try {
      final fileInfo = await _manager.getFileFromCache(url);
      if (fileInfo != null) {
        return await fileInfo.file.readAsBytes();
      }
      final file = await _manager.getSingleFile(url);
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  /// Invalida y remueve una imagen de la caché en disco y memoria (ej. cuando se sube un nuevo logo).
  static Future<void> evict(String url) async {
    if (url.trim().isEmpty) return;
    try {
      await _manager.removeFile(url);
      await CachedNetworkImage.evictFromCache(url);
    } catch (_) {}
  }
}
