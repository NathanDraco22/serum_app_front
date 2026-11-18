import 'package:material_ui/material_ui.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../tools/exports/pdf/templates/atopica_30i_helper.dart';

class Atopica30iSpecialView extends StatelessWidget {
  final OrderInDb order;

  const Atopica30iSpecialView({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final split = Atopica30iHelper.splitResults(order);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
          child: const Text(
            'Test (Alergias): Atópica 30-I',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        _buildAllergensTable(split.atopica),
        const SizedBox(height: 10),
        ...Atopica30iHelper.mixNotes.map(
          (note) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              note,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildClassLegendTable(),
      ],
    );
  }

  Widget _buildAllergensTable(List<OrderTestResult> results) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black87, width: 0.8),
      ),
      child: Column(
        children: [
          Container(
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Alérgenos',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Clase',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'IgE [kU/L]',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          Text('1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          Text('2', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          Text('3', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          Text('4 - 6', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: Atopica30iHelper.scaleTicks
                            .map(
                              (t) => Text(
                                t == 100.0 ? '100' : t.toString(),
                                style: const TextStyle(fontSize: 9.5),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...results.map((r) {
            final rawVal = (r.resultValue ?? '').trim();
            final igeClass = Atopica30iHelper.computeIgeClass(rawVal);
            final fraction = Atopica30iHelper.computeScaleFraction(rawVal);
            final isPositive = igeClass != null && igeClass >= 1;

            return Container(
              decoration: BoxDecoration(
                color: isPositive ? const Color(0xFFFFF5F5) : Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade400, width: 0.6)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      r.parameterName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isPositive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      igeClass?.toString() ?? '-',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isPositive ? FontWeight.bold : FontWeight.normal,
                        color: isPositive ? Colors.red.shade900 : Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      rawVal.isEmpty ? '-' : rawVal,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isPositive ? FontWeight.bold : FontWeight.normal,
                        color: isPositive ? Colors.red.shade900 : Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final barWidth = constraints.maxWidth * fraction;
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: barWidth > 1
                              ? Container(
                                  width: barWidth,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: isPositive
                                        ? const Color(0xFFE5A1A1)
                                        : Colors.grey.shade400,
                                    border: Border.all(
                                      color: isPositive
                                          ? Colors.red.shade900
                                          : Colors.grey.shade700,
                                      width: 0.8,
                                    ),
                                  ),
                                )
                              : const SizedBox(height: 10),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildClassLegendTable() {
    final left = Atopica30iHelper.classDescriptors.sublist(0, 4);
    final right = Atopica30iHelper.classDescriptors.sublist(4);

    return Table(
      border: TableBorder.all(color: Colors.black54, width: 0.6),
      columnWidths: const {
        0: FlexColumnWidth(0.7),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(2.6),
        3: FlexColumnWidth(0.7),
        4: FlexColumnWidth(1.2),
        5: FlexColumnWidth(2.6),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade200),
          children: const [
            _LegendCell('Clase', bold: true, align: TextAlign.center),
            _LegendCell('Conc. IgE [kU/l]', bold: true, align: TextAlign.center),
            _LegendCell('Explicación', bold: true),
            _LegendCell('Clase', bold: true, align: TextAlign.center),
            _LegendCell('Conc. IgE [kU/l]', bold: true, align: TextAlign.center),
            _LegendCell('Explicación', bold: true),
          ],
        ),
        for (var i = 0; i < left.length; i++)
          TableRow(
            children: [
              _LegendCell('${left[i].classNumber}', align: TextAlign.center),
              _LegendCell(left[i].rangeLabel, align: TextAlign.center),
              _LegendCell(left[i].description),
              if (i < right.length) ...[
                _LegendCell('${right[i].classNumber}', align: TextAlign.center),
                _LegendCell(right[i].rangeLabel, align: TextAlign.center),
                _LegendCell(right[i].description),
              ] else ...[
                const _LegendCell(''),
                const _LegendCell(''),
                const _LegendCell(''),
              ],
            ],
          ),
      ],
    );
  }
}

class _LegendCell extends StatelessWidget {
  final String text;
  final bool bold;
  final TextAlign align;

  const _LegendCell(
    this.text, {
    this.bold = false,
    this.align = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
