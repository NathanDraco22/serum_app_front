import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/administration/widgets/admin_module_card.dart';

void main() {
  group('Layout Overflow and Rendering Fixes Tests', () {
    testWidgets('AdminModuleCard renders in constrained height without vertical overflow',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 210, // Height that previously caused 29px bottom overflow
                child: AdminModuleCard(
                  title: 'Sucursales / Sedes',
                  description:
                      'Alta, modificación y control de sedes físicas, direcciones de atención clínica y teléfonos de contacto.',
                  icon: Icons.store_mall_directory_rounded,
                  iconColor: Colors.blue,
                  iconBackgroundColor: Colors.blue.withAlpha(50),
                  badgeText: 'Sedes Físicas',
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sucursales / Sedes'), findsOneWidget);
      expect(find.text('Administrar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('DropdownButtonFormField with isExpanded=true handles long text without horizontal overflow',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 220, // Very narrow container
                child: DropdownButtonFormField<String?>(
                  initialValue: 'shift_1',
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por Turno',
                    prefixIcon: Icon(Icons.lock_clock_outlined, size: 20),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'shift_1',
                      child: Text(
                        '🟢 Mi Turno Activo (#12345678) • Este texto es extremadamente largo para el ancho disponible',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<String?>), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ListTile inside solid Material does not trigger framework warnings',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: Material(
              color: Colors.grey.shade100,
              child: SizedBox(
                width: 260,
                child: ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Inicio'),
                  selected: true,
                  selectedTileColor: Colors.blue.withAlpha(38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Inicio'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
