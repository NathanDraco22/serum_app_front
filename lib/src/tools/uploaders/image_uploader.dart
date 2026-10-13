import 'dart:typed_data';

import 'package:serum_business/serum_business.dart';

import '../../../config/service_locator.dart';
import '../../cubits/app_session_cubit/app_session_cubit.dart';

class _ImageUploaderService with HttpService {}

class ImageUploader {
  static final _service = _ImageUploaderService();

  static const String _servinCoreUrl = String.fromEnvironment(
    "ORIGIN_SERVER_URL",
    defaultValue: "",
  );

  static Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
    String mediaType = "image/jpeg",
    String? folder,
    String appName = "neptuno",
  }) async {
    String resolvedFolder = folder ?? "";
    if (resolvedFolder.isEmpty) {
      if (sl.isRegistered<AppSessionCubit>()) {
        final session = sl<AppSessionCubit>();
        resolvedFolder = session.currentBranch?.id ?? session.user?.username ?? "origin";
      } else {
        resolvedFolder = "origin";
      }
    }

    final baseUrl = _servinCoreUrl.isNotEmpty ? _servinCoreUrl : SerumClient.instance.baseUrl;

    final uri = Uri.parse("$baseUrl/api/v1/images/upload/$appName/$resolvedFolder");
    final headers = HttpTools.generateAuthHeaders();

    final response = await _service.multipartQuery(
      uri,
      bytes,
      fileName: fileName,
      mediaType: mediaType,
      headers: headers,
      fieldName: "image",
    );

    final url = response['url'] as String?;
    if (url == null) {
      throw Exception("Failed to retrieve image URL from upload response.");
    }

    return url;
  }
}
