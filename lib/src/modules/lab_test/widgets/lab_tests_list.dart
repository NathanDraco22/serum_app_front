import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/lab_test_cubit/read_lab_tests_cubit.dart';
import '../../../cubits/lab_test_cubit/write_lab_tests_cubit.dart';

class LabTestsList extends StatelessWidget {
  final List<LabTestInDb> labTests;
  final Function(LabTestInDb) onEdit;

  const LabTestsList({
    super.key,
    required this.labTests,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (labTests.isEmpty) {
      return const Center(child: Text('No se encontraron pruebas'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: labTests.length,
      itemBuilder: (context, index) {
        final labTest = labTests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: const Icon(Icons.science),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labTest.parameterName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.category, size: 14, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                labTest.medicalClassification,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.input, size: 14, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                'Tipo: ${labTest.dataType}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.straighten, size: 14, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                'Unidad: ${labTest.unitOfMeasure}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (labTest.referenceValues.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: labTest.referenceValues.map((ref) {
                            return Chip(
                              labelPadding: const EdgeInsets.all(0),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              label: Text(
                                '${ref.gender == 'male' ? 'M' : ref.gender == 'female' ? 'F' : 'G'} (${ref.minValue}-${ref.maxValue} ${labTest.unitOfMeasure})',
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => onEdit(labTest),
                  color: theme.colorScheme.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text('Eliminar Prueba'),
                        content: Text('¿Está seguro de eliminar la prueba ${labTest.parameterName}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<WriteLabTestCubit>().delete(labTest.id).then((_) {
                                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                                if (context.mounted) context.read<ReadLabTestCubit>().getAll();
                              });
                            },
                            child: Text(
                              'Eliminar',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  color: theme.colorScheme.error,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
