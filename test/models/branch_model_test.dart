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
        'sealUrl': 'https://server.com/images/sello_bioanalista.png',
      };

      final bio = BranchBioanalyst.fromJson(bioJson);
      expect(bio.name, equals('Lic. Joselin Lopez'));
      expect(bio.title, equals('TECNOLOGO MEDICO'));
      expect(bio.code, equals('Codigo MINSA 88027'));
      expect(bio.sealUrl, equals('https://server.com/images/sello_bioanalista.png'));
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
      expect(branch.bioanalyst!.sealUrl, equals('https://server.com/images/sello_bioanalista.png'));

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

    test('Serialización y deserialización de AuxBioanalyst y auxBio en Branch', () {
      final auxJson = {
        'user': {'id': 'user-101', 'name': 'Lic. Auxiliar Maria'},
        'bioanalyst': {
          'name': 'Lic. Auxiliar Maria',
          'title': 'MICROBIOLOGA',
          'code': 'MINSA 77112',
          'sealUrl': 'https://cdn.example.com/seals/aux_maria.png',
        },
      };

      final aux = AuxBioanalyst.fromJson(auxJson);
      expect(aux.user.id, equals('user-101'));
      expect(aux.user.name, equals('Lic. Auxiliar Maria'));
      expect(aux.bioanalyst.name, equals('Lic. Auxiliar Maria'));
      expect(aux.bioanalyst.title, equals('MICROBIOLOGA'));
      expect(aux.bioanalyst.code, equals('MINSA 77112'));
      expect(aux.bioanalyst.sealUrl, equals('https://cdn.example.com/seals/aux_maria.png'));
      expect(aux.toJson(), equals(auxJson));

      final branchJson = {
        'id': 'BR-AUX',
        'name': 'Sucursal con Auxiliares',
        'address': 'Avenida Central',
        'phone': '12345678',
        'bioanalyst': {
          'name': 'Lic. Titular',
          'title': 'TITULAR',
          'code': '123',
        },
        'auxBio': [auxJson],
        'createdAt': 1700000000000,
      };

      final branch = BranchInDb.fromJson(branchJson);
      expect(branch.auxBio, isNotNull);
      expect(branch.auxBio!.length, equals(1));
      expect(branch.auxBio!.first.user.name, equals('Lic. Auxiliar Maria'));
      expect(branch.auxBio!.first.bioanalyst.sealUrl, equals('https://cdn.example.com/seals/aux_maria.png'));

      final createBranch = CreateBranch(
        name: 'Sede Aux',
        address: 'Dir',
        phone: '111',
        auxBio: [aux],
      );
      expect(createBranch.toJson()['auxBio'], equals([auxJson]));

      final updateBranch = UpdateBranch(
        auxBio: [aux],
      );
      expect(updateBranch.toJson()['auxBio'], equals([auxJson]));
    });

    test('Configuración autoCalculateFormulas: retrocompatibilidad, serialización y valor por defecto', () {
      // 1. Retrocompatibilidad: si no está en el JSON, es true
      final legacyJson = {
        'id': 'BR-LEGACY',
        'name': 'Sucursal Antigua',
        'address': 'Calle 1',
        'phone': '123',
        'createdAt': 1700000000000,
      };
      final branchLegacy = BranchInDb.fromJson(legacyJson);
      expect(branchLegacy.autoCalculateFormulas, isTrue);

      // 2. Si viene explícitamente en false
      final manualJson = {
        'id': 'BR-MANUAL',
        'name': 'Sucursal Manual',
        'address': 'Calle 2',
        'phone': '456',
        'autoCalculateFormulas': false,
        'createdAt': 1700000000000,
      };
      final branchManual = BranchInDb.fromJson(manualJson);
      expect(branchManual.autoCalculateFormulas, isFalse);

      // 3. CreateBranch serializa autoCalculateFormulas
      final createBranch = CreateBranch(
        name: 'Sede Auto Off',
        address: 'Calle 3',
        phone: '789',
        autoCalculateFormulas: false,
      );
      expect(createBranch.toJson()['autoCalculateFormulas'], isFalse);

      // 4. UpdateBranch incluye autoCalculateFormulas solo si no es nulo
      final updateBranch = UpdateBranch(autoCalculateFormulas: false);
      expect(updateBranch.toJson()['autoCalculateFormulas'], isFalse);

      final updateBranchNull = UpdateBranch();
      expect(updateBranchNull.toJson().containsKey('autoCalculateFormulas'), isFalse);
    });
  });
}
