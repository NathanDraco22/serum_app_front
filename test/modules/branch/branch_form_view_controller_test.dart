import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/branch/controllers/branch_form_view_controller.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  group('BranchFormViewController Tests', () {
    test('Inicialización por defecto en modo creación', () {
      final controller = BranchFormViewController();

      expect(controller.isEditing, isFalse);
      expect(controller.isSaving, isFalse);
      expect(controller.isUploadingAny, isFalse);

      expect(controller.nameController.text, isEmpty);
      expect(controller.addressController.text, isEmpty);
      expect(controller.phoneController.text, isEmpty);
      expect(controller.emailController.text, isEmpty);
      expect(controller.facebookController.text, isEmpty);

      expect(controller.bioanalystNameController.text, isEmpty);
      expect(controller.bioanalystTitleController.text, isEmpty);
      expect(controller.bioanalystCodeController.text, isEmpty);

      expect(controller.logoUrl, isNull);
      expect(controller.selectedLogoBytes, isNull);
      expect(controller.hasLogo, isFalse);

      expect(controller.isoLogoUrl, isNull);
      expect(controller.selectedIsoLogoBytes, isNull);
      expect(controller.hasIsoLogo, isFalse);

      expect(controller.sealUrl, isNull);
      expect(controller.selectedSealBytes, isNull);
      expect(controller.hasSeal, isFalse);

      expect(controller.auxBioList, isEmpty);

      controller.dispose();
    });

    test('Inicialización en modo edición con BranchInDb precargada', () {
      final aux = AuxBioanalyst(
        user: UserInfo(id: 'u-1', name: 'Dr. Perez'),
        bioanalyst: BioanalystInfo(
          name: 'Lic. Perez',
          title: 'Bioanalista',
          code: 'BIO-111',
          sealUrl: 'https://cdn.example.com/perez_seal.png',
        ),
      );

      final branch = BranchInDb(
        id: 'BR-100',
        name: 'Sucursal Norte',
        address: 'Km 5 Carretera Norte',
        phone: '2244-8899',
        email: 'norte@laboratorio.com',
        facebook: 'fb.com/laboratorionorte',
        logoUrl: 'https://cdn.example.com/logo.png',
        isoLogoUrl: 'https://cdn.example.com/isologo.png',
        bioanalyst: BranchBioanalyst(
          name: 'Lic. Joselin Lopez',
          title: 'TECNOLOGO MEDICO',
          code: 'MINSA 88027',
          sealUrl: 'https://cdn.example.com/seal.png',
        ),
        auxBio: [aux],
        createdAt: 1000,
      );

      final controller = BranchFormViewController(initialBranch: branch);

      expect(controller.isEditing, isTrue);
      expect(controller.nameController.text, equals('Sucursal Norte'));
      expect(controller.addressController.text, equals('Km 5 Carretera Norte'));
      expect(controller.phoneController.text, equals('2244-8899'));
      expect(controller.emailController.text, equals('norte@laboratorio.com'));
      expect(controller.facebookController.text, equals('fb.com/laboratorionorte'));

      expect(controller.bioanalystNameController.text, equals('Lic. Joselin Lopez'));
      expect(controller.bioanalystTitleController.text, equals('TECNOLOGO MEDICO'));
      expect(controller.bioanalystCodeController.text, equals('MINSA 88027'));

      expect(controller.logoUrl, equals('https://cdn.example.com/logo.png'));
      expect(controller.hasLogo, isTrue);

      expect(controller.isoLogoUrl, equals('https://cdn.example.com/isologo.png'));
      expect(controller.hasIsoLogo, isTrue);

      expect(controller.sealUrl, equals('https://cdn.example.com/seal.png'));
      expect(controller.hasSeal, isTrue);

      expect(controller.auxBioList.length, equals(1));
      expect(controller.auxBioList.first.bioanalyst.name, equals('Lic. Perez'));

      controller.dispose();
    });

    test('Mutaciones reactivas de Logotipo (setLogo y removeLogo)', () {
      final controller = BranchFormViewController();
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      final dummyBytes = Uint8List.fromList([1, 2, 3, 4]);
      controller.setLogo(bytes: dummyBytes, name: 'logo.png');

      expect(controller.selectedLogoBytes, equals(dummyBytes));
      expect(controller.selectedLogoName, equals('logo.png'));
      expect(controller.hasLogo, isTrue);
      expect(notifyCount, equals(1));

      controller.removeLogo();
      expect(controller.selectedLogoBytes, isNull);
      expect(controller.selectedLogoName, isNull);
      expect(controller.logoUrl, isNull);
      expect(controller.hasLogo, isFalse);
      expect(notifyCount, equals(2));

      controller.dispose();
    });

    test('Mutaciones reactivas de IsoLogo (setIsoLogo y removeIsoLogo)', () {
      final controller = BranchFormViewController();
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      final dummyBytes = Uint8List.fromList([10, 20, 30]);
      controller.setIsoLogo(bytes: dummyBytes, name: 'isologo.png');

      expect(controller.selectedIsoLogoBytes, equals(dummyBytes));
      expect(controller.selectedIsoLogoName, equals('isologo.png'));
      expect(controller.hasIsoLogo, isTrue);
      expect(notifyCount, equals(1));

      controller.removeIsoLogo();
      expect(controller.selectedIsoLogoBytes, isNull);
      expect(controller.selectedIsoLogoName, isNull);
      expect(controller.isoLogoUrl, isNull);
      expect(controller.hasIsoLogo, isFalse);
      expect(notifyCount, equals(2));

      controller.dispose();
    });

    test('Mutaciones reactivas de Sello (setSeal y removeSeal)', () {
      final controller = BranchFormViewController();
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      final dummyBytes = Uint8List.fromList([99, 88, 77]);
      controller.setSeal(bytes: dummyBytes, name: 'sello.png');

      expect(controller.selectedSealBytes, equals(dummyBytes));
      expect(controller.selectedSealName, equals('sello.png'));
      expect(controller.hasSeal, isTrue);
      expect(notifyCount, equals(1));

      controller.removeSeal();
      expect(controller.selectedSealBytes, isNull);
      expect(controller.selectedSealName, isNull);
      expect(controller.sealUrl, isNull);
      expect(controller.hasSeal, isFalse);
      expect(notifyCount, equals(2));

      controller.dispose();
    });

    test('Gestión reactiva de AuxBioanalyst (agregar, actualizar y remover)', () {
      final controller = BranchFormViewController();
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      final aux1 = AuxBioanalyst(
        user: UserInfo(id: 'u-1', name: 'User 1'),
        bioanalyst: BioanalystInfo(name: 'Aux 1', title: 'T1', code: 'C1'),
      );
      final aux2 = AuxBioanalyst(
        user: UserInfo(id: 'u-2', name: 'User 2'),
        bioanalyst: BioanalystInfo(name: 'Aux 2', title: 'T2', code: 'C2'),
      );

      // Agregar
      controller.addAuxBioanalyst(aux1);
      expect(controller.auxBioList.length, equals(1));
      expect(controller.auxBioList.first.bioanalyst.name, equals('Aux 1'));
      expect(notifyCount, equals(1));

      // Actualizar
      controller.updateAuxBioanalyst(0, aux2);
      expect(controller.auxBioList.length, equals(1));
      expect(controller.auxBioList.first.bioanalyst.name, equals('Aux 2'));
      expect(notifyCount, equals(2));

      // Remover
      controller.removeAuxBioanalyst(0);
      expect(controller.auxBioList, isEmpty);
      expect(notifyCount, equals(3));

      controller.dispose();
    });

    test('Generación de CreateBranch DTO con uploader inyectado', () async {
      final controller = BranchFormViewController();
      controller.nameController.text = 'Nueva Sucursal';
      controller.addressController.text = 'Calle Central';
      controller.phoneController.text = '2222-1111';
      controller.emailController.text = 'info@sucursal.com';
      controller.facebookController.text = 'fb.com/sucursal';

      controller.bioanalystNameController.text = 'Lic. Ana Morales';
      controller.bioanalystTitleController.text = 'BIOANALISTA CLINICA';
      controller.bioanalystCodeController.text = 'COL-9988';

      final logoBytes = Uint8List.fromList([1, 2, 3]);
      final isoBytes = Uint8List.fromList([4, 5, 6]);
      final sealBytes = Uint8List.fromList([7, 8, 9]);

      controller.setLogo(bytes: logoBytes, name: 'uploaded_logo.png');
      controller.setIsoLogo(bytes: isoBytes, name: 'uploaded_iso.png');
      controller.setSeal(bytes: sealBytes, name: 'uploaded_seal.png');

      final uploadedUrls = <String, String>{};

      Future<String?> mockUploader({
        required Uint8List bytes,
        required String fileName,
      }) async {
        final url = 'https://mock.cdn/$fileName';
        uploadedUrls[fileName] = url;
        return url;
      }

      final createDto = await controller.generateCreateDto(uploader: mockUploader);

      expect(createDto.name, equals('Nueva Sucursal'));
      expect(createDto.address, equals('Calle Central'));
      expect(createDto.phone, equals('2222-1111'));
      expect(createDto.email, equals('info@sucursal.com'));
      expect(createDto.facebook, equals('fb.com/sucursal'));
      expect(createDto.logoUrl, equals('https://mock.cdn/uploaded_logo.png'));
      expect(createDto.imageUrl, equals('https://mock.cdn/uploaded_logo.png'));
      expect(createDto.isoLogoUrl, equals('https://mock.cdn/uploaded_iso.png'));

      expect(createDto.bioanalyst, isNotNull);
      expect(createDto.bioanalyst!.name, equals('Lic. Ana Morales'));
      expect(createDto.bioanalyst!.title, equals('BIOANALISTA CLINICA'));
      expect(createDto.bioanalyst!.code, equals('COL-9988'));
      expect(createDto.bioanalyst!.sealUrl, equals('https://mock.cdn/uploaded_seal.png'));

      controller.dispose();
    });

    test('Generación de UpdateBranch DTO preservando URLs existentes', () async {
      final initialBranch = BranchInDb(
        id: 'BR-200',
        name: 'Sucursal Original',
        address: 'Dir Original',
        phone: '555-0000',
        logoUrl: 'https://cdn.example.com/original_logo.png',
        isoLogoUrl: 'https://cdn.example.com/original_iso.png',
        bioanalyst: BranchBioanalyst(
          name: 'Lic. Original',
          title: 'Regente',
          code: 'REG-1',
          sealUrl: 'https://cdn.example.com/original_seal.png',
        ),
        createdAt: 1000,
      );

      final controller = BranchFormViewController(initialBranch: initialBranch);
      controller.nameController.text = 'Sucursal Modificada';

      // No se seleccionan nuevos bytes, debe preservar las URLs previas
      final updateDto = await controller.generateUpdateDto();

      expect(updateDto.name, equals('Sucursal Modificada'));
      expect(updateDto.address, equals('Dir Original'));
      expect(updateDto.logoUrl, equals('https://cdn.example.com/original_logo.png'));
      expect(updateDto.isoLogoUrl, equals('https://cdn.example.com/original_iso.png'));
      expect(updateDto.bioanalyst?.sealUrl, equals('https://cdn.example.com/original_seal.png'));
      expect(updateDto.bioanalyst?.name, equals('Lic. Original'));

      controller.dispose();
    });

    test('Si todos los campos del Bioanalista están vacíos, bioanalyst es nulo', () async {
      final controller = BranchFormViewController();
      controller.nameController.text = 'Sede Simple';
      controller.addressController.text = 'Dirección Simple';
      controller.phoneController.text = '1234-5678';

      final createDto = await controller.generateCreateDto();
      expect(createDto.bioanalyst, isNull);

      final updateDto = await controller.generateUpdateDto();
      expect(updateDto.bioanalyst, isNull);

      controller.dispose();
    });

    test('Gestión reactiva de preferencia autoCalculateFormulas en creación y edición', () async {
      // 1. En creación: por defecto true
      final createController = BranchFormViewController();
      expect(createController.autoCalculateFormulas, isTrue);

      // Mutación reactiva
      bool notified = false;
      createController.addListener(() => notified = true);
      createController.setAutoCalculateFormulas(false);
      expect(createController.autoCalculateFormulas, isFalse);
      expect(notified, isTrue);

      createController.nameController.text = 'Sede Manual';
      createController.addressController.text = 'Calle 1';
      createController.phoneController.text = '123';
      final createDto = await createController.generateCreateDto();
      expect(createDto.autoCalculateFormulas, isFalse);
      createController.dispose();

      // 2. En edición: inicializa desde la sucursal existente
      final initialBranch = BranchInDb(
        id: 'BR-MANUAL',
        name: 'Sede Analizador',
        address: 'Calle 2',
        phone: '456',
        autoCalculateFormulas: false,
        createdAt: 1700000000000,
      );
      final editController = BranchFormViewController(initialBranch: initialBranch);
      expect(editController.autoCalculateFormulas, isFalse);

      editController.setAutoCalculateFormulas(true);
      expect(editController.autoCalculateFormulas, isTrue);

      final updateDto = await editController.generateUpdateDto();
      expect(updateDto.autoCalculateFormulas, isTrue);
      editController.dispose();
    });
  });
}
