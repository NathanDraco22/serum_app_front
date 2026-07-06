sealed class HttpServiceException implements Exception {
  HttpServiceException(this.message, this.body);
  final String message;
  final Map<String, dynamic> body;

  @override
  String toString() {
    const prefix = "HttpServiceException: ";

    if (this is! InternalRequestException && body.containsKey("detail")) {
      return prefix + body["detail"].toString();
    }

    return prefix + message;
  }
}

class NoInternetException extends HttpServiceException {
  NoInternetException(Map<String, dynamic> body) : super("NO_INTERNET", body);
}

class ServerException extends HttpServiceException {
  ServerException(Map<String, dynamic> body) : super("SERVER_ERROR", body);
}

class BadRequestException extends HttpServiceException {
  BadRequestException(Map<String, dynamic> body, this.statusCode) : super("CLIENT_ERROR", body);

  final int statusCode;
}

class UnauthorizedException extends HttpServiceException {
  UnauthorizedException(Map<String, dynamic> body) : super("UNAUTHORIZED", body);
}

class ForbiddenException extends HttpServiceException {
  ForbiddenException(Map<String, dynamic> body) : super("FORBIDDEN", body);
}

class InternalRequestException extends HttpServiceException {
  InternalRequestException(Map<String, dynamic> body) : super("INTERNAL_ERROR", body);
}
