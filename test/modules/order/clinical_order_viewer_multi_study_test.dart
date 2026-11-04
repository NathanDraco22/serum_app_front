import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/widgets/dialogs/viewers/clinical_order_viewer.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final nowMs = DateTime.now().millisecondsSinceEpoch;

  final multiOrder = OrderInDb(
    id: 'ORD-MULTI-VIEWER-01',
    patientId: 'PAT-1',
    branchId: 'branch-1',
    totalPrice: 65000,
    paidAmount: 65000,
    status: 'completed',
    createdAt: nowMs,
    patientInfo: PatientInfo(
      name: 'Paciente Multi Exámenes',
      dateOfBirth: nowMs - (30 * 365 * 86400000),
      gender: 'M',
    ),
    doctorInfo: DoctorInfo(name: 'Dr. Medico Tratante'),
    items: [
      OrderItem(labTestId: 'BHC', name: 'Biometría Hemática Completa', salePriceApplied: 30000, isPack: true),
      OrderItem(labTestId: 'EGO', name: 'Examen General de Orina', salePriceApplied: 15000, isPack: true),
      OrderItem(labTestId: 'EGH', name: 'Examen General de Heces', salePriceApplied: 15000, isPack: true),
    ],
    results: [
      // Biometría
      OrderTestResult(
        labTestId: 'HB',
        parameterName: 'Hemoglobina',
        subclassification: 'Serie Roja',
        dataType: 'numeric',
        parentExamName: 'Biometría Hemática Completa',
        resultValue: '15.2',
        unitOfMeasure: 'g/dL',
      ),
      OrderTestResult(
        labTestId: 'LEU',
        parameterName: 'Leucocitos',
        subclassification: 'Serie Blanca',
        dataType: 'numeric',
        parentExamName: 'Biometría Hemática Completa',
        resultValue: '6800',
        unitOfMeasure: 'x mm3',
      ),
      // EGO
      OrderTestResult(
        labTestId: 'COL-ORI',
        parameterName: 'Color',
        subclassification: 'Examen Físico-Químico',
        dataType: 'qualitative',
        parentExamName: 'Examen General de Orina',
        resultValue: 'Amarillo',
      ),
      OrderTestResult(
        labTestId: 'LEU-ORI',
        parameterName: 'Leucocitos (Orina)',
        subclassification: 'Sedimento Microscópico',
        dataType: 'text',
        parentExamName: 'Examen General de Orina',
        resultValue: '0 - 1 x campo',
      ),
      // EGH
      OrderTestResult(
        labTestId: 'COL-HEC',
        parameterName: 'Color (Heces)',
        subclassification: 'Examen Físico',
        dataType: 'qualitative',
        parentExamName: 'Examen General de Heces',
        resultValue: 'Café',
      ),
    ],
  );

  final branch = BranchInDb(
    id: 'br-1',
    name: 'Sede Biomedic Central',
    address: 'Avenida Médica #123',
    phone: '2222-3333',
    createdAt: nowMs,
  );

  testWidgets('ClinicalOrderViewerContent renderiza títulos de examen independientes y subseries', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClinicalOrderViewerContent(
              order: multiOrder,
              branch: branch,
              patientInfo: multiOrder.patientInfo!,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Títulos destacados de cada estudio
    expect(find.text('BIOMETRÍA HEMÁTICA COMPLETA'), findsOneWidget);
    expect(find.text('EXAMEN GENERAL DE ORINA'), findsOneWidget);
    expect(find.text('EXAMEN GENERAL DE HECES'), findsOneWidget);

    // 2. Subclasificaciones de cada estudio
    expect(find.text('SERIE ROJA'), findsOneWidget);
    expect(find.text('SERIE BLANCA'), findsOneWidget);
    expect(find.text('EXAMEN FÍSICO-QUÍMICO'), findsOneWidget);
    expect(find.text('SEDIMENTO MICROSCÓPICO'), findsOneWidget);
    expect(find.text('EXAMEN FÍSICO'), findsOneWidget);

    // 3. Parámetros
    expect(find.text('Hemoglobina'), findsOneWidget);
    expect(find.text('Leucocitos'), findsOneWidget);
    expect(find.text('Leucocitos (Orina)'), findsOneWidget);
    expect(find.text('Color (Heces)'), findsOneWidget);
  });
}
