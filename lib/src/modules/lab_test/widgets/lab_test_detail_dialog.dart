import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

class LabTestDetailDialog extends StatelessWidget {
  final LabTestInDb labTest;
  final List<LabTestInDb> allLabTests;

  const LabTestDetailDialog({
    super.key,
    required this.labTest,
    this.allLabTests = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceFormatted = (labTest.salePrice / 100.0).toStringAsFixed(2);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: labTest.isPack
                    ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.25)
                    : theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: labTest.isPack
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    child: Icon(labTest.isPack ? Icons.inventory_2 : Icons.science),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                labTest.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: labTest.isPack
                                    ? theme.colorScheme.tertiary
                                    : theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                labTest.isPack ? 'PACK / PERFIL' : 'INDIVIDUAL',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (labTest.code != null && labTest.code!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Clave / Código: ${labTest.code}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila de Métricas Principales
                    Row(
                      children: [
                        Expanded(
                          child: _InfoTile(
                            label: 'Precio de Venta',
                            value: '\$$priceFormatted USD',
                            icon: Icons.sell,
                            isHighlighted: true,
                          ),
                        ),
                        /* // Comentado temporalmente por requerimiento del cliente: Soporte Precio 2
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoTile(
                            label: 'Precio 2 (Especial)',
                            value: labTest.salePrice2 > 0
                                ? '\$${(labTest.salePrice2 / 100.0).toStringAsFixed(2)} USD'
                                : 'Sin asignar',
                            icon: Icons.local_offer_outlined,
                            isHighlighted: labTest.salePrice2 > 0,
                          ),
                        ),
                        */
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoTile(
                            label: 'Categoría Comercial',
                            value: labTest.commercialCategory.isNotEmpty
                                ? labTest.commercialCategory
                                : 'Sin Asignar',
                            icon: Icons.category,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (labTest.isPack) ...[
                      _buildPackContent(context),
                    ] else ...[
                      _buildIndividualContent(context),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualContent(BuildContext context) {
    final theme = Theme.of(context);

    String typeLabel;
    switch (labTest.dataType) {
      case 'boolean':
        typeLabel = 'Cualitativo / Booleano (Sí/No, Positivo/Negativo)';
        break;
      case 'text':
        typeLabel = 'Texto Libre / Descriptivo';
        break;
      case 'numeric':
      default:
        typeLabel = 'Numérico (con Rangos y Unidades)';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                label: 'Tipo de Resultado',
                value: typeLabel,
                icon: Icons.biotech,
              ),
            ),
            if (labTest.dataType == 'numeric' && labTest.unitOfMeasure.isNotEmpty) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  label: 'Unidad de Medida',
                  value: labTest.unitOfMeasure,
                  icon: Icons.straighten,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),

        if (labTest.dataType == 'numeric') ...[
          Text(
            'Valores y Rangos de Referencia',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (labTest.referenceValues.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'No se han configurado valores de referencia específicos para esta prueba.',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ),
            )
          else
            Table(
              border: TableBorder.all(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHigh),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Género', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Rango Edad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Rango Normal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                ...labTest.referenceValues.map((ref) {
                  final genderLabel = ref.gender == 'male'
                      ? 'Masculino'
                      : ref.gender == 'female'
                          ? 'Femenino'
                          : 'Ambos';
                  final ageYearsMin = (ref.minAgeDays / 365).floor();
                  final ageYearsMax = (ref.maxAgeDays / 365).floor();
                  final ageLabel = ref.maxAgeDays >= 36500
                      ? 'Todas las edades'
                      : '$ageYearsMin - $ageYearsMax años';

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(genderLabel, style: const TextStyle(fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(ageLabel, style: const TextStyle(fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          '${ref.minValue} - ${ref.maxValue} ${labTest.unitOfMeasure}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
        ],

        if (labTest.dataType == 'boolean') ...[
          Text(
            'Configuración Cualitativa',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Opciones posibles: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(
                      labTest.qualitativeOptions.isNotEmpty
                          ? labTest.qualitativeOptions.join(', ')
                          : 'Negativo, Positivo',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('Valor Normal Esperado: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(
                      labTest.expectedQualitativeValue ?? 'No definido',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPackContent(BuildContext context) {
    final theme = Theme.of(context);

    final childTests = allLabTests
        .where((t) => labTest.childTestIds.contains(t.id))
        .toList();

    final individualSumCents = childTests.fold<int>(0, (sum, t) => sum + t.salePrice);
    final individualSum = individualSumCents / 100.0;
    final packPrice = labTest.salePrice / 100.0;
    final savings = individualSum - packPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Análisis Incluidos (${labTest.childTestIds.length})',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (savings > 0 && individualSum > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Text(
                  'Ahorro del Pack: \$${savings.toStringAsFixed(2)} USD (${((savings / individualSum) * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (childTests.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'No se tienen detalles de las pruebas hijas o no se seleccionaron pruebas para este pack.',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: childTests.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: theme.colorScheme.outlineVariant),
              itemBuilder: (context, index) {
                final test = childTests[index];
                final price = (test.salePrice / 100.0).toStringAsFixed(2);

                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text('${index + 1}', style: const TextStyle(fontSize: 11)),
                  ),
                  title: Text(test.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${test.commercialCategory}${test.unitOfMeasure.isNotEmpty ? " • ${test.unitOfMeasure}" : ""}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Text(
                    '\$$price USD',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isHighlighted;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isHighlighted ? theme.colorScheme.primary : theme.colorScheme.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                    fontSize: isHighlighted ? 15 : 13,
                    color: isHighlighted ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
