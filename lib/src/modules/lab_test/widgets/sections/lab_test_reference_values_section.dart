import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import '../../controllers/lab_test_form_mediator.dart';
import '../../controllers/lab_test_form_view_controller.dart';

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
                              onChanged: (val) => controller.setUnitOfMeasure(val),
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
                if (controller.dataType == 'numeric') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tabla de Rangos de Referencia:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => controller.addReferenceValue(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Agregar Rango'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (controller.referenceValues.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Haga clic en "+ Agregar Rango" para definir los límites de normalidad.',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.referenceValues.length,
                      itemBuilder: (context, index) {
                        final ref = controller.referenceValues[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  initialValue: LabTestFormViewController.normalizeGender(ref.gender),
                                  isDense: true,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Género',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'both',
                                      child: Text('Ambos'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'male',
                                      child: Text('Masculino'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'female',
                                      child: Text('Femenino'),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    controller.updateReferenceValue(
                                      index,
                                      ReferenceValue(
                                        patientType: ref.patientType,
                                        gender: val ?? 'both',
                                        minAgeDays: ref.minAgeDays,
                                        maxAgeDays: ref.maxAgeDays,
                                        minValue: ref.minValue,
                                        maxValue: ref.maxValue,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: ref.minValue.toString(),
                                  decoration: const InputDecoration(
                                    labelText: 'Mínimo',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    final parsed = double.tryParse(val) ?? 0.0;
                                    controller.updateReferenceValue(
                                      index,
                                      ReferenceValue(
                                        patientType: ref.patientType,
                                        gender: ref.gender,
                                        minAgeDays: ref.minAgeDays,
                                        maxAgeDays: ref.maxAgeDays,
                                        minValue: parsed,
                                        maxValue: ref.maxValue,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: ref.maxValue.toString(),
                                  decoration: const InputDecoration(
                                    labelText: 'Máximo',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    final parsed = double.tryParse(val) ?? 0.0;
                                    controller.updateReferenceValue(
                                      index,
                                      ReferenceValue(
                                        patientType: ref.patientType,
                                        gender: ref.gender,
                                        minAgeDays: ref.minAgeDays,
                                        maxAgeDays: ref.maxAgeDays,
                                        minValue: ref.minValue,
                                        maxValue: parsed,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => controller.removeReferenceValueAt(index),
                                color: theme.colorScheme.error,
                                tooltip: 'Eliminar rango',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],

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
                          controller.qualitativeOptions.contains(controller.expectedQualitativeValue)
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
