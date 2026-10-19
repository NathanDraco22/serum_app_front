import 'package:flutter_test/flutter_test.dart';
import 'package:serum_business/serum_business.dart';

class _MockConfig implements SerumClientConfig {
  @override
  String baseUrl = 'http://localhost:8000';

  @override
  String authToken = '';

  @override
  String? branchId;

  @override
  String? servinNickname;
}

void main() {
  group('HttpTools Tenant & Auth Headers Tests', () {
    late _MockConfig mockConfig;

    setUp(() {
      mockConfig = _MockConfig();
      SerumClient.initialize(mockConfig);
    });

    test('generateTenantHeaders incluye x-servin y x-branch en minúsculas cuando están presentes', () {
      mockConfig.servinNickname = 'clinica_central';
      mockConfig.branchId = 'BR-001';

      final headers = HttpTools.generateTenantHeaders();

      expect(headers['X-Agent'], equals('Serum'));
      expect(headers['x-servin'], equals('clinica_central'));
      expect(headers['x-branch'], equals('BR-001'));
      expect(headers.containsKey('X-Servin'), isFalse);
      expect(headers.containsKey('X-Branch'), isFalse);
    });

    test('generateTenantHeaders omite x-branch si branchId es nulo o vacío', () {
      mockConfig.servinNickname = 'laboratorio_norte';
      mockConfig.branchId = null;

      final headers = HttpTools.generateTenantHeaders();

      expect(headers['x-servin'], equals('laboratorio_norte'));
      expect(headers.containsKey('x-branch'), isFalse);

      mockConfig.branchId = '';
      final headersEmpty = HttpTools.generateTenantHeaders();
      expect(headersEmpty.containsKey('x-branch'), isFalse);
    });

    test('generateAuthHeaders incluye Authorization con token además de x-servin y x-branch', () {
      mockConfig.servinNickname = 'lab_demo';
      mockConfig.branchId = 'BRANCH-ORIGIN';
      mockConfig.authToken = 'my-jwt-session-token';

      final headers = HttpTools.generateAuthHeaders();

      expect(headers['x-servin'], equals('lab_demo'));
      expect(headers['x-branch'], equals('BRANCH-ORIGIN'));
      expect(headers['Authorization'], equals('Bearer my-jwt-session-token'));
      expect(headers['X-Agent'], equals('Serum'));
    });

    test('generateUri genera URIs correctas para HTTP con puerto, sin puerto y HTTPS', () {
      mockConfig.baseUrl = 'http://localhost:8000';
      final uriWithPort = HttpTools.generateUri('/patients');
      expect(uriWithPort.toString(), equals('http://localhost:8000/api/v1/patients'));

      mockConfig.baseUrl = 'http://api.laboratorio.com';
      final uriHttpNoPort = HttpTools.generateUri('/orders');
      expect(uriHttpNoPort.scheme, equals('http'));
      expect(uriHttpNoPort.host, equals('api.laboratorio.com'));
      expect(uriHttpNoPort.path, equals('/api/v1/orders'));

      mockConfig.baseUrl = 'https://cloud.serumlis.com';
      final uriHttps = HttpTools.generateUri('/lab-tests');
      expect(uriHttps.scheme, equals('https'));
      expect(uriHttps.host, equals('cloud.serumlis.com'));
      expect(uriHttps.path, equals('/api/v1/lab-tests'));
    });
  });
}
