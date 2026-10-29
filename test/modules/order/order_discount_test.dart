import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/order/widgets/add_discount_dialog.dart';
import 'package:serum_app_front/src/modules/order/widgets/order_cart_section.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  group('AddDiscountDialog Widget Tests', () {
    testWidgets('Permite ingresar descuento porcentual y valida correctamente', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      OrderDiscount? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AddDiscountDialog.show(
                    context,
                    currentSubtotal: 50000, // C$ 500.00
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      // Abrir diálogo
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Agregar Descuento a la Orden'), findsOneWidget);
      expect(find.text('Porcentaje (%)'), findsOneWidget);

      // Ingresar motivo y porcentaje
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Motivo o Concepto del Descuento *'),
        'Descuento Tercera Edad',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Porcentaje de descuento (%) *'),
        '10',
      );
      await tester.pumpAndSettle();

      // Debe calcular $50.00 de deducción (5000 centavos) sobre subtotal de $500.00
      expect(find.textContaining('50.00'), findsWidgets);
      expect(find.textContaining('450.00'), findsOneWidget);

      // Presionar Aplicar Descuento
      await tester.ensureVisible(find.text('Aplicar Descuento'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Aplicar Descuento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aplicar Descuento'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.description, 'Descuento Tercera Edad');
      expect(result!.type, 'percentage');
      expect(result!.value, 10.0);
      expect(result!.appliedAmount, 5000);
    });

    testWidgets('Permite cambiar a monto fijo y valida que no exceda el subtotal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      OrderDiscount? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AddDiscountDialog.show(
                    context,
                    currentSubtotal: 20000, // C$ 200.00
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Cambiar a Monto Fijo
      await tester.tap(find.text('Monto Fijo (C\$)'));
      await tester.pumpAndSettle();

      // Intentar ingresar un monto superior al subtotal
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Motivo o Concepto del Descuento *'),
        'Ajuste Excesivo',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Monto de descuento (C\$) *'),
        '250.00',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Aplicar Descuento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aplicar Descuento'));
      await tester.pumpAndSettle();

      // Debe mostrar error de validación
      expect(find.textContaining('El monto no puede superar el subtotal'), findsOneWidget);
      expect(result, isNull);

      // Corregir a C$ 50.00
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Monto de descuento (C\$) *'),
        '50.00',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Aplicar Descuento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aplicar Descuento'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.type, 'amount');
      expect(result!.value, 50.0);
      expect(result!.appliedAmount, 5000);
    });
  });

  group('OrderCartSection Discounts Integration Tests', () {
    testWidgets('Renderiza descuentos y muestra advertencia de supervisor requerida', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      bool discountRemoved = false;

      final testItem = LabTestInDb(
        id: 'test_1',
        name: 'Glucosa en Sangre',
        salePrice: 10000, // C$ 100.00
        createdAt: 0,
      );

      final discount = OrderDiscount(
        id: 'd_1',
        description: 'Tercera Edad',
        type: 'percentage',
        value: 15.0,
        appliedAmount: 1500, // C$ 15.00
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 700,
              height: 1000,
              child: OrderCartSection(
                selectedPatient: PatientInDb(
                  id: 'p_1',
                  name: 'Juan Perez',
                  originBranch: 'b_1',
                  dateOfBirth: 946684800000,
                  gender: 'M',
                  phone: '12345678',
                  createdAt: 0,
                ),
                selectedDoctor: null,
                selectedItems: [testItem],
                discounts: [discount],
                isSubmitting: false,
                onSelectPatient: () {},
                onRemovePatient: () {},
                onSelectDoctor: () {},
                onRemoveDoctor: () {},
                onRemoveItem: (_) {},
                onPriceLevelChanged: (_, _) {},
                onDefaultPriceLevelChanged: (_) {},
                onEditItemPrice: (_) {},
                onClearItems: () {},
                onAddService: () {},
                onRemoveService: (_) {},
                onEditService: (_) {},
                onAddDiscount: () {},
                onRemoveDiscount: (d) => discountRemoved = true,
                onEditDiscount: (_) {},
                onSubmitOrder: () {},
              ),
            ),
          ),
        ),
      );

      // Verificar que renderice el descuento y la advertencia de supervisor
      expect(find.text('Descuentos en la Orden (1)'), findsOneWidget);
      expect(find.text('Tercera Edad'), findsOneWidget);
      expect(find.textContaining('15.00'), findsWidgets); // En el tile y en el resumen
      expect(find.textContaining('85.00'), findsOneWidget); // Total a cobrar (100 - 15)
      expect(
        find.textContaining('Descuento aplicado: La orden se creará con requerimiento de autorización de supervisor.'),
        findsOneWidget,
      );

      // Quitar descuento
      await tester.tap(find.byTooltip('Quitar descuento'));
      await tester.pumpAndSettle();

      expect(discountRemoved, isTrue);
    });
  });
}
