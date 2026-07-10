import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/exam_cubit/read_exams_cubit.dart';
import '../../../cubits/exam_cubit/write_exams_cubit.dart';

class ExamsList extends StatelessWidget {
  final List<ExamInDb> exams;
  final Function(ExamInDb) onEdit;

  const ExamsList({
    super.key,
    required this.exams,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (exams.isEmpty) {
      return const Center(child: Text('No se encontraron exámenes'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
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
                  child: const Icon(Icons.biotech),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.name,
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
                                exam.commercialCategory,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.science, size: 14, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                '${exam.includedTests.length} pruebas incluidas',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Precio: ${exam.salePrice} ${exam.currency}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => onEdit(exam),
                  color: theme.colorScheme.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text('Eliminar Examen'),
                        content: Text('¿Está seguro de eliminar el examen ${exam.name}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<WriteExamCubit>().delete(exam.id).then((_) {
                                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                                if (context.mounted) context.read<ReadExamCubit>().getAll();
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
