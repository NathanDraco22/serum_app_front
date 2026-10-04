import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/tools/exports/exports.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReportPdfHelper Tests', () {
    test('formatCurrency formatea centavos a formato de moneda con decimales y comas', () {
      expect(ReportPdfHelper.formatCurrency(0), equals('\$0.00'));
      expect(ReportPdfHelper.formatCurrency(100), equals('\$1.00'));
      expect(ReportPdfHelper.formatCurrency(1550), equals('\$15.50'));
      expect(ReportPdfHelper.formatCurrency(125000), equals('\$1,250.00'));
      expect(ReportPdfHelper.formatCurrency(10000000), equals('\$100,000.00'));
      expect(ReportPdfHelper.formatCurrency(-2500), equals('-\$25.00'));
    });

    test('formatDate y formatDateTime retornan cadenas coherentes', () {
      final date = DateTime(2026, 10, 4, 14, 30);
      expect(ReportPdfHelper.formatDate(date), equals('04/10/2026'));
      expect(ReportPdfHelper.formatDateTime(date), equals('04/10/2026 14:30'));
    });
  });

  group('Reports PDF Templates Generation Tests', () {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    test('FinancialReportPdfTemplate construye documento PDF válido', () async {
      final report = FinancialReportResponse(
        startDate: nowMs - 86400000,
        endDate: nowMs,
        summary: const FinancialSummaryReport(
          totalBilled: 500000,
          totalCollected: 450000,
          pendingReceivables: 50000,
          ordersCount: 15,
          transactionsCount: 18,
          paymentMethods: PaymentMethodsBreakdown(
            cash: 250000,
            card: 150000,
            transfer: 50000,
          ),
        ),
        byBranch: const [
          FinancialBranchReport(
            branchId: 'b1',
            branchName: 'Sede Centro',
            totalBilled: 500000,
            totalCollected: 450000,
            pendingReceivables: 50000,
            ordersCount: 15,
            transactionsCount: 18,
            paymentMethods: PaymentMethodsBreakdown(
              cash: 250000,
              card: 150000,
              transfer: 50000,
            ),
          ),
        ],
      );

      final template = FinancialReportPdfTemplate(
        report: report,
        branchName: 'Sucursal Centro',
        branchAddress: 'Av. Libertador #123',
        branchPhone: '555-1234',
        generatedBy: 'Admin',
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('TopDoctorsReportPdfTemplate construye documento PDF válido', () async {
      final report = TopDoctorsReportResponse(
        startDate: nowMs - 86400000,
        endDate: nowMs,
        summary: const TopDoctorsSummary(
          totalOrders: 10,
          totalRevenue: 300000,
          topDoctors: [
            DoctorOrderItem(
              doctorId: 'd1',
              doctorName: 'Dr. Roberto Gómez',
              specialty: 'Medicina Interna',
              totalOrders: 7,
              totalRevenue: 210000,
            ),
            DoctorOrderItem(
              doctorId: 'd2',
              doctorName: 'Dra. María Pérez',
              specialty: 'Pediatría',
              totalOrders: 3,
              totalRevenue: 90000,
            ),
          ],
        ),
      );

      final template = TopDoctorsReportPdfTemplate(
        report: report,
        branchName: 'Sucursal Matriz',
        generatedBy: 'Operador 1',
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('LabTestsVolumeReportPdfTemplate construye documento PDF válido', () async {
      final report = LabTestsVolumeReportResponse(
        startDate: nowMs - 86400000,
        endDate: nowMs,
        source: 'orders',
        summary: const LabTestsVolumeSummary(
          totalTestsCount: 20,
          totalRevenue: 400000,
          topTests: [
            LabTestVolumeItem(
              labTestId: 't1',
              name: 'Biometría Hemática Completa',
              category: 'Hematología',
              isPack: false,
              timesOrdered: 12,
              totalRevenue: 180000,
            ),
            LabTestVolumeItem(
              labTestId: 't2',
              name: 'Perfil Bioquímico 24 Elementos',
              category: 'Química Clínica',
              isPack: true,
              timesOrdered: 8,
              totalRevenue: 220000,
            ),
          ],
        ),
      );

      final template = LabTestsVolumeReportPdfTemplate(
        report: report,
        branchName: 'Laboratorio Central',
        generatedBy: 'Bioanalista',
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('PendingBalancesReportPdfTemplate construye documento PDF válido', () async {
      final report = PendingBalancesReportResponse(
        startDate: nowMs - 86400000,
        endDate: nowMs,
        summary: const PendingBalancesSummary(
          totalPendingAmount: 150000,
          ordersCount: 2,
        ),
        byBranch: [
          PendingBalancesBranchReport(
            branchId: 'b1',
            branchName: 'Sede Norte',
            totalPendingAmount: 150000,
            ordersCount: 2,
            orders: [
              PendingBalanceItem(
                orderId: 'ORD-00192837',
                patientId: 'p1',
                patientName: 'Carlos Santillán',
                patientPhone: '555-9876',
                totalPrice: 100000,
                paidAmount: 20000,
                pendingAmount: 80000,
                orderDate: nowMs - 1000000,
                daysPending: 18,
              ),
              PendingBalanceItem(
                orderId: 'ORD-00192838',
                patientId: 'p2',
                patientName: 'Lucía Méndez',
                patientPhone: '555-5432',
                totalPrice: 90000,
                paidAmount: 20000,
                pendingAmount: 70000,
                orderDate: nowMs - 500000,
                daysPending: 5,
              ),
            ],
          ),
        ],
      );

      final template = PendingBalancesReportPdfTemplate(
        report: report,
        branchName: 'Sede Norte',
        generatedBy: 'Auditor Financiero',
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('ShiftsAuditReportPdfTemplate construye documento PDF válido', () async {
      final report = ShiftsAuditReportResponse(
        startDate: nowMs - 86400000,
        endDate: nowMs,
        summary: const ShiftsAuditSummary(
          totalShifts: 2,
          totalDiscrepancies: 1,
          netDifference: -5000,
        ),
        byBranch: [
          ShiftsAuditBranchReport(
            branchId: 'b1',
            branchName: 'Sede Central',
            totalShifts: 2,
            totalDiscrepancies: 1,
            netDifference: -5000,
            shifts: [
              ShiftAuditItem(
                shiftId: 's1',
                userId: 'u1',
                userName: 'Juan Cajero',
                openedAt: nowMs - 36000000,
                closedAt: nowMs - 18000000,
                initialBalance: 50000,
                cashBalance: 120000,
                declaredCash: 115000,
                difference: -5000,
                notes: 'Faltante de \$50 en arqueo',
              ),
              ShiftAuditItem(
                shiftId: 's2',
                userId: 'u2',
                userName: 'Ana Cajera',
                openedAt: nowMs - 18000000,
                closedAt: nowMs,
                initialBalance: 50000,
                cashBalance: 90000,
                declaredCash: 90000,
                difference: 0,
                notes: 'Cuadre exacto',
              ),
            ],
          ),
        ],
      );

      final template = ShiftsAuditReportPdfTemplate(
        report: report,
        branchName: 'Sede Central',
        generatedBy: 'Supervisor',
        discrepanciesOnly: false,
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });
  });
}
