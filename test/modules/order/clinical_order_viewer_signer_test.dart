import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/widgets/dialogs/viewers/clinical_order_viewer.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockOrder = OrderInDb(
    id: 'ORD-SIGNER-01',
    patientId: 'PAT-1',
    branchId: 'branch-1',
    totalPrice: 2000,
    paidAmount: 2000,
    status: 'completed',
    createdAt: 1700000000000,
    patientInfo: PatientInfo(
      name: 'Paciente Prueba',
      dateOfBirth: 100000000000,
      gender: 'M',
    ),
    doctorInfo: DoctorInfo(name: 'Dr. Medico'),
    items: [
      OrderItem(
        labTestId: 'lt-1',
        name: 'Glucosa',
        salePriceApplied: 2000,
        originalPrice: 2000,
      ),
    ],
    results: [
      OrderTestResult(
        labTestId: 'lt-1',
        parameterName: 'Glucosa en Ayunas',
        medicalClassification: 'Bioquímica',
        dataType: 'numeric',
        resultValue: '95',
      ),
    ],
  );

  final titularBio = BioanalystInfo(
    name: 'Lic. Titular Biomedic',
    title: 'DIRECTOR TECNICO',
    code: 'MINSA 11223',
  );

  final auxiliarBio = BioanalystInfo(
    name: 'Lic. Auxiliar Guardia',
    title: 'MICROBIOLOGA CLINICA',
    code: 'MINSA 99887',
  );

  testWidgets('ClinicalOrderViewerContent renderiza al titular por defecto', (tester) async {
    final branch = BranchInDb(
      id: 'br-1',
      name: 'Sede Biomedic',
      address: 'Central',
      phone: '123',
      bioanalyst: titularBio,
      createdAt: 1700000000000,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClinicalOrderViewerContent(
              order: mockOrder,
              branch: branch,
              patientInfo: mockOrder.patientInfo!,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lic. Titular Biomedic'), findsOneWidget);
    expect(find.text('DIRECTOR TECNICO'), findsOneWidget);
    expect(find.text('MINSA 11223'), findsOneWidget);
  });

  testWidgets('ClinicalOrderViewerContent renderiza al auxiliar cuando se pasa signer explícito', (tester) async {
    final branch = BranchInDb(
      id: 'br-1',
      name: 'Sede Biomedic',
      address: 'Central',
      phone: '123',
      bioanalyst: titularBio,
      createdAt: 1700000000000,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClinicalOrderViewerContent(
              order: mockOrder,
              branch: branch,
              patientInfo: mockOrder.patientInfo!,
              signer: auxiliarBio,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lic. Auxiliar Guardia'), findsOneWidget);
    expect(find.text('MICROBIOLOGA CLINICA'), findsOneWidget);
    expect(find.text('MINSA 99887'), findsOneWidget);
    expect(find.text('Lic. Titular Biomedic'), findsNothing);
  });

  testWidgets('Selector dinámico de firmante conmuta entre titular y auxiliar en el visor completo', (tester) async {
    final branchWithAux = BranchInDb(
      id: 'br-1',
      name: 'Sede Biomedic',
      address: 'Central',
      phone: '123',
      bioanalyst: titularBio,
      auxBio: [
        AuxBioanalyst(
          user: UserInfo(id: 'usr-aux-1', name: 'Lic. Auxiliar Guardia'),
          bioanalyst: auxiliarBio,
        ),
      ],
      createdAt: 1700000000000,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ClinicalOrderViewer(
          order: mockOrder,
          branch: branchWithAux,
          patientInfo: mockOrder.patientInfo,
          doctorInfo: mockOrder.doctorInfo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Inicialmente se muestra el botón del selector con el titular
    expect(find.text('Lic. Titular Biomedic'), findsAtLeastNWidgets(1));
    expect(find.byType(PopupMenuButton<BioanalystInfo>), findsOneWidget);

    // 2. Abrir el PopupMenuButton
    await tester.tap(find.byType(PopupMenuButton<BioanalystInfo>));
    await tester.pumpAndSettle();

    // 3. Seleccionar el auxiliar de la lista desplegable
    await tester.tap(find.textContaining('Lic. Auxiliar Guardia').last);
    await tester.pumpAndSettle();

    // 4. Ahora en la firma se muestra el auxiliar
    expect(find.text('Lic. Auxiliar Guardia'), findsAtLeastNWidgets(1));
    expect(find.text('MICROBIOLOGA CLINICA'), findsOneWidget);
    expect(find.text('MINSA 99887'), findsOneWidget);
  });
}
