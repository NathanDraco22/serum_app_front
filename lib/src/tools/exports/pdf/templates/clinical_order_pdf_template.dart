import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:serum_business/serum_business.dart';
import '../pdf_font_helper.dart';
import '../pdf_template.dart';

class SingleClinicalOrderTemplate implements PdfTemplate {
  final OrderInDb order;
  final BranchInDb branch;
  final PatientInfo? patientInfo;
  final DoctorInfo? doctorInfo;

  SingleClinicalOrderTemplate({
    required this.order,
    required this.branch,
    PatientInfo? patientInfo,
    DoctorInfo? doctorInfo,
  })  : patientInfo = patientInfo ?? order.patientInfo,
        doctorInfo = doctorInfo ?? order.doctorInfo;

  int _calculateAge(int birthDateMs) {
    if (birthDateMs <= 0) return 0;
    final birthDate = DateTime.fromMillisecondsSinceEpoch(birthDateMs);
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age >= 0 ? age : 0;
  }

  String _formatGender(String gender) {
    final g = gender.trim().toLowerCase();
    if (g == 'm' || g == 'male' || g == 'masculino') return 'Masculino';
    if (g == 'f' || g == 'female' || g == 'femenino') return 'Femenino';
    return gender;
  }

  String _determineClinicalArea() {
    final title = order.examName.toUpperCase();
    if (title.contains('HEMAT') ||
        title.contains('HEMOGLOBINA') ||
        title.contains('SANGRE') ||
        title.contains('BIOMETR')) {
      return 'HEMATOLOGIA';
    }
    if (title.contains('QUIMIC') ||
        title.contains('GLUCOSA') ||
        title.contains('PERFIL') ||
        title.contains('LIPID') ||
        title.contains('COLESTEROL')) {
      return 'QUIMICA CLINICA';
    }
    if (title.contains('ORINA') ||
        title.contains('URO') ||
        title.contains('GENERAL DE ORINA')) {
      return 'UROANALISIS';
    }
    if (title.contains('HECES') ||
        title.contains('COPRO') ||
        title.contains('PARASIT')) {
      return 'COPROLOGIA';
    }
    if (title.contains('INMUNO') ||
        title.contains('SEROLOG') ||
        title.contains('VIH') ||
        title.contains('ANTIGEN')) {
      return 'INMUNOLOGIA / SEROLOGIA';
    }
    if (title.contains('HORMON') || title.contains('TIROID')) {
      return 'HORMONAS / ENDOCRINOLOGIA';
    }

    for (final r in order.results) {
      final mc = r.medicalClassification.trim().toUpperCase();
      if (mc.contains('HEMAT')) return 'HEMATOLOGIA';
      if (mc.contains('QUIMIC')) return 'QUIMICA CLINICA';
      if (mc.contains('URO')) return 'UROANALISIS';
      if (mc.contains('COPRO')) return 'COPROLOGIA';
      if (mc.contains('INMUNO')) return 'INMUNOLOGIA';
    }

    return 'LABORATORIO CLINICO';
  }

  String _resolveReferenceText(OrderTestResult r, int patientAge, String gender) {
    if (r.dataType == 'numeric') {
      if (r.referenceValues.isNotEmpty) {
        final normalizedGender = gender.toLowerCase();
        ReferenceValue? matchedRef;
        for (final ref in r.referenceValues) {
          final refGender = ref.gender.toLowerCase();
          final matchesGender = refGender.isEmpty ||
              refGender == 'both' ||
              refGender == 'todos' ||
              (refGender.startsWith('m') && normalizedGender.startsWith('m')) ||
              (refGender.startsWith('f') && normalizedGender.startsWith('f'));

          final ageDays = patientAge * 365;
          final matchesAge = (ref.minAgeDays <= 0 || ageDays >= ref.minAgeDays) &&
              (ref.maxAgeDays <= 0 || ageDays <= ref.maxAgeDays);

          if (matchesGender && matchesAge) {
            matchedRef = ref;
            break;
          }
        }
        matchedRef ??= r.referenceValues.first;
        final unitSuffix = r.unitOfMeasure.isNotEmpty ? ' ${r.unitOfMeasure}' : '';
        return '${matchedRef.minValue} - ${matchedRef.maxValue}$unitSuffix';
      }
      return '-';
    } else if (r.dataType == 'qualitative' || r.dataType == 'boolean') {
      if (r.expectedQualitativeValue != null &&
          r.expectedQualitativeValue!.isNotEmpty) {
        return 'Esperado: ${r.expectedQualitativeValue}';
      }
      return 'Negativo';
    } else {
      if (r.expectedQualitativeValue != null &&
          r.expectedQualitativeValue!.isNotEmpty) {
        return r.expectedQualitativeValue!;
      }
      return '-';
    }
  }

  String? _resolveAlertFlag(OrderTestResult r, int patientAge, String gender) {
    if (r.alertFlag != null && r.alertFlag!.isNotEmpty) {
      final flag = r.alertFlag!.toUpperCase();
      if (flag == 'HIGH' || flag == 'ALTO' || flag == 'H') return 'H';
      if (flag == 'LOW' || flag == 'BAJO' || flag == 'L') return 'L';
      if (flag == 'ABNORMAL' || flag == 'ANORMAL') return '*';
      return flag;
    }

    if (r.dataType == 'numeric' &&
        r.resultValue != null &&
        r.referenceValues.isNotEmpty) {
      final numVal =
          double.tryParse(r.resultValue!.replaceAll(',', '.').trim());
      if (numVal != null) {
        final normalizedGender = gender.toLowerCase();
        ReferenceValue? matchedRef;
        for (final ref in r.referenceValues) {
          final refGender = ref.gender.toLowerCase();
          final matchesGender = refGender.isEmpty ||
              refGender == 'both' ||
              refGender == 'todos' ||
              (refGender.startsWith('m') && normalizedGender.startsWith('m')) ||
              (refGender.startsWith('f') && normalizedGender.startsWith('f'));

          final ageDays = patientAge * 365;
          final matchesAge = (ref.minAgeDays <= 0 || ageDays >= ref.minAgeDays) &&
              (ref.maxAgeDays <= 0 || ageDays <= ref.maxAgeDays);

          if (matchesGender && matchesAge) {
            matchedRef = ref;
            break;
          }
        }
        matchedRef ??= r.referenceValues.first;
        if (numVal > matchedRef.maxValue) {
          return 'H';
        }
        if (numVal < matchedRef.minValue) {
          return 'L';
        }
      }
    }
    return null;
  }

  @override
  Future<pw.Document> buildDocument() async {
    await PdfFontHelper.ensureInitialized();
    final doc = pw.Document();

    final orderDate = DateTime.fromMillisecondsSinceEpoch(order.createdAt);
    final formattedDate =
        '${DateTimeTool.formatddMMyy(orderDate)} ${DateTimeTool.formatHHmm(orderDate)}';

    pw.MemoryImage? logoImage;
    if (branch.imageUrl != null && branch.imageUrl!.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(branch.imageUrl!));
        if (response.statusCode == 200) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {
        // Si no se puede descargar el logo, se continúa generando el informe limpiamente
      }
    }

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 26),
      buildBackground: (pw.Context context) {
        if (logoImage == null) return pw.SizedBox();
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Center(
            child: pw.Opacity(
              opacity: 0.08,
              child: pw.Image(
                logoImage,
                width: 280,
                fit: pw.BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );

    final patient = patientInfo ??
        PatientInfo(
          name: 'Paciente #${order.patientId}',
          dateOfBirth: 0,
          gender: 'M',
        );
    final patientAge = _calculateAge(patient.dateOfBirth);
    final genderStr = _formatGender(patient.gender);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            child: _buildHeader(formattedDate, logoImage),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 10),
            padding: const pw.EdgeInsets.only(top: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Serum LIS - Sistema de Gestión de Laboratorio Clínico',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            _buildPatientAndDoctorInfo(patient, patientAge, genderStr),
            pw.SizedBox(height: 14),
            _buildClinicalResultsSection(patientAge, patient.gender),
            pw.SizedBox(height: 20),
            _buildSignatureAndNotes(),
          ];
        },
      ),
    );

    return doc;
  }

  pw.Widget _buildHeader(String formattedDate, pw.MemoryImage? logoImage) {
    final shortId = order.id.length > 8
        ? order.id.substring(order.id.length - 8).toUpperCase()
        : order.id.toUpperCase();

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 6,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null) ...[
                pw.Container(
                  width: 48,
                  height: 48,
                  margin: const pw.EdgeInsets.only(right: 10),
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      branch.name.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    if (branch.address.isNotEmpty)
                      pw.Text(
                        branch.address,
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                    if (branch.phone.isNotEmpty)
                      pw.Text(
                        'Teléfono: ${branch.phone}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'INFORME DE RESULTADOS',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Folio: #$shortId',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Fecha: $formattedDate',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPatientAndDoctorInfo(
    PatientInfo patient,
    int patientAge,
    String genderStr,
  ) {
    final doctor = doctorInfo;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Datos del Paciente
          pw.Expanded(
            flex: 5,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildCompactInfoLine('Paciente:', patient.name, isBold: true),
                _buildCompactInfoLine(
                  'Edad / Sexo:',
                  '${patientAge > 0 ? '$patientAge años' : 'N/D'} | $genderStr',
                ),
                if (patient.cardId != null && patient.cardId!.isNotEmpty)
                  _buildCompactInfoLine('Identificación:', patient.cardId!),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          // Datos del Médico Referente
          pw.Expanded(
            flex: 5,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildCompactInfoLine(
                  'Médico:',
                  doctor?.name ?? 'Particular / Sin médico asignado',
                  isBold: true,
                ),
                if (doctor != null && doctor.specialty.isNotEmpty)
                  _buildCompactInfoLine('Especialidad:', doctor.specialty),
                if (doctor != null &&
                    doctor.cardId != null &&
                    doctor.cardId!.isNotEmpty)
                  _buildCompactInfoLine('Colegiatura:', doctor.cardId!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactInfoLine(String label, String value,
      {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 70,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildClinicalResultsSection(int patientAge, String gender) {
    final clinicalArea = _determineClinicalArea();
    final examTitle = order.examName.isNotEmpty
        ? order.examName.toUpperCase()
        : 'ESTUDIO CLÍNICO';

    // Agrupar resultados por clasificación médica (subseries como SERIE ROJA, SERIE BLANCA, etc.)
    final Map<String, List<OrderTestResult>> groups = {};
    for (final r in order.results) {
      final classification = r.medicalClassification.trim();
      final groupKey = classification.isNotEmpty ? classification.toUpperCase() : '';
      groups.putIfAbsent(groupKey, () => []).add(r);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // 1. Barra de acento teal superior
        pw.Container(
          height: 2.2,
          color: PdfColor.fromHex('#26A69A'),
        ),
        pw.SizedBox(height: 5),

        // 2. Encabezado de área (ej. HEMATOLOGIA)
        pw.Text(
          clinicalArea,
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 3),

        // 3. Línea negra superior de la tabla
        pw.Container(
          height: 1.0,
          color: PdfColors.black,
        ),
        pw.SizedBox(height: 3),

        // 4. Encabezados de la tabla: Nombre del Test | Resultado | Valores de Referencia
        pw.Row(
          children: [
            pw.Expanded(
              flex: 42,
              child: pw.Text(
                'Nombre del Test',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ),
            pw.Expanded(
              flex: 31,
              child: pw.Text(
                'Resultado',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ),
            pw.Expanded(
              flex: 27,
              child: pw.Text(
                'Valores de Referencia',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 3),

        // 5. Línea negra inferior del encabezado
        pw.Container(
          height: 1.0,
          color: PdfColors.black,
        ),
        pw.SizedBox(height: 7),

        // 6. Nombre del Estudio (ej. BIOMETRÍA HEMÁTICA COMPLETA)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Text(
            examTitle,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ),

        // 7. Resultados clasificados por subseries o desplegados
        ...groups.entries.map((entry) {
          final groupTitle = entry.key;
          final items = entry.value;
          final bool hasGroupHeader = groupTitle.isNotEmpty && groupTitle != clinicalArea;

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (hasGroupHeader) ...[
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 4),
                  margin: const pw.EdgeInsets.only(top: 4, bottom: 2),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F4F6F6'),
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                  child: pw.Text(
                    groupTitle,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                ),
              ],
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(4.2), // Parámetro
                  1: const pw.FlexColumnWidth(1.8), // Resultado (+ Flag H/L)
                  2: const pw.FlexColumnWidth(1.3), // Unidad
                  3: const pw.FlexColumnWidth(2.7), // Valores de Referencia
                },
                children: items.map((r) {
                  final alertFlag = _resolveAlertFlag(r, patientAge, gender);
                  final hasAlert = alertFlag != null && alertFlag.isNotEmpty;
                  final refText = _resolveReferenceText(r, patientAge, gender);
                  final isTotalRow = r.parameterName.trim().toUpperCase() == 'TOTAL';

                  return pw.TableRow(
                    decoration: isTotalRow
                        ? const pw.BoxDecoration(
                            border: pw.Border(
                              top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                            ),
                          )
                        : null,
                    children: [
                      // Nombre del parámetro con indentación
                      pw.Padding(
                        padding: pw.EdgeInsets.only(
                          left: hasGroupHeader ? 10 : 2,
                          top: 2.5,
                          bottom: 2.5,
                          right: 4,
                        ),
                        child: pw.Text(
                          r.parameterName,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: isTotalRow ? pw.FontWeight.bold : pw.FontWeight.normal,
                            color: PdfColors.black,
                          ),
                        ),
                      ),

                      // Resultado con letra H / L en rojo
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 2),
                        child: pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(
                              r.resultValue ?? '-',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: hasAlert || isTotalRow
                                    ? pw.FontWeight.bold
                                    : pw.FontWeight.normal,
                                color: PdfColors.black,
                              ),
                            ),
                            if (hasAlert) ...[
                              pw.SizedBox(width: 6),
                              pw.Text(
                                alertFlag,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromHex('#D32F2F'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Unidad de medida
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 2),
                        child: pw.Text(
                          r.unitOfMeasure.isNotEmpty ? r.unitOfMeasure : '',
                          style: const pw.TextStyle(
                            fontSize: 7.5,
                            color: PdfColors.grey800,
                          ),
                        ),
                      ),

                      // Valores de referencia (alineados a la derecha)
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 2),
                        child: pw.Text(
                          refText,
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(
                            fontSize: 7.5,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              pw.SizedBox(height: 3),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildSignatureAndNotes() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Text(
            'Nota: Los resultados aquí expresados corresponden única y exclusivamente a la muestra recibida y procesada en nuestras instalaciones. Todo resultado debe ser correlacionado clínicamente por el médico tratante.',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
            textAlign: pw.TextAlign.justify,
          ),
        ),
        pw.SizedBox(height: 36),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Container(
                width: 190,
                height: 0.5,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Responsable de Laboratorio',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Firma y Sello de Validación',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
