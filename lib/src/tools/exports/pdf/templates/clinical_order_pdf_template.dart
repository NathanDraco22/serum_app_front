import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:serum_business/serum_business.dart';
import '../../../../tools/cache/app_image_cache.dart';
import '../../../formatters/thousands_separator_input_formatter.dart';
import '../pdf_font_helper.dart';
import '../pdf_template.dart';
import 'clinical_order_study_group.dart';

class SingleClinicalOrderTemplate implements PdfTemplate {
  final OrderInDb order;
  final BranchInDb branch;
  final PatientInfo? patientInfo;
  final DoctorInfo? doctorInfo;
  final BioanalystInfo? signer;

  SingleClinicalOrderTemplate({
    required this.order,
    required this.branch,
    PatientInfo? patientInfo,
    DoctorInfo? doctorInfo,
    BioanalystInfo? signer,
  })  : patientInfo = patientInfo ?? order.patientInfo,
        doctorInfo = doctorInfo ?? order.doctorInfo,
        signer = signer ?? branch.bioanalyst;

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

  String _resolveReferenceText(OrderTestResult r, int patientAge, String gender) {
    if (r.referenceText.trim().isNotEmpty) {
      return r.referenceText.trim();
    }
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
      final numVal = ThousandsSeparatorInputFormatter.tryParseDouble(r.resultValue);
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

    pw.MemoryImage? headerImage;
    pw.MemoryImage? watermarkImage;
    pw.MemoryImage? sealImage;

    final isIsoLogo = branch.isoLogoUrl != null && branch.isoLogoUrl!.isNotEmpty;
    final headerImageUrl = branch.effectiveIsoLogo;
    final watermarkImageUrl = branch.effectiveLogo ?? branch.effectiveIsoLogo;
    final effectiveSigner = signer ?? branch.bioanalyst;
    final sealImageUrl = effectiveSigner?.sealUrl;

    if (headerImageUrl != null && headerImageUrl.isNotEmpty) {
      final bytes = await AppImageCache.getImageBytes(headerImageUrl);
      if (bytes != null) {
        headerImage = pw.MemoryImage(bytes);
      }
    }

    if (watermarkImageUrl != null && watermarkImageUrl.isNotEmpty) {
      if (watermarkImageUrl == headerImageUrl && headerImage != null) {
        watermarkImage = headerImage;
      } else {
        final bytes = await AppImageCache.getImageBytes(watermarkImageUrl);
        if (bytes != null) {
          watermarkImage = pw.MemoryImage(bytes);
        }
      }
    }

    if (sealImageUrl != null && sealImageUrl.isNotEmpty) {
      final bytes = await AppImageCache.getImageBytes(sealImageUrl);
      if (bytes != null) {
        sealImage = pw.MemoryImage(bytes);
      }
    }

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 26),
      buildBackground: (pw.Context context) {
        final bgImage = watermarkImage ?? headerImage;
        if (bgImage == null) return pw.SizedBox();
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Center(
            child: pw.Opacity(
              opacity: 0.08,
              child: pw.Image(
                bgImage,
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
    final patientAge =
        patient.age > 0 ? patient.age : _calculateAge(patient.dateOfBirth);
    final genderStr = _formatGender(patient.gender);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            child: _buildHeader(formattedDate, headerImage, isIsoLogo),
          );
        },
        footer: (pw.Context context) {
          return _buildFooter(context);
        },
        build: (pw.Context context) {
          return [
            _buildPatientAndDoctorInfo(patient, patientAge, genderStr),
            pw.SizedBox(height: 14),
            _buildClinicalResultsSection(patientAge, patient.gender),
            pw.SizedBox(height: 20),
            _buildSignatureAndNotes(sealImage),
          ];
        },
      ),
    );

    return doc;
  }

  pw.Widget _buildHeader(
      String formattedDate, pw.MemoryImage? headerImage, bool isIsoLogo) {
    final shortId = order.id.length > 8
        ? order.id.substring(order.id.length - 8).toUpperCase()
        : order.id.toUpperCase();

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 6,
          child: isIsoLogo && headerImage != null
              ? pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      height: 48,
                      margin: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Image(headerImage, fit: pw.BoxFit.contain),
                    ),
                    if (branch.address.isNotEmpty)
                      pw.Text(
                        branch.address,
                        style: const pw.TextStyle(
                            fontSize: 8.5, color: PdfColors.grey700),
                      ),
                    pw.Row(
                      children: [
                        if (branch.phone.isNotEmpty)
                          pw.Text(
                            'Tel: ${branch.phone}',
                            style: const pw.TextStyle(
                                fontSize: 8.5, color: PdfColors.grey700),
                          ),
                        if (branch.phone.isNotEmpty &&
                            branch.email != null &&
                            branch.email!.isNotEmpty)
                          pw.Text(
                            ' | ',
                            style: const pw.TextStyle(
                                fontSize: 8.5, color: PdfColors.grey500),
                          ),
                        if (branch.email != null && branch.email!.isNotEmpty)
                          pw.Text(
                            branch.email!,
                            style: const pw.TextStyle(
                                fontSize: 8.5, color: PdfColors.grey700),
                          ),
                      ],
                    ),
                  ],
                )
              : pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (headerImage != null) ...[
                      pw.Container(
                        width: 48,
                        height: 48,
                        margin: const pw.EdgeInsets.only(right: 12),
                        child: pw.Image(headerImage, fit: pw.BoxFit.contain),
                      ),
                    ],
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            branch.name.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blueGrey900,
                            ),
                          ),
                          if (branch.address.isNotEmpty)
                            pw.Text(
                              branch.address,
                              style: const pw.TextStyle(
                                  fontSize: 8.5, color: PdfColors.grey700),
                            ),
                          if (branch.phone.isNotEmpty)
                            pw.Text(
                              'Teléfono: ${branch.phone}',
                              style: const pw.TextStyle(
                                  fontSize: 8.5, color: PdfColors.grey700),
                            ),
                          if (branch.email != null && branch.email!.isNotEmpty)
                            pw.Text(
                              'Email: ${branch.email!}',
                              style: const pw.TextStyle(
                                  fontSize: 8.5, color: PdfColors.grey700),
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
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Folio: #$shortId',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Fecha: $formattedDate',
                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
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
                if (order.patientId.isNotEmpty)
                  _buildCompactInfoLine('Código Paciente:', '#${order.patientId}'),
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
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 76,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildClinicalResultsSection(int patientAge, String gender) {
    final studyGroups = ClinicalOrderGrouper.groupResultsByStudy(order);
    final overallArea =
        ClinicalOrderGrouper.determineOverallClinicalArea(studyGroups);

    pw.TableRow buildPdfTableRow(OrderTestResult r, bool hasGroupHeader) {
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
              top: 3.0,
              bottom: 3.0,
              right: 4,
            ),
            child: pw.Text(
              r.parameterName,
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: isTotalRow ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: PdfColors.black,
              ),
            ),
          ),

          // Resultado con letra H / L en rojo
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3.0, horizontal: 2),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(
                    r.dataType == 'numeric' && r.resultValue != null
                        ? ThousandsSeparatorInputFormatter.formatText(r.resultValue!)
                        : (r.resultValue ?? '-'),
                    style: pw.TextStyle(
                      fontSize: 10,
                      lineSpacing: 1.15,
                      fontWeight: hasAlert || isTotalRow
                          ? pw.FontWeight.bold
                          : pw.FontWeight.normal,
                      color: PdfColors.black,
                    ),
                  ),
                ),
                if (hasAlert) ...[
                  pw.SizedBox(width: 4),
                  pw.Text(
                    alertFlag,
                    style: pw.TextStyle(
                      fontSize: 10,
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
            padding: const pw.EdgeInsets.symmetric(vertical: 3.0, horizontal: 2),
            child: pw.Text(
              r.unitOfMeasure.isNotEmpty ? r.unitOfMeasure : '',
              style: const pw.TextStyle(
                fontSize: 8.5,
                color: PdfColors.grey800,
              ),
            ),
          ),

          // Valores de referencia (alineados a la derecha)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3.0, horizontal: 2),
            child: pw.Text(
              refText,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: refText.contains('\n') ? 8.5 : 9.0,
                lineSpacing: refText.contains('\n') ? 1.2 : 1.0,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ],
      );
    }

    pw.Widget buildPdfTextResultBlock(OrderTestResult r, bool hasGroupHeader) {
      final hasContent =
          r.resultValue != null && r.resultValue!.trim().isNotEmpty;
      final displayValue = hasContent ? r.resultValue!.trim() : '-';
      final refText = _resolveReferenceText(r, patientAge, gender);

      return pw.Padding(
        padding: pw.EdgeInsets.only(
          left: hasGroupHeader ? 10 : 2,
          top: 4.0,
          bottom: 5.0,
          right: 2,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              r.parameterName,
              style: const pw.TextStyle(
                fontSize: 9.5,
                color: PdfColors.black,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Container(
              width: double.infinity,
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F9FAFB'),
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(2)),
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              ),
              child: pw.Text(
                displayValue,
                style: const pw.TextStyle(
                  fontSize: 9.0,
                  lineSpacing: 1.25,
                  color: PdfColors.black,
                ),
              ),
            ),
            if (refText.isNotEmpty && refText != '—' && refText != '-') ...[
              pw.SizedBox(height: 2),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                child: pw.Text(
                  'Criterio / Valor de Referencia: $refText',
                  style: pw.TextStyle(
                    fontSize: 8.0,
                    fontStyle: pw.FontStyle.italic,
                    lineSpacing: 1.15,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    List<pw.Widget> buildStudySectionWidgets(
      ClinicalStudyGroup study,
      bool isFirst,
      bool isLast,
    ) {
      final List<pw.Widget> studyWidgets = [];

      // 1. Separador visual entre estudios
      if (!isFirst) {
        studyWidgets.add(pw.SizedBox(height: 12));
        studyWidgets.add(
          pw.Container(
            height: 0.8,
            color: PdfColor.fromHex('#B0BEC5'),
          ),
        );
        studyWidgets.add(pw.SizedBox(height: 10));
      }

      // 2. Nombre del Estudio (ej. BIOMETRÍA HEMÁTICA COMPLETA, EXAMEN GENERAL DE ORINA)
      studyWidgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Expanded(
                child: pw.Text(
                  study.studyTitle,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
              if (studyGroups.length > 1 && study.clinicalArea != overallArea)
                pw.Text(
                  study.clinicalArea,
                  style: const pw.TextStyle(
                    fontSize: 8.5,
                    color: PdfColors.grey700,
                  ),
                ),
            ],
          ),
        ),
      );

      // 3. Encabezados de tabla si contiene pruebas tabulares
      if (study.hasTabularTests) {
        studyWidgets.add(
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.black, width: 0.8),
                bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 42,
                  child: pw.Text(
                    'Nombre del Test',
                    style: pw.TextStyle(
                      fontSize: 9.5,
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
                      fontSize: 9.5,
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
                      fontSize: 9.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        studyWidgets.add(pw.SizedBox(height: 5));
      }

      // 4. Subclasificaciones clínicas y resultados
      for (final entry in study.subclassificationGroups.entries) {
        final groupTitle = entry.key;
        final items = entry.value;
        final bool hasGroupHeader = groupTitle.isNotEmpty &&
            groupTitle != study.studyTitle &&
            groupTitle != overallArea;

        final List<pw.Widget> groupWidgets = [];
        List<OrderTestResult> currentTabularChunk = [];

        void flushTabularChunk() {
          if (currentTabularChunk.isEmpty) return;
          final chunk = List<OrderTestResult>.from(currentTabularChunk);
          currentTabularChunk.clear();
          groupWidgets.add(
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(4.2),
                1: const pw.FlexColumnWidth(1.8),
                2: const pw.FlexColumnWidth(1.3),
                3: const pw.FlexColumnWidth(2.7),
              },
              children: chunk
                  .map((r) => buildPdfTableRow(r, hasGroupHeader))
                  .toList(),
            ),
          );
        }

        for (final r in items) {
          if (r.dataType == 'text') {
            flushTabularChunk();
            groupWidgets.add(buildPdfTextResultBlock(r, hasGroupHeader));
          } else {
            currentTabularChunk.add(r);
          }
        }
        flushTabularChunk();

        studyWidgets.add(
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (hasGroupHeader) ...[
                pw.Container(
                  width: double.infinity,
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 5),
                  margin: const pw.EdgeInsets.only(top: 4, bottom: 2),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F4F6F6'),
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                  child: pw.Text(
                    groupTitle,
                    style: pw.TextStyle(
                      fontSize: 9.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                ),
              ],
              ...groupWidgets,
              pw.SizedBox(height: 2),
            ],
          ),
        );
      }

      return studyWidgets;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // 1. Encabezado de área clínica general
        pw.Text(
          overallArea,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Container(
          height: 1.2,
          color: PdfColors.black,
        ),
        pw.SizedBox(height: 8),

        // 2. Renderizar cada estudio clínico con sus clasificaciones y separadores
        for (int i = 0; i < studyGroups.length; i++) ...[
          ...buildStudySectionWidgets(
            studyGroups[i],
            i == 0,
            i == studyGroups.length - 1,
          ),
        ],
      ],
    );
  }

  pw.Widget _buildSignatureAndNotes(pw.MemoryImage? sealImage) {
    final effectiveSigner = signer ?? branch.bioanalyst;
    final hasClinicalNotes = order.notes != null && order.notes!.trim().isNotEmpty;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (hasClinicalNotes) ...[
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            margin: const pw.EdgeInsets.only(bottom: 8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F8F9FA'),
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'OBSERVACIONES / NOTAS CLÍNICAS:',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  order.notes!.trim(),
                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
                ),
              ],
            ),
          ),
        ],
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Column(
            children: [
              if (sealImage != null) ...[
                pw.Transform.rotateBox(
                  angle: -0.087, // ~ -5 grados de inclinación de tinta
                  child: pw.Image(
                    sealImage,
                    width: 100,
                    height: 75,
                    fit: pw.BoxFit.contain,
                  ),
                ),
                pw.SizedBox(height: 4),
              ] else ...[
                pw.SizedBox(height: 38), // Espacio para firma manuscrita y sello manual
              ],
              pw.Container(
                width: 190,
                height: 0.5,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 4),
              if (effectiveSigner != null &&
                  effectiveSigner.name.trim().isNotEmpty) ...[
                pw.Text(
                  effectiveSigner.name.trim(),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (effectiveSigner.title.trim().isNotEmpty)
                  pw.Text(
                    effectiveSigner.title.trim(),
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                if (effectiveSigner.code.trim().isNotEmpty)
                  pw.Text(
                    effectiveSigner.code.trim(),
                    style: const pw.TextStyle(
                      fontSize: 7.5,
                      color: PdfColors.grey700,
                    ),
                  ),
              ] else ...[
                pw.Text(
                  'Responsable de Laboratorio',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Firma y Sello de Validación',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.6),
        ),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // 1. Dirección física de la sucursal
          if (branch.address.trim().isNotEmpty) ...[
            pw.Text(
              branch.address.trim(),
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.black,
              ),
              maxLines: 1,
            ),
            pw.SizedBox(height: 3),
          ],

          // 2. Canales de contacto con iconos circulares (Facebook, WhatsApp, Email)
          _buildFooterContactItems(),

          pw.SizedBox(height: 3),

          // 3. Paginación alineada a la derecha
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooterContactItems() {
    final contactItems = <pw.Widget>[];

    // Facebook
    if (branch.facebook != null && branch.facebook!.trim().isNotEmpty) {
      contactItems.add(
        _buildContactItem(
          label: 'f',
          text: branch.facebook!.trim(),
          iconColor: PdfColors.blue700,
        ),
      );
    }

    // Teléfono / WhatsApp
    if (branch.phone.trim().isNotEmpty) {
      if (contactItems.isNotEmpty) contactItems.add(pw.SizedBox(width: 14));
      contactItems.add(
        _buildContactItem(
          label: 'W',
          text: branch.phone.trim(),
          iconColor: PdfColors.teal,
        ),
      );
    }

    // Correo electrónico
    if (branch.email != null && branch.email!.trim().isNotEmpty) {
      if (contactItems.isNotEmpty) contactItems.add(pw.SizedBox(width: 14));
      contactItems.add(
        _buildContactItem(
          label: '@',
          text: branch.email!.trim(),
          iconColor: PdfColors.blue500,
        ),
      );
    }

    if (contactItems.isEmpty) return pw.SizedBox();

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: contactItems,
    );
  }

  pw.Widget _buildContactItem({
    required String label,
    required String text,
    required PdfColor iconColor,
  }) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 12,
          height: 12,
          decoration: pw.BoxDecoration(
            color: iconColor,
            shape: pw.BoxShape.circle,
          ),
          alignment: pw.Alignment.center,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 6.8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          text,
          style: const pw.TextStyle(
            fontSize: 7.8,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }
}
