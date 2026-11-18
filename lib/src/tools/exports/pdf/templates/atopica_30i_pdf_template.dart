import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:serum_business/serum_business.dart';

import '../../../../tools/cache/app_image_cache.dart';
import '../pdf_font_helper.dart';
import '../pdf_template.dart';
import 'atopica_30i_helper.dart';
import 'clinical_order_pdf_template.dart';

class Atopica30iPdfTemplate implements PdfTemplate {
  final OrderInDb order;
  final BranchInDb branch;
  final PatientInfo? patientInfo;
  final DoctorInfo? doctorInfo;
  final BioanalystInfo? signer;

  Atopica30iPdfTemplate({
    required this.order,
    required this.branch,
    PatientInfo? patientInfo,
    DoctorInfo? doctorInfo,
    BioanalystInfo? signer,
  }) : patientInfo = patientInfo ?? order.patientInfo,
       doctorInfo = doctorInfo ?? order.doctorInfo,
       signer = signer ?? branch.bioanalyst;

  String _formatGender(String gender) {
    final g = gender.trim().toLowerCase();
    if (g == 'm' || g == 'male' || g == 'masculino') return 'Masculino';
    if (g == 'f' || g == 'female' || g == 'femenino') return 'Femenino';
    return gender.isEmpty ? 'No especificado' : gender;
  }

  @override
  Future<pw.Document> buildDocument() async {
    await PdfFontHelper.ensureInitialized();
    final doc = pw.Document();

    final orderDate = DateTime.fromMillisecondsSinceEpoch(order.createdAt);
    final formattedDate =
        '${DateTimeTool.formatddMMyy(orderDate)} ${DateTimeTool.formatHHmm(orderDate)}';

    pw.MemoryImage? headerImage;
    pw.MemoryImage? sealImage;

    final headerImageUrl = branch.effectiveIsoLogo;
    final effectiveSigner = signer ?? branch.bioanalyst;
    final sealImageUrl = effectiveSigner?.sealUrl;

    if (headerImageUrl != null && headerImageUrl.isNotEmpty) {
      final bytes = await AppImageCache.getImageBytes(headerImageUrl);
      if (bytes != null) {
        headerImage = pw.MemoryImage(bytes);
      }
    }

    if (sealImageUrl != null && sealImageUrl.isNotEmpty) {
      final bytes = await AppImageCache.getImageBytes(sealImageUrl);
      if (bytes != null) {
        sealImage = pw.MemoryImage(bytes);
      }
    }

    final patient =
        patientInfo ??
        PatientInfo(
          name: 'Paciente #${order.patientId}',
          dateOfBirth: 0,
          gender: '',
        );

    final ageInDays = ReferenceValueResolver.tryAgeInDaysAt(
      dateOfBirthMs: patient.dateOfBirth,
      referenceDateMs: order.createdAt,
      fallbackAgeYears: patient.explicitAge,
    );
    final ageLabel = ageInDays != null
        ? ReferenceValueResolver.formatAgeDays(ageInDays)
        : 'Sin edad';

    final split = Atopica30iHelper.splitResults(order);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildCompactHeader(formattedDate, headerImage),
              pw.SizedBox(height: 6),
              _buildPatientStrip(patient, ageLabel, formattedDate),
              pw.SizedBox(height: 8),
              _buildAllergenTable(split.atopica),
              pw.SizedBox(height: 5),
              ...Atopica30iHelper.mixNotes.map(
                (note) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 1.5),
                  child: pw.Text(
                    note,
                    style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey800),
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              _buildClassScaleTable(),
              pw.Spacer(),
              _buildCompactSignatureAndFooter(effectiveSigner, sealImage),
            ],
          );
        },
      ),
    );

    if (split.others.isNotEmpty) {
      final remainingOrder = Atopica30iHelper.filterOrder(order, split.others);
      final remainingTemplate = SingleClinicalOrderTemplate(
        order: remainingOrder,
        branch: branch,
        patientInfo: patientInfo,
        doctorInfo: doctorInfo,
        signer: signer,
      );
      final remainingDoc = await remainingTemplate.buildDocument();
      assert(remainingDoc.document.pdfPageList.pages.isNotEmpty);
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          build: (_) => [
            pw.Text(
              'Pruebas Adicionales de la Orden',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            _buildRemainingResultsTable(split.others),
          ],
        ),
      );
    }

    return doc;
  }

  pw.Widget _buildCompactHeader(String formattedDate, pw.MemoryImage? headerImage) {
    final shortId = order.id.length > 8
        ? order.id.substring(order.id.length - 8).toUpperCase()
        : order.id.toUpperCase();

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Row(
          children: [
            if (headerImage != null) ...[
              pw.Image(headerImage, height: 34, fit: pw.BoxFit.contain),
              pw.SizedBox(width: 8),
            ],
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  branch.name,
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                if (branch.address.trim().isNotEmpty)
                  pw.Text(
                    branch.address.trim(),
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                  ),
              ],
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Test (Alergias): Atópica 30-I',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Orden #$shortId  |  Fecha: $formattedDate',
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPatientStrip(
    PatientInfo patient,
    String ageLabel,
    String formattedDate,
  ) {
    final doctorName = doctorInfo?.name.trim();
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400, width: 0.6),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            flex: 4,
            child: pw.Text(
              'Paciente: ${patient.name}',
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              'Edad: $ageLabel',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              'Sexo: ${_formatGender(patient.gender)}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
          if (doctorName != null && doctorName.isNotEmpty)
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                'Médico: $doctorName',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.right,
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildAllergenTable(List<OrderTestResult> results) {
    const barWidth = 220.0;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.7),
        1: const pw.FlexColumnWidth(0.75),
        2: const pw.FlexColumnWidth(1.05),
        3: const pw.FixedColumnWidth(barWidth),
      },
      children: [
        // Encabezado fila 1: Alérgenos | Clase | [vacío] | Clases 0..4-6
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              child: pw.Text(
                'Alérgenos',
                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              child: pw.Center(
                child: pw.Text(
                  'Clase',
                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              child: pw.Center(
                child: pw.Text(
                  'IgE [kU/L]',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('0', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text('1', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text('2', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text('3', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text('4 - 6', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.SizedBox(height: 1),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: Atopica30iHelper.scaleTicks
                        .map(
                          (t) => pw.Text(
                            t == 100.0 ? '100' : t.toString(),
                            style: const pw.TextStyle(fontSize: 6),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Filas de los 30 alérgenos
        ...results.map((r) {
          final rawVal = (r.resultValue ?? '').trim();
          final igeClass = Atopica30iHelper.computeIgeClass(rawVal);
          final fraction = Atopica30iHelper.computeScaleFraction(rawVal);
          final isPositive = igeClass != null && igeClass >= 1;
          final barFillWidth = (barWidth - 8) * fraction;

          return pw.TableRow(
            decoration: isPositive
                ? const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFFF5F5))
                : null,
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.8),
                child: pw.Text(
                  r.parameterName,
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: isPositive ? pw.FontWeight.bold : pw.FontWeight.normal,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1.8),
                child: pw.Center(
                  child: pw.Text(
                    igeClass?.toString() ?? '-',
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight: isPositive ? pw.FontWeight.bold : pw.FontWeight.normal,
                      color: isPositive ? PdfColors.red900 : PdfColors.black,
                    ),
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1.8),
                child: pw.Center(
                  child: pw.Text(
                    rawVal.isEmpty ? '-' : rawVal,
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight: isPositive ? pw.FontWeight.bold : pw.FontWeight.normal,
                      color: isPositive ? PdfColors.red900 : PdfColors.black,
                    ),
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
                child: pw.Container(
                  height: 6,
                  alignment: pw.Alignment.centerLeft,
                  child: barFillWidth > 0.5
                      ? pw.Container(
                          width: barFillWidth,
                          height: 5.5,
                          decoration: pw.BoxDecoration(
                            color: isPositive
                                ? const PdfColor.fromInt(0xFFE5A1A1)
                                : PdfColors.grey400,
                            border: pw.Border.all(
                              color: isPositive ? PdfColors.red900 : PdfColors.grey700,
                              width: 0.6,
                            ),
                          ),
                        )
                      : pw.SizedBox(),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildClassScaleTable() {
    final left = Atopica30iHelper.classDescriptors.sublist(0, 4);
    final right = Atopica30iHelper.classDescriptors.sublist(4);

    pw.Widget cell(String text, {bool bold = false, pw.TextAlign align = pw.TextAlign.left}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: 6.5,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.7),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(2.6),
        3: const pw.FlexColumnWidth(0.7),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(2.6),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            cell('Clase', bold: true, align: pw.TextAlign.center),
            cell('Conc. IgE [kU/l]', bold: true, align: pw.TextAlign.center),
            cell('Explicación', bold: true),
            cell('Clase', bold: true, align: pw.TextAlign.center),
            cell('Conc. IgE [kU/l]', bold: true, align: pw.TextAlign.center),
            cell('Explicación', bold: true),
          ],
        ),
        for (var i = 0; i < left.length; i++)
          pw.TableRow(
            children: [
              cell('${left[i].classNumber}', align: pw.TextAlign.center),
              cell(left[i].rangeLabel, align: pw.TextAlign.center),
              cell(left[i].description),
              if (i < right.length) ...[
                cell('${right[i].classNumber}', align: pw.TextAlign.center),
                cell(right[i].rangeLabel, align: pw.TextAlign.center),
                cell(right[i].description),
              ] else ...[
                cell(''),
                cell(''),
                cell(''),
              ],
            ],
          ),
      ],
    );
  }

  pw.Widget _buildRemainingResultsTable(List<OrderTestResult> others) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Prueba', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Resultado', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Unidad', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        ...others.map(
          (r) => pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(r.parameterName, style: const pw.TextStyle(fontSize: 8.5)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(r.resultValue ?? '-', style: const pw.TextStyle(fontSize: 8.5)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(r.unitOfMeasure, style: const pw.TextStyle(fontSize: 8.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCompactSignatureAndFooter(
    BioanalystInfo? effectiveSigner,
    pw.MemoryImage? sealImage,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              branch.phone.trim().isNotEmpty
                  ? 'Tel: ${branch.phone.trim()}${branch.email?.trim().isNotEmpty == true ? ' | ${branch.email!.trim()}' : ''}'
                  : (branch.email?.trim() ?? ''),
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (sealImage != null)
                  pw.Image(sealImage, height: 32, fit: pw.BoxFit.contain)
                else
                  pw.SizedBox(height: 24),
                pw.Container(width: 150, height: 0.7, color: PdfColors.black),
                pw.SizedBox(height: 2),
                pw.Text(
                  effectiveSigner?.name.trim().isNotEmpty == true
                      ? effectiveSigner!.name.trim()
                      : 'Responsable de Laboratorio',
                  style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                ),
                if (effectiveSigner?.title.trim().isNotEmpty == true)
                  pw.Text(
                    effectiveSigner!.title.trim(),
                    style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
