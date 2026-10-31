import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:serum_business/serum_business.dart';

import '../../../../tools/cache/app_image_cache.dart';
import '../../../calculators/clinical_formulas_registry.dart';
import '../../../formatters/thousands_separator_input_formatter.dart';
import '../pdf_font_helper.dart';
import '../pdf_template.dart';

/// Representa una fila calculada de comparación entre dos resultados del mismo análisis.
class ClinicalComparisonPdfRow {
  final String key;
  final String parameterName;
  final String medicalClassification;
  final String unitOfMeasure;
  final String dataType;
  final OrderTestResult? baseResult;
  final OrderTestResult? comparisonResult;
  final List<ReferenceValue> referenceValues;
  final String? expectedQualitativeValue;

  ClinicalComparisonPdfRow({
    required this.key,
    required this.parameterName,
    this.medicalClassification = '',
    this.unitOfMeasure = '',
    this.dataType = 'numeric',
    this.baseResult,
    this.comparisonResult,
    this.referenceValues = const [],
    this.expectedQualitativeValue,
  });

  double? get baseNumeric =>
      baseResult?.resultValue != null
          ? ThousandsSeparatorInputFormatter.tryParseDouble(baseResult!.resultValue!)
          : null;

  double? get comparisonNumeric =>
      comparisonResult?.resultValue != null
          ? ThousandsSeparatorInputFormatter.tryParseDouble(comparisonResult!.resultValue!)
          : null;

  double? get deltaAbsolute {
    if (baseNumeric == null || comparisonNumeric == null) return null;
    return comparisonNumeric! - baseNumeric!;
  }

  double? get deltaPercentage {
    if (baseNumeric == null || comparisonNumeric == null || baseNumeric == 0) return null;
    return ((comparisonNumeric! - baseNumeric!) / baseNumeric!) * 100.0;
  }
}

/// Plantilla oficial de informe impreso PDF para análisis evolutivo y comparativo
/// de dos órdenes de laboratorio clínico (ej. dos Biometrías Hemáticas).
class ClinicalComparisonPdfTemplate implements PdfTemplate {
  final OrderInDb baseOrder;
  final OrderInDb comparisonOrder;
  final BranchInDb branch;
  final PatientInfo patientInfo;
  final DoctorInfo? doctorInfo;
  final List<ClinicalComparisonPdfRow> comparisonRows;

  ClinicalComparisonPdfTemplate({
    required OrderInDb order1,
    required OrderInDb order2,
    required this.branch,
    PatientInfo? patientInfo,
    DoctorInfo? doctorInfo,
    List<ClinicalComparisonPdfRow>? rows,
  })  : baseOrder = order1.createdAt <= order2.createdAt ? order1 : order2,
        comparisonOrder = order1.createdAt <= order2.createdAt ? order2 : order1,
        patientInfo = patientInfo ??
            order2.patientInfo ??
            order1.patientInfo ??
            PatientInfo(name: 'Paciente sin registrar'),
        doctorInfo = doctorInfo ?? order2.doctorInfo ?? order1.doctorInfo,
        comparisonRows = rows ?? buildComparisonRows(
          order1.createdAt <= order2.createdAt ? order1 : order2,
          order1.createdAt <= order2.createdAt ? order2 : order1,
        );

  /// Construye y empareja las filas de resultados entre la orden base y la evolutiva.
  static List<ClinicalComparisonPdfRow> buildComparisonRows(
    OrderInDb base,
    OrderInDb comparison,
  ) {
    final Map<String, ClinicalComparisonPdfRow> map = {};

    String resolveKey(OrderTestResult r) {
      final canonical = ClinicalFormulasRegistry.resolveCanonicalKey(r.parameterName);
      if (canonical != null) return canonical;
      if (r.labTestId.isNotEmpty) return r.labTestId.toLowerCase();
      return r.parameterName.trim().toLowerCase();
    }

    // 1. Ingresar resultados base
    for (final r in base.results) {
      final key = resolveKey(r);
      map[key] = ClinicalComparisonPdfRow(
        key: key,
        parameterName: r.parameterName,
        medicalClassification: r.medicalClassification,
        unitOfMeasure: r.unitOfMeasure,
        dataType: r.dataType,
        baseResult: r,
        referenceValues: r.referenceValues,
        expectedQualitativeValue: r.expectedQualitativeValue,
      );
    }

    // 2. Emparejar con resultados de la orden comparativa
    for (final r in comparison.results) {
      final key = resolveKey(r);
      if (map.containsKey(key)) {
        final existing = map[key]!;
        map[key] = ClinicalComparisonPdfRow(
          key: key,
          parameterName: existing.parameterName.isNotEmpty ? existing.parameterName : r.parameterName,
          medicalClassification: existing.medicalClassification.isNotEmpty
              ? existing.medicalClassification
              : r.medicalClassification,
          unitOfMeasure: existing.unitOfMeasure.isNotEmpty ? existing.unitOfMeasure : r.unitOfMeasure,
          dataType: existing.dataType,
          baseResult: existing.baseResult,
          comparisonResult: r,
          referenceValues: existing.referenceValues.isNotEmpty ? existing.referenceValues : r.referenceValues,
          expectedQualitativeValue: existing.expectedQualitativeValue ?? r.expectedQualitativeValue,
        );
      } else {
        map[key] = ClinicalComparisonPdfRow(
          key: key,
          parameterName: r.parameterName,
          medicalClassification: r.medicalClassification,
          unitOfMeasure: r.unitOfMeasure,
          dataType: r.dataType,
          comparisonResult: r,
          referenceValues: r.referenceValues,
          expectedQualitativeValue: r.expectedQualitativeValue,
        );
      }
    }

    return map.values.toList();
  }

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

  String _resolveReferenceText(ClinicalComparisonPdfRow row, int patientAge, String gender) {
    if (row.dataType == 'numeric') {
      if (row.referenceValues.isNotEmpty) {
        final normalizedGender = gender.toLowerCase();
        ReferenceValue? matchedRef;
        for (final ref in row.referenceValues) {
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
        matchedRef ??= row.referenceValues.first;
        final unitSuffix = row.unitOfMeasure.isNotEmpty ? ' ${row.unitOfMeasure}' : '';
        return '${matchedRef.minValue} - ${matchedRef.maxValue}$unitSuffix';
      }
      return '-';
    } else if (row.expectedQualitativeValue != null &&
        row.expectedQualitativeValue!.isNotEmpty) {
      return 'Esperado: ${row.expectedQualitativeValue}';
    }
    return '-';
  }

  String? _resolveAlertFlag(OrderTestResult? r, List<ReferenceValue> referenceValues) {
    if (r == null) return null;
    if (r.alertFlag != null && r.alertFlag!.isNotEmpty) {
      final flag = r.alertFlag!.toUpperCase();
      if (flag == 'HIGH' || flag == 'ALTO' || flag == 'H') return 'H';
      if (flag == 'LOW' || flag == 'BAJO' || flag == 'L') return 'L';
      if (flag == 'ABNORMAL' || flag == 'ANORMAL') return '*';
      return flag;
    }

    if (r.dataType == 'numeric' && r.resultValue != null && referenceValues.isNotEmpty) {
      final numVal = ThousandsSeparatorInputFormatter.tryParseDouble(r.resultValue);
      if (numVal != null) {
        final ref = referenceValues.first;
        if (numVal > ref.maxValue) return 'H';
        if (numVal < ref.minValue) return 'L';
      }
    }
    return null;
  }

  String _groupForParam(ClinicalComparisonPdfRow row) {
    final key = row.key.toUpperCase();
    if (['ERI', 'HB', 'HTC', 'VCM', 'HCM', 'CHCM'].contains(key)) {
      return 'SERIE ROJA / ÍNDICES ERITROCITARIOS';
    }
    if (['LEU', 'SEG', 'LINF', 'EOS', 'MON', 'BAN', 'BAS', 'LINF-ATIP'].contains(key)) {
      return 'SERIE BLANCA / FÓRMULA LEUCOCITARIA';
    }
    if (['PLAQ'].contains(key)) {
      return 'SERIE PLAQUETARIA';
    }
    final mc = row.medicalClassification.trim().toUpperCase();
    if (mc.contains('ROJA') || mc.contains('ERITRO')) {
      return 'SERIE ROJA / ÍNDICES ERITROCITARIOS';
    }
    if (mc.contains('BLANCA') || mc.contains('LEUCO')) {
      return 'SERIE BLANCA / FÓRMULA LEUCOCITARIA';
    }
    if (mc.contains('PLAQ')) {
      return 'SERIE PLAQUETARIA';
    }
    if (mc.isNotEmpty) return mc;
    return 'PARÁMETROS GENERALES';
  }

  @override
  Future<pw.Document> buildDocument() async {
    await PdfFontHelper.ensureInitialized();
    final doc = pw.Document();

    final baseDate = DateTime.fromMillisecondsSinceEpoch(baseOrder.createdAt);
    final compDate = DateTime.fromMillisecondsSinceEpoch(comparisonOrder.createdAt);
    final daysElapsed = compDate.difference(baseDate).inDays;

    final formattedBaseDate =
        '${DateTimeTool.formatddMMyy(baseDate)} ${DateTimeTool.formatHHmm(baseDate)}';
    final formattedCompDate =
        '${DateTimeTool.formatddMMyy(compDate)} ${DateTimeTool.formatHHmm(compDate)}';

    final shortBaseId = baseOrder.id.length > 8
        ? baseOrder.id.substring(baseOrder.id.length - 8).toUpperCase()
        : baseOrder.id.toUpperCase();
    final shortCompId = comparisonOrder.id.length > 8
        ? comparisonOrder.id.substring(comparisonOrder.id.length - 8).toUpperCase()
        : comparisonOrder.id.toUpperCase();

    pw.MemoryImage? headerImage;
    pw.MemoryImage? watermarkImage;

    final headerImageUrl = branch.effectiveIsoLogo;
    final watermarkImageUrl = branch.effectiveLogo ?? branch.effectiveIsoLogo;

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

    final patientAge =
        patientInfo.age > 0 ? patientInfo.age : _calculateAge(patientInfo.dateOfBirth);
    final genderStr = _formatGender(patientInfo.gender);

    // Agrupar filas
    final Map<String, List<ClinicalComparisonPdfRow>> groups = {};
    for (final row in comparisonRows) {
      final groupName = _groupForParam(row);
      groups.putIfAbsent(groupName, () => []).add(row);
    }

    final cardIdSuffix = patientInfo.cardId != null && patientInfo.cardId!.isNotEmpty
        ? '  •  Cédula: ${patientInfo.cardId}'
        : '';

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
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

    doc.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Membrete
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 6,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (headerImage != null)
                          pw.Image(headerImage, height: 42, fit: pw.BoxFit.contain)
                        else
                          pw.Text(
                            branch.name.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                        pw.SizedBox(height: 4),
                        if (branch.address.isNotEmpty)
                          pw.Text(
                            'Dirección: ${branch.address}',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                          ),
                        if (branch.phone.isNotEmpty)
                          pw.Text(
                            'Teléfono: ${branch.phone}',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                          ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.teal50,
                            borderRadius: pw.BorderRadius.circular(4),
                            border: pw.Border.all(color: PdfColors.teal700, width: 0.8),
                          ),
                          child: pw.Text(
                            'INFORME COMPARATIVO EVOLUTIVO',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal900,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Base: #$shortBaseId ($formattedBaseDate)',
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                        ),
                        pw.Text(
                          'Evolutiva: #$shortCompId ($formattedCompDate)',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        if (daysElapsed >= 0)
                          pw.Text(
                            'Intervalo: $daysElapsed días entre tomas',
                            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey500, thickness: 0.8),
              pw.SizedBox(height: 6),

              // Datos del paciente
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: 'Paciente: ',
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
                                ),
                                pw.TextSpan(
                                  text: patientInfo.name,
                                  style: const pw.TextStyle(fontSize: 9.5),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Edad / Sexo: ${patientAge > 0 ? '$patientAge años' : 'N/D'} | $genderStr$cardIdSuffix',
                            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                          ),
                        ],
                      ),
                    ),
                    if (doctorInfo != null)
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'Médico: ${doctorInfo!.name}',
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              'Especialidad: ${doctorInfo!.specialty}',
                              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey400, thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Página ${context.pageNumber} de ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Laboratorio Clínico Serum — Informe Generado Automáticamente',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
        build: (context) {
          return [
            // Cabecera de la tabla
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              decoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey800,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 32,
                    child: pw.Text(
                      'Parámetro / Análisis',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 12,
                    child: pw.Text(
                      'Unidad',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 16,
                    child: pw.Text(
                      'Base ($shortBaseId)',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 16,
                    child: pw.Text(
                      'Evolutiva ($shortCompId)',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 14,
                    child: pw.Text(
                      'Var. (Delta)',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 20,
                    child: pw.Text(
                      'Valores Referencia',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            ...groups.entries.map((entry) {
              final groupTitle = entry.key;
              final rows = entry.value;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    margin: const pw.EdgeInsets.only(top: 8, bottom: 2),
                    color: PdfColors.grey200,
                    child: pw.Text(
                      groupTitle,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                  ),
                  ...rows.map((r) {
                    final baseAlert = _resolveAlertFlag(r.baseResult, r.referenceValues);
                    final compAlert = _resolveAlertFlag(r.comparisonResult, r.referenceValues);

                    final baseVal = r.baseResult?.resultValue != null &&
                            r.baseResult!.resultValue!.isNotEmpty
                        ? ThousandsSeparatorInputFormatter.formatText(r.baseResult!.resultValue!)
                        : '—';

                    final compVal = r.comparisonResult?.resultValue != null &&
                            r.comparisonResult!.resultValue!.isNotEmpty
                        ? ThousandsSeparatorInputFormatter.formatText(r.comparisonResult!.resultValue!)
                        : '—';

                    final deltaAbs = r.deltaAbsolute;
                    final deltaPct = r.deltaPercentage;

                    String deltaText = '—';
                    PdfColor deltaColor = PdfColors.grey800;

                    if (deltaAbs != null && deltaPct != null) {
                      final sign = deltaAbs > 0 ? '+' : '';
                      final formattedDelta = deltaAbs.abs() >= 100
                          ? deltaAbs.toStringAsFixed(0)
                          : deltaAbs.toStringAsFixed(1);
                      final pctSign = deltaPct > 0 ? '+' : '';
                      deltaText = '$sign$formattedDelta ($pctSign${deltaPct.toStringAsFixed(1)}%)';

                      if (deltaAbs.abs() > 0.001) {
                        deltaColor = deltaAbs > 0 ? PdfColors.teal900 : PdfColors.indigo900;
                      }
                    }

                    final refText = _resolveReferenceText(r, patientAge, genderStr);

                    return pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 32,
                            child: pw.Text(
                              r.parameterName,
                              style: const pw.TextStyle(fontSize: 8.5),
                            ),
                          ),
                          pw.Expanded(
                            flex: 12,
                            child: pw.Text(
                              r.unitOfMeasure,
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                            ),
                          ),
                          pw.Expanded(
                            flex: 16,
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Text(
                                  baseVal,
                                  style: pw.TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: baseAlert != null
                                        ? pw.FontWeight.bold
                                        : pw.FontWeight.normal,
                                  ),
                                ),
                                if (baseAlert != null) ...[
                                  pw.SizedBox(width: 2),
                                  pw.Text(
                                    baseAlert,
                                    style: pw.TextStyle(
                                      fontSize: 7.5,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.red800,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          pw.Expanded(
                            flex: 16,
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Text(
                                  compVal,
                                  style: pw.TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: compAlert != null
                                        ? pw.FontWeight.bold
                                        : pw.FontWeight.normal,
                                  ),
                                ),
                                if (compAlert != null) ...[
                                  pw.SizedBox(width: 2),
                                  pw.Text(
                                    compAlert,
                                    style: pw.TextStyle(
                                      fontSize: 7.5,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.red800,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          pw.Expanded(
                            flex: 14,
                            child: pw.Text(
                              deltaText,
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: deltaColor,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 20,
                            child: pw.Text(
                              refText,
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            }),

            pw.SizedBox(height: 16),
            // Leyenda de alertas
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(3),
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              ),
              child: pw.Text(
                'Convenciones de Alerta: H = Superior al rango normal (Alto) | L = Inferior al rango normal (Bajo) | * = Valor Anormal cualitativo. '
                'Delta: Variación evolutiva entre la orden base (#$shortBaseId) y la orden reciente (#$shortCompId).',
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
              ),
            ),
          ];
        },
      ),
    );

    return doc;
  }
}
