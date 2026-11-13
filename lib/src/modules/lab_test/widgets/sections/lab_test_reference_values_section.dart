import 'package:flutter/material.dart';
import '../../controllers/lab_test_form_mediator.dart';
import '../../controllers/lab_test_form_view_controller.dart';
import '../reference_values_editor.dart';

class LabTestReferenceValuesSection extends StatelessWidget {
  const LabTestReferenceValuesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = LabTestFormMediator.controllerOf(context);
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isPack) return const SizedBox.shrink();

        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.biotech_outlined,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Configuración Analítica y Rangos de Referencia',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: controller.dataType,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Tipo de Resultado',
                          prefixIcon: const Icon(Icons.science, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'numeric',
                            child: Text(
                              'Numérico (Unidad de Medida y Rangos Mín/Máx)',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'qualitative',
                            child: Text(
                              'Cualitativo (Opciones Múltiples, Positivo/Negativo)',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'text',
                            child: Text('Texto Libre / Observaciones Clínicas'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            controller.setDataType(val);
                          }
                        },
                      ),
                    ),
                    if (controller.dataType == 'numeric') ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: controller.unitController,
                              decoration: InputDecoration(
                                labelText: 'Unidad de Medida *',
                                hintText: 'ej. mg/dL',
                                prefixIcon: const Icon(Icons.straighten, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (val) =>
                                  controller.dataType == 'numeric' &&
                                      (val == null || val.trim().isEmpty)
                                  ? 'Requerido'
                                  : null,
                              onChanged: (val) =>
                                  controller.updateUnitOfMeasureFromText(val),
                            ),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: LabTestFormViewController.commonUnits.map((u) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ActionChip(
                                      label: Text(
                                        u,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      onPressed: () => controller.setUnitOfMeasure(u),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                // Editor de Rangos Numéricos
                if (controller.dataType == 'numeric')
                  ReferenceValuesEditor(
                    values: controller.referenceValues,
                    onChanged: controller.setReferenceValues,
                    unitOfMeasure: controller.unitOfMeasure,
                    showTitle: false,
                  ),

                // Editor Cualitativo
                if (controller.dataType == 'qualitative' || controller.dataType == 'boolean') ...[
                  Text(
                    'Plantillas Rápidas Frecuentes:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: LabTestFormViewController.qualitativePresets.map((preset) {
                        final opts = preset['options'] as List<String>;
                        final exp = preset['expected'] as String;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            avatar: const Icon(Icons.flash_on, size: 14),
                            label: Text(
                              preset['label'] as String,
                              style: const TextStyle(fontSize: 11),
                            ),
                            onPressed: () {
                              controller.setQualitativePresets(opts, exp);
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: controller.qualitativeOptionsController,
                    decoration: InputDecoration(
                      labelText: 'Opciones de Resultado (separadas por coma) *',
                      hintText: 'ej. Negativo, Positivo',
                      prefixIcon: const Icon(Icons.list_alt, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (val) {
                      if (controller.dataType == 'qualitative' ||
                          controller.dataType == 'boolean') {
                        if (val == null ||
                            val.trim().isEmpty ||
                            controller.qualitativeOptions.isEmpty) {
                          return 'Debe ingresar al menos una opción';
                        }
                      }
                      return null;
                    },
                    onChanged: (val) => controller.updateQualitativeOptionsFromText(val),
                  ),
                  const SizedBox(height: 14),
                  if (controller.qualitativeOptions.isNotEmpty)
                    DropdownButtonFormField<String>(
                      key: ValueKey('expected_${controller.expectedQualitativeValue}'),
                      initialValue:
                          controller.qualitativeOptions.contains(
                            controller.expectedQualitativeValue,
                          )
                          ? controller.expectedQualitativeValue
                          : controller.qualitativeOptions.first,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Valor Normal / Esperado *',
                        helperText:
                            'Cualquier resultado distinto a este marcará alerta médica (ANORMAL)',
                        prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: controller.qualitativeOptions.toSet().map((opt) {
                        return DropdownMenuItem<String>(
                          value: opt,
                          child: Text(opt),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          controller.setExpectedQualitativeValue(val);
                        }
                      },
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Defina al menos una opción de resultado en el campo superior para seleccionar el valor normal esperado.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                // Texto / Escala de Referencia Explicativa
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.referenceTextController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Texto / Escala de Referencia Explicativa (Opcional)',
                    hintText:
                        'Ej. - Menor de 5.6%: Nivel no diabético\n- 5.7 - 6.4%: Nivel prediabético...',
                    helperText:
                        'Opcional. Permite mostrar escalas clínicas complejas o notas multilínea en órdenes e impresiones PDF.',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
