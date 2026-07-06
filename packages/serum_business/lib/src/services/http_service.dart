import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'exceptions/http_exceptions.dart';

mixin HttpService {
  Future<Map<String, dynamic>> getQuery(Uri url, {Map<String, String>? headers}) async {
    late http.Response response;

    try {
      response = await http.get(url, headers: headers);
    } catch (error) {
      throw NoInternetException({"message": error.toString()});
    }

    final utf8Body = utf8.decode(response.bodyBytes);
    final body = jsonDecode(utf8Body) as Map<String, dynamic>;

    _processStatusCode(response.statusCode, body);

    return body;
  }

  Future<Map<String, dynamic>> postQuery(Uri url, Map<String, dynamic> body, {Map<String, String>? headers}) async {
    final jsonEncoded = jsonEncode(body);
    final contentType = {'Content-Type': 'application/json'};

    final applicationHeaders = {...contentType, ...headers ?? {}};

    late http.Response response;

    try {
      response = await http.post(url, body: jsonEncoded, headers: applicationHeaders);
    } catch (error) {
      throw NoInternetException({"message": error.toString()});
    }

    final utf8Body = utf8.decode(response.bodyBytes);
    final decodedBody = jsonDecode(utf8Body) as Map<String, dynamic>;

    _processStatusCode(response.statusCode, decodedBody);

    return decodedBody;
  }

  Future<Map<String, dynamic>> putQuery(Uri url, Map<String, dynamic> body, {Map<String, String>? headers}) async {
    final jsonEncoded = jsonEncode(body);
    final contentType = {'Content-Type': 'application/json'};

    final applicationHeaders = {...contentType, ...headers ?? {}};

    late http.Response response;

    try {
      response = await http.put(url, body: jsonEncoded, headers: applicationHeaders);
    } catch (error) {
      throw NoInternetException({"message": error.toString()});
    }

    final utf8Body = utf8.decode(response.bodyBytes);
    final decodedBody = jsonDecode(utf8Body) as Map<String, dynamic>;

    _processStatusCode(response.statusCode, decodedBody);

    return decodedBody;
  }

  Future<Map<String, dynamic>> patchQuery(Uri url, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    String? jsonEncoded;
    if (body != null) jsonEncoded = jsonEncode(body);

    final contentType = {'Content-Type': 'application/json'};
    final applicationHeaders = {...contentType, ...headers ?? {}};

    late http.Response response;

    try {
      response = await http.patch(url, body: jsonEncoded, headers: applicationHeaders);
    } catch (error) {
      throw NoInternetException({"message": error.toString()});
    }

    final utf8Body = utf8.decode(response.bodyBytes);
    final decodedBody = jsonDecode(utf8Body) as Map<String, dynamic>;

    _processStatusCode(response.statusCode, decodedBody);

    return decodedBody;
  }

  Future<Map<String, dynamic>> deleteQuery(Uri url, {Map<String, String>? headers}) async {
    late http.Response response;

    try {
      response = await http.delete(url, headers: headers);
    } catch (error) {
      throw NoInternetException({"message": error.toString()});
    }

    final utf8Body = utf8.decode(response.bodyBytes);
    final decodedBody = jsonDecode(utf8Body) as Map<String, dynamic>;

    _processStatusCode(response.statusCode, decodedBody);

    return decodedBody;
  }

  Future<Map<String, dynamic>> multipartQuery(
    Uri url,
    Uint8List bytes, {
    String fileName = "",
    String mediaType = "image/jpeg",
    Map<String, String>? headers,
  }) async {
    final request = http.MultipartRequest("POST", url);

    if (headers != null) {
      request.headers.addAll(headers);
    }

    request.files.add(
      http.MultipartFile.fromBytes("file", bytes, filename: fileName, contentType: MediaType.parse(mediaType)),
    );

    late http.Response response;

    try {
      final bytesRequest = await request.send();
      response = await http.Response.fromStream(bytesRequest);
    } catch (error) {
      throw NoInternetException({"message": error.toString()});
    }

    final utf8Body = utf8.decode(response.bodyBytes);
    final content = jsonDecode(utf8Body) as Map<String, dynamic>;

    _processStatusCode(response.statusCode, content);

    return content;
  }

  void _processStatusCode(int statusCode, Map<String, dynamic> body) {
    if (statusCode >= 500) {
      throw ServerException(body);
    }

    if (statusCode == 401) {
      throw UnauthorizedException(body);
    }

    if (statusCode == 403) {
      throw ForbiddenException(body);
    }

    if (statusCode >= 400) {
      throw BadRequestException(body, statusCode);
    }
  }
}
