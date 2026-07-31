import '../user_model/user_model.dart';

class LoginRequest {
  final String? username;
  final String? email;
  final String? phone;
  final String password;

  LoginRequest({
    this.username,
    this.email,
    this.phone,
    required this.password,
  });

  factory LoginRequest.fromInput(String input, String password) {
    final trimmed = input.trim();
    if (trimmed.contains('@')) {
      return LoginRequest(email: trimmed, password: password);
    } else if (RegExp(r'^\+?[0-9\s\-]+$').hasMatch(trimmed) && trimmed.length >= 7) {
      return LoginRequest(phone: trimmed, password: password);
    } else {
      return LoginRequest(username: trimmed, password: password);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'phone': phone,
      'password': password,
    };
  }
}

class LoginResponse {
  final UserInDb user;
  final String token;
  final String refreshToken;

  LoginResponse({
    required this.user,
    required this.token,
    required this.refreshToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: UserInDb.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}

class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {
      'refreshToken': refreshToken,
    };
  }
}

class RefreshTokenResponse {
  final String token;
  final String refreshToken;

  RefreshTokenResponse({
    required this.token,
    required this.refreshToken,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}

class CheckUserRequest {
  final String token;

  CheckUserRequest({required this.token});

  Map<String, dynamic> toJson() {
    return {
      'token': token,
    };
  }
}

class CheckUserResponse {
  final String status;

  CheckUserResponse({required this.status});

  bool get isActive => status == 'active';
  bool get isUnactive => status == 'unactive';
  bool get isDeleted => status == 'deleted';

  factory CheckUserResponse.fromJson(Map<String, dynamic> json) {
    return CheckUserResponse(
      status: json['status'] as String,
    );
  }
}
