import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/tools/exports/pdf/templates/clinical_order_pdf_template.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (methodCall) async => '.',
    );
  });

  group('SingleClinicalOrderTemplate Tests', () {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final mockOrder = OrderInDb(
      id: 'ord-12345678',
      patientId: 'pat-1',
      doctorId: 'doc-1',
      branchId: 'br-1',
      items: [
        OrderItem(
          labTestId: 'lt-1',
          name: 'Perfil Lipídico Completo',
          salePriceApplied: 35000,
        ),
      ],
      status: 'completed',
      totalPrice: 35000,
      paidAmount: 35000,
      results: [
        OrderTestResult(
          labTestId: 'lt-1',
          parameterName: 'Colesterol Total',
          medicalClassification: 'Bioquímica',
          dataType: 'numeric',
          unitOfMeasure: 'mg/dL',
          referenceValues: [
            ReferenceValue(
              patientType: 'general',
              gender: 'any',
              minAgeDays: 0,
              maxAgeDays: 36500,
              minValue: 100,
              maxValue: 200,
            ),
          ],
          qualitativeOptions: [],
          resultValue: '185',
        ),
      ],
      createdAt: nowMs,
      patientInfo: PatientInfo(
        name: 'Carlos Mendoza',
        dateOfBirth: nowMs - (30 * 365 * 86400000),
        gender: 'M',
        phone: '555-0192',
        address: 'Av. Siempre Viva 123',
      ),
      doctorInfo: DoctorInfo(
        name: 'Dr. Roberto Gómez',
        specialty: 'Medicina Interna',
        phone: '555-9988',
      ),
    );

    test('Construye PDF correctamente cuando la sucursal no tiene imageUrl', () async {
      final branchWithoutImage = BranchInDb(
        id: 'br-1',
        name: 'Laboratorio Clínico Serum Matriz',
        address: 'Calle Principal 456',
        phone: 'PBX 2222-0000',
        imageUrl: null,
        createdAt: nowMs,
      );

      final template = SingleClinicalOrderTemplate(
        order: mockOrder,
        branch: branchWithoutImage,
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('Construye PDF correctamente cuando la sucursal tiene imageUrl', () async {
      final branchWithImage = BranchInDb(
        id: 'br-1',
        name: 'Laboratorio Clínico Serum Matriz',
        address: 'Calle Principal 456',
        phone: 'PBX 2222-0000',
        imageUrl: 'https://example.com/logo_non_existent.jpg',
        createdAt: nowMs,
      );

      final template = SingleClinicalOrderTemplate(
        order: mockOrder,
        branch: branchWithImage,
      );

      // Si la URL no es accesible en test, se gestiona y no arroja excepción no capturada
      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });

    test(
      'Construye PDF correctamente con valores nulos (fallbacks de guion) y caracteres especiales',
      () async {
        final branch = BranchInDb(
          id: 'br-1',
          name: 'Laboratorio Clínico Serum',
          address: 'Calle 10',
          phone: 'PBX 2222',
          createdAt: nowMs,
        );

        final orderWithNulls = OrderInDb(
          id: 'ord-nulls-unicode',
          patientId: mockOrder.patientId,
          doctorId: mockOrder.doctorId,
          branchId: mockOrder.branchId,
          items: mockOrder.items,
          status: mockOrder.status,
          totalPrice: mockOrder.totalPrice,
          paidAmount: mockOrder.paidAmount,
          createdAt: nowMs,
          patientInfo: mockOrder.patientInfo,
          doctorInfo: mockOrder.doctorInfo,
          results: [
            OrderTestResult(
              labTestId: 'lt-unicode',
              parameterName: 'Prueba Especial con Símbolos (≥, ≤, µ, °C, —)',
              medicalClassification: 'Inmunología',
              dataType: 'numeric',
              unitOfMeasure: '', // Dispara el fallback '-'
              referenceValues: [],
              qualitativeOptions: [],
              resultValue: null, // Dispara el fallback '-'
            ),
          ],
        );

        final template = SingleClinicalOrderTemplate(
          order: orderWithNulls,
          branch: branch,
        );

        final doc = await template.buildDocument();
        final bytes = await doc.save();

        expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
        expect(bytes.isNotEmpty, isTrue);
      },
    );

    test('Construye PDF correctamente con Biometría Hemática, subseries y alertas H/L', () async {
      final branch = BranchInDb(
        id: 'br-1',
        name: 'Laboratorio Clínico Serum',
        address: 'Calle Principal',
        phone: 'PBX 2222',
        createdAt: nowMs,
      );

      final hemogramOrder = OrderInDb(
        id: 'ord-hemogram-full',
        patientId: 'pat-1',
        branchId: 'br-1',
        items: [
          OrderItem(
            labTestId: 'lt-bh',
            name: 'Biometría Hemática Completa',
            salePriceApplied: 25000,
          ),
        ],
        status: 'completed',
        totalPrice: 25000,
        paidAmount: 25000,
        createdAt: nowMs,
        patientInfo: PatientInfo(
          name: 'Ana Martínez',
          dateOfBirth: nowMs - (25 * 365 * 86400000),
          gender: 'F',
        ),
        results: [
          OrderTestResult(
            labTestId: 'lt-bh',
            parameterName: 'Eritrocitos',
            medicalClassification: 'SERIE ROJA',
            dataType: 'numeric',
            unitOfMeasure: 'xmm3',
            referenceValues: [
              ReferenceValue(
                patientType: 'general',
                gender: 'f',
                minAgeDays: 0,
                maxAgeDays: 36500,
                minValue: 3.78,
                maxValue: 5.7,
              ),
            ],
            resultValue: '5.000',
          ),
          OrderTestResult(
            labTestId: 'lt-bh',
            parameterName: 'Linfocitos',
            medicalClassification: 'DIFERENCIAL',
            dataType: 'numeric',
            unitOfMeasure: '%',
            referenceValues: [
              ReferenceValue(
                patientType: 'general',
                gender: 'any',
                minAgeDays: 0,
                maxAgeDays: 36500,
                minValue: 20.0,
                maxValue: 40.0,
              ),
            ],
            resultValue: '42',
            alertFlag: 'HIGH', // Dispara 'H'
          ),
          OrderTestResult(
            labTestId: 'lt-bh',
            parameterName: 'TOTAL',
            medicalClassification: 'DIFERENCIAL',
            dataType: 'numeric',
            unitOfMeasure: '',
            referenceValues: [],
            resultValue: '100',
          ),
        ],
      );

      final template = SingleClinicalOrderTemplate(
        order: hemogramOrder,
        branch: branch,
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('Genera PDF correctamente para prueba con referenceText multilínea (HbA1c)', () async {
      final hba1cOrder = OrderInDb(
        id: 'ord-hba1c-1',
        patientId: 'pat-1',
        doctorId: 'doc-1',
        branchId: 'br-1',
        items: [
          OrderItem(
            labTestId: 'lt-hba1c',
            name: 'Glicohemoglobina A1c (HbA1c)',
            salePriceApplied: 2500,
          ),
        ],
        status: 'completed',
        totalPrice: 2500,
        paidAmount: 2500,
        results: [
          OrderTestResult(
            labTestId: 'lt-hba1c',
            parameterName: 'Glicohemoglobina A1c HbA1c',
            medicalClassification: 'Química Sanguínea',
            dataType: 'numeric',
            unitOfMeasure: '%',
            referenceValues: [
              ReferenceValue(
                patientType: 'general',
                gender: 'both',
                minAgeDays: 0,
                maxAgeDays: 43800,
                minValue: 4.0,
                maxValue: 5.6,
              ),
            ],
            referenceText:
                '- Menor de 5.6%: Nivel no diabético\n- 5.7 - 6.4%: Nivel prediabético\n- Mayor de 6.5%: Diagnosticado diabético\n- NOTA: 4.5 - 8.4%: Metabolismo normal O Diabético Controlado\n- (Mayor de 8.5%: Diabético mal controlado o Metabolismo desequilibrado)',
            resultValue: '6.0',
            alertFlag: 'HIGH',
          ),
        ],
        createdAt: nowMs,
        patientInfo: PatientInfo(
          name: 'Maribel Lopez',
          dateOfBirth: nowMs - (53 * 365 * 86400000),
          gender: 'F',
        ),
      );

      final branchWithoutImage = BranchInDb(
        id: 'br-1',
        name: 'Laboratorio Clínico Serum Matriz',
        address: 'Calle Principal 456',
        phone: 'PBX 2222-0000',
        imageUrl: null,
        createdAt: nowMs,
      );

      final template = SingleClinicalOrderTemplate(
        order: hba1cOrder,
        branch: branchWithoutImage,
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });

    test(
      'Genera PDF correctamente para orden con parámetros de texto libre (dataType: text) multilínea',
      () async {
        final textOrder = OrderInDb(
          id: 'ord-text-1',
          patientId: 'pat-1',
          doctorId: 'doc-1',
          branchId: 'br-1',
          items: [
            OrderItem(
              labTestId: 'lt-biopsia',
              name: 'Biopsia de Piel y Tejidos Blandos',
              salePriceApplied: 5000,
            ),
          ],
          status: 'completed',
          totalPrice: 5000,
          paidAmount: 5000,
          results: [
            OrderTestResult(
              labTestId: 'lt-macro',
              parameterName: 'Descripción Macroscópica',
              medicalClassification: 'Histopatología',
              dataType: 'text',
              resultValue:
                  'Se recibe espécimen fijado en formol que mide 2.5 x 1.8 x 0.6 cm.\nSuperficie cutánea parda clara con lesión sobreelevada central.',
            ),
            OrderTestResult(
              labTestId: 'lt-micro',
              parameterName: 'Diagnóstico Histopatológico',
              medicalClassification: 'Histopatología',
              dataType: 'text',
              resultValue:
                  'Los cortes histológicos confirman Queratoacantoma bien diferenciado con bordes quirúrgicos libres de lesión.\nNo se observan signos de invasión vascular ni perineural.',
              referenceText: 'Clasificación de malignidad según criterios OMS.',
            ),
          ],
          createdAt: nowMs,
          patientInfo: PatientInfo(
            name: 'Carlos Mendoza',
            dateOfBirth: nowMs - (45 * 365 * 86400000),
            gender: 'M',
          ),
        );

        final branchWithoutImage = BranchInDb(
          id: 'br-1',
          name: 'Laboratorio Clínico Serum Matriz',
          address: 'Calle Principal 456',
          phone: 'PBX 2222-0000',
          imageUrl: null,
          createdAt: nowMs,
        );

        final template = SingleClinicalOrderTemplate(
          order: textOrder,
          branch: branchWithoutImage,
        );

        final doc = await template.buildDocument();
        final bytes = await doc.save();

        expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
        expect(bytes.isNotEmpty, isTrue);
      },
    );

    test('Construye PDF con Bioanalista Representante configurado en la sucursal', () async {
      final branchWithBioanalyst = BranchInDb(
        id: 'br-bio',
        name: 'Laboratorio Clínico Serum Matriz',
        address: 'Calle Principal 456',
        phone: 'PBX 2222-0000',
        imageUrl: null,
        bioanalyst: BranchBioanalyst(
          name: 'Lic. Joselin Lopez',
          title: 'TECNOLOGO MEDICO',
          code: 'Codigo MINSA 88027',
        ),
        createdAt: nowMs,
      );

      final template = SingleClinicalOrderTemplate(
        order: mockOrder,
        branch: branchWithBioanalyst,
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('Construye PDF con Sello Digital de Tinta configurado en el Bioanalista', () async {
      final branchWithBioanalystAndSeal = BranchInDb(
        id: 'br-seal',
        name: 'Laboratorio Clínico Serum Matriz',
        address: 'Calle Principal 456',
        phone: 'PBX 2222-0000',
        imageUrl: null,
        bioanalyst: BranchBioanalyst(
          name: 'Lic. Joselin Lopez',
          title: 'TECNOLOGO MEDICO',
          code: 'Codigo MINSA 88027',
          sealUrl: 'https://cdn.example.com/seals/sello_lic_joselin.png',
        ),
        createdAt: nowMs,
      );

      final template = SingleClinicalOrderTemplate(
        order: mockOrder,
        branch: branchWithBioanalystAndSeal,
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });

    test(
      'Construye PDF con pie de página conteniendo dirección, WhatsApp, Facebook y Email',
      () async {
        final branchWithFullContacts = BranchInDb(
          id: 'br-full',
          name: 'Laboratorio Clínico Biomedic',
          address: 'Consultorio Médico Divino Niño, de Unión FENOSA 1 C y 75 vrs al este',
          phone: '8783-4873',
          facebook: 'Laboratorio Clínico Biomedic',
          email: 'info@biomedic.com',
          imageUrl: null,
          createdAt: nowMs,
        );

        final template = SingleClinicalOrderTemplate(
          order: mockOrder,
          branch: branchWithFullContacts,
        );

        final doc = await template.buildDocument();
        final bytes = await doc.save();

        expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
        expect(bytes.isNotEmpty, isTrue);
      },
    );

    test(
      'Construye PDF con pie de página tolerante cuando los contactos son nulos o vacíos',
      () async {
        final branchEmptyContacts = BranchInDb(
          id: 'br-empty',
          name: 'Laboratorio Clínico Matriz',
          address: '',
          phone: '',
          facebook: null,
          email: null,
          imageUrl: null,
          createdAt: nowMs,
        );

        final template = SingleClinicalOrderTemplate(
          order: mockOrder,
          branch: branchEmptyContacts,
        );

        final doc = await template.buildDocument();
        final bytes = await doc.save();

        expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
        expect(bytes.isNotEmpty, isTrue);
      },
    );

    test('Construye PDF excluyendo parámetros con showInPrint false', () async {
      final orderWithHidden = OrderInDb(
        id: 'ord-hidden-test',
        patientId: 'pat-1',
        doctorId: 'doc-1',
        branchId: 'br-1',
        items: mockOrder.items,
        status: 'completed',
        totalPrice: 35000,
        paidAmount: 35000,
        createdAt: nowMs,
        patientInfo: mockOrder.patientInfo,
        doctorInfo: mockOrder.doctorInfo,
        results: [
          OrderTestResult(
            labTestId: 'lt-1',
            parameterName: 'Colesterol Total',
            medicalClassification: 'Bioquímica',
            dataType: 'numeric',
            resultValue: '185',
            showInPrint: true,
          ),
          OrderTestResult(
            labTestId: 'lt-2',
            parameterName: 'Triglicéridos',
            medicalClassification: 'Bioquímica',
            dataType: 'numeric',
            resultValue: '120',
            showInPrint: false, // Oculto
          ),
        ],
      );

      final branch = BranchInDb(
        id: 'br-1',
        name: 'Laboratorio Clínico Matriz',
        address: 'Calle 10 #20',
        phone: '1234-5678',
        createdAt: nowMs,
      );

      final template = SingleClinicalOrderTemplate(
        order: orderWithHidden,
        branch: branch,
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });

    test(
      'Usa 0 días exactos cuando el paciente tiene fecha de nacimiento, sin caer al fallback de años',
      () {
        final newborn = PatientInfo(
          name: 'Recién nacido',
          dateOfBirth: nowMs,
          gender: 'M',
        );

        final ageInDays = SingleClinicalOrderTemplate.resolveReferenceAgeInDays(
          patient: newborn,
          exactAgeInDays: 0,
        );

        expect(ageInDays, 0);
      },
    );

    test('Usa 0 días exactos cuando explicitAge es 0 aunque no haya fecha de nacimiento', () {
      final newborn = PatientInfo(
        name: 'Recién nacido sin fecha',
        dateOfBirth: 0,
        gender: 'M',
        age: 0,
      );

      final ageInDays = SingleClinicalOrderTemplate.resolveReferenceAgeInDays(
        patient: newborn,
        exactAgeInDays: 0,
      );

      expect(ageInDays, 0);
    });

    test('Devuelve null cuando no hay ningún dato de edad', () {
      final patientWithoutAge = PatientInfo(
        name: 'Paciente sin demografía',
        dateOfBirth: 0,
        gender: '',
      );

      final ageInDays = SingleClinicalOrderTemplate.resolveReferenceAgeInDays(
        patient: patientWithoutAge,
        exactAgeInDays: 0,
      );

      expect(ageInDays, isNull);
    });

    test('Ignora el alertFlag guardado cuando el resolvedor no encuentra rango', () {
      final result = OrderTestResult(
        labTestId: 'lt-glucosa',
        parameterName: 'Glucosa',
        dataType: 'numeric',
        unitOfMeasure: 'mg/dL',
        referenceValues: [
          ReferenceValue(
            patientType: 'general',
            gender: 'female',
            minAgeDays: 0,
            maxAgeDays: 36500,
            minValue: 70,
            maxValue: 100,
            useGender: true,
          ),
        ],
        resultValue: '150',
        alertFlag: 'HIGH',
      );

      final reference = ReferenceValueResolver.resolve(
        values: result.referenceValues,
        ageInDays: 30 * 365,
        gender: 'M',
      );

      expect(reference, isNull);
      expect(
        SingleClinicalOrderTemplate.resolveResultAlert(
          result: result,
          reference: reference,
        ),
        isNull,
      );
    });

    test('Recalcula H en PDF aunque el flag guardado sea NORMAL', () {
      final result = OrderTestResult(
        labTestId: 'lt-glucosa',
        parameterName: 'Glucosa',
        dataType: 'numeric',
        unitOfMeasure: 'mg/dL',
        resultValue: '150',
        alertFlag: 'NORMAL',
      );

      final reference = ReferenceValue(
        patientType: 'general',
        gender: 'both',
        minAgeDays: 0,
        maxAgeDays: 36500,
        minValue: 70,
        maxValue: 100,
      );

      expect(
        SingleClinicalOrderTemplate.resolveResultAlert(
          result: result,
          reference: reference,
        ),
        'H',
      );
    });

    test('Prioriza Sin rango sobre referenceText cuando no hay rango aplicable', () {
      final label = SingleClinicalOrderTemplate.resolveReferenceLabel(
        dataType: 'numeric',
        referenceText: 'Escala institucional: 70 - 100 mg/dL',
        unitOfMeasure: 'mg/dL',
        expectedQualitativeValue: null,
        reference: null,
      );

      expect(label, contains('Sin rango para esta edad/género'));
      expect(label, contains('Escala institucional: 70 - 100 mg/dL'));
      expect(label.indexOf('Sin rango'), lessThan(label.indexOf('Escala')));
    });

    test('Muestra Sin datos demográficos cuando no hay edad ni género', () {
      final label = SingleClinicalOrderTemplate.resolveReferenceLabel(
        dataType: 'numeric',
        referenceText: '',
        unitOfMeasure: 'mg/dL',
        expectedQualitativeValue: null,
        reference: null,
        hasDemographics: false,
      );

      expect(label, 'Sin datos demográficos');
    });

    test('Mantiene referenceText como escala cuando sí hay rango resuelto', () {
      final label = SingleClinicalOrderTemplate.resolveReferenceLabel(
        dataType: 'numeric',
        referenceText: 'Escala institucional: 70 - 100 mg/dL',
        unitOfMeasure: 'mg/dL',
        expectedQualitativeValue: null,
        reference: ReferenceValue(
          patientType: 'general',
          gender: 'both',
          minAgeDays: 0,
          maxAgeDays: 36500,
          minValue: 70,
          maxValue: 100,
        ),
      );

      expect(label, 'Escala institucional: 70 - 100 mg/dL');
    });

    test('Construye PDF con Bioanalista Auxiliar seleccionado (signer explícito)', () async {
      final titular = BioanalystInfo(
        name: 'Lic. Titular Central',
        title: 'DIRECTOR TECNICO',
        code: 'MINSA 11223',
      );

      final auxiliar = BioanalystInfo(
        name: 'Lic. Auxiliar de Turno',
        title: 'MICROBIOLOGA CLINICA',
        code: 'MINSA 99887',
      );

      final branch = BranchInDb(
        id: 'br-aux-test',
        name: 'Laboratorio Biomedic',
        address: 'Calle Real #10',
        phone: '1234-5678',
        bioanalyst: titular,
        auxBio: [
          AuxBioanalyst(
            user: UserInfo(id: 'usr-9', name: 'Lic. Auxiliar de Turno'),
            bioanalyst: auxiliar,
          ),
        ],
        createdAt: nowMs,
      );

      final template = SingleClinicalOrderTemplate(
        order: mockOrder,
        branch: branch,
        signer: auxiliar,
      );

      expect(template.signer, equals(auxiliar));
      expect(template.signer!.name, equals('Lic. Auxiliar de Turno'));

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });
  });
}
