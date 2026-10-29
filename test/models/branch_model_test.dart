import 'package:flutter_test/flutter_test.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  group('Branch Model & Brand Hierarchy Tests', () {
    test('Serialización y deserialización completa con email, facebook e imágenes', () {
      final json = {
        'id': 'BR-001',
        'name': 'Sucursal Centro',
        'address': 'Av. Juárez 123',
        'phone': '555-123-4567',
        'email': 'centro@serumlab.com',
        'facebook': 'facebook.com/serumcentro',
        'logoUrl': 'https://server.com/images/logo.png',
        'imageUrl': 'https://server.com/images/logo.png',
        'isoLogoUrl': 'https://server.com/images/isologo.png',
        'createdAt': 1700000000000,
        'updatedAt': 1700005000000,
        'isDeleted': false,
      };

      final branch = BranchInDb.fromJson(json);

      expect(branch.id, equals('BR-001'));
      expect(branch.name, equals('Sucursal Centro'));
      expect(branch.email, equals('centro@serumlab.com'));
      expect(branch.facebook, equals('facebook.com/serumcentro'));
      expect(branch.logoUrl, equals('https://server.com/images/logo.png'));
      expect(branch.isoLogoUrl, equals('https://server.com/images/isologo.png'));
      expect(branch.effectiveLogo, equals('https://server.com/images/logo.png'));
      expect(branch.effectiveIsoLogo, equals('https://server.com/images/isologo.png'));
    });

    test('Retrocompatibilidad: mapea imageUrl a logoUrl si logoUrl es nulo', () {
      final legacyJson = {
        'id': 'BR-LEGACY',
        'name': 'Sucursal Antigua',
        'address': 'Calle Vieja 456',
        'phone': '555-000-0000',
        'imageUrl': 'https://server.com/images/old_logo.png',
        'createdAt': 1690000000000,
      };

      final branch = BranchInDb.fromJson(legacyJson);

      expect(branch.email, isNull);
      expect(branch.facebook, isNull);
      expect(branch.imageUrl, equals('https://server.com/images/old_logo.png'));
      expect(branch.logoUrl, equals('https://server.com/images/old_logo.png'));
      expect(branch.isoLogoUrl, isNull);
      expect(branch.effectiveLogo, equals('https://server.com/images/old_logo.png'));
      // Fallback: Si no hay isoLogoUrl, effectiveIsoLogo retorna effectiveLogo
      expect(branch.effectiveIsoLogo, equals('https://server.com/images/old_logo.png'));
    });

    test('effectiveIsoLogo da prioridad a isoLogoUrl sobre logoUrl e imageUrl', () {
      final branch = BranchInDb(
        id: 'BR-TEST',
        name: 'Test Sede',
        address: 'Dirección',
        phone: '123',
        logoUrl: 'https://server.com/logo.png',
        isoLogoUrl: 'https://server.com/isologo.png',
        createdAt: 1700000000000,
      );

      expect(branch.effectiveLogo, equals('https://server.com/logo.png'));
      expect(branch.effectiveIsoLogo, equals('https://server.com/isologo.png'));
    });

    test('effectiveLogo y effectiveIsoLogo retornan null cuando no hay imágenes configuradas', () {
      final branch = BranchInDb(
        id: 'BR-EMPTY',
        name: 'Sin Logos',
        address: 'Dirección',
        phone: '123',
        createdAt: 1700000000000,
      );

      expect(branch.effectiveLogo, isNull);
      expect(branch.effectiveIsoLogo, isNull);
    });

    test('CreateBranch genera json correctamente con campos opcionales omitidos si son nulos', () {
      final createFull = CreateBranch(
        name: 'Nueva Sede',
        address: 'Av. Test',
        phone: '555',
        email: 'test@lab.com',
        facebook: 'fb/test',
        logoUrl: 'http://logo',
        isoLogoUrl: 'http://isologo',
      );

      final fullJson = createFull.toJson();
      expect(fullJson['email'], equals('test@lab.com'));
      expect(fullJson['facebook'], equals('fb/test'));
      expect(fullJson['logoUrl'], equals('http://logo'));
      expect(fullJson['isoLogoUrl'], equals('http://isologo'));

      final createMinimal = CreateBranch(
        name: 'Min Sede',
        address: 'Av. Min',
        phone: '111',
      );

      final minJson = createMinimal.toJson();
      expect(minJson.containsKey('email'), isFalse);
      expect(minJson.containsKey('facebook'), isFalse);
      expect(minJson.containsKey('logoUrl'), isFalse);
      expect(minJson.containsKey('isoLogoUrl'), isFalse);
      expect(minJson.containsKey('bioanalyst'), isFalse);
    });

    test('Serialización y deserialización de BranchBioanalyst en BranchInDb y CreateBranch', () {
      final bioJson = {
        'name': 'Lic. Joselin Lopez',
        'title': 'TECNOLOGO MEDICO',
        'code': 'Codigo MINSA 88027',
      };

      final bio = BranchBioanalyst.fromJson(bioJson);
      expect(bio.name, equals('Lic. Joselin Lopez'));
      expect(bio.title, equals('TECNOLOGO MEDICO'));
      expect(bio.code, equals('Codigo MINSA 88027'));
      expect(bio.toJson(), equals(bioJson));

      final branchJson = {
        'id': 'BR-BIO',
        'name': 'Sucursal con Bioanalista',
        'address': 'Calle Real #10',
        'phone': '555-9999',
        'bioanalyst': bioJson,
        'createdAt': 1700000000000,
      };

      final branch = BranchInDb.fromJson(branchJson);
      expect(branch.bioanalyst, isNotNull);
      expect(branch.bioanalyst!.name, equals('Lic. Joselin Lopez'));
      expect(branch.bioanalyst!.title, equals('TECNOLOGO MEDICO'));
      expect(branch.bioanalyst!.code, equals('Codigo MINSA 88027'));

      final createWithBio = CreateBranch(
        name: 'Sede Bio',
        address: 'Dirección Bio',
        phone: '123456',
        bioanalyst: bio,
      );
      final createJson = createWithBio.toJson();
      expect(createJson['bioanalyst'], equals(bioJson));

      final updateWithBio = UpdateBranch(
        bioanalyst: bio,
      );
      final updateJson = updateWithBio.toJson();
      expect(updateJson['bioanalyst'], equals(bioJson));
    });
  });
}
