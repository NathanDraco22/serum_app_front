import 'package:flutter/material.dart';
import '../../controllers/lab_test_form_mediator.dart';
import '../clinical_classification_registry.dart';

class LabTestGeneralInfoSection extends StatelessWidget {
  const LabTestGeneralInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = LabTestFormMediator.controllerOf(context);
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final availableCategories = ClinicalClassificationRegistry.classifications;
        if (controller.rawCommercialCategory.isNotEmpty &&
            !controller.isCustomCategory &&
            !availableCategories.contains(controller.rawCommercialCategory)) {
          availableCategories.add(controller.rawCommercialCategory);
          availableCategories.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        }

        final currentCatForSubs = controller.isCustomCategory
            ? controller.customCategoryController.text
            : controller.rawCommercialCategory;
        final availableSubs = ClinicalClassificationRegistry.getSubclassificationsFor(
          currentCatForSubs,
        );
        if (controller.rawSubclassification.isNotEmpty &&
            !controller.isCustomSubclass &&
            !availableSubs.contains(controller.rawSubclassification)) {
          availableSubs.add(controller.rawSubclassification);
          availableSubs.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TARJETA 1: MODALIDAD DE ANÁLISIS
            Card(
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
                          controller.isPack ? Icons.inventory_2_outlined : Icons.science_outlined,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Modalidad de Análisis',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Indique si desea registrar una prueba de laboratorio individual o un paquete comercial integrado por múltiples análisis.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<bool>(
                      initialValue: controller.isPack,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Tipo de Análisis *',
                        prefixIcon: Icon(
                          controller.isPack ? Icons.inventory_2 : Icons.science,
                          color: theme.colorScheme.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem<bool>(
                          value: false,
                          child: Text('Análisis Clínico Individual (Prueba Única)'),
                        ),
                        DropdownMenuItem<bool>(
                          value: true,
                          child: Text('Pack / Perfil Compuesto (Agrupación de análisis)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          controller.setIsPack(val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // TARJETA 2: INFORMACIÓN GENERAL
            Card(
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
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Información General',
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
                          flex: 3,
                          child: TextFormField(
                            controller: controller.nameController,
                            decoration: InputDecoration(
                              labelText: controller.isPack
                                  ? 'Nombre del Pack / Perfil *'
                                  : 'Nombre del Análisis *',
                              hintText: controller.isPack
                                  ? 'ej. Perfil Lipídico Completo'
                                  : 'ej. Glucosa Sérica',
                              prefixIcon: const Icon(
                                Icons.drive_file_rename_outline,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'El nombre es obligatorio'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: controller.codeController,
                            decoration: InputDecoration(
                              labelText: 'Código / Clave',
                              hintText: 'ej. GLU-01',
                              prefixIcon: const Icon(Icons.tag, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // FILA 2: CLASIFICACIÓN GENERAL Y SUBCLASIFICACIÓN
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(
                              'form_cat_${controller.isCustomCategory ? "__custom__" : controller.rawCommercialCategory}',
                            ),
                            initialValue: controller.isCustomCategory
                                ? '__custom__'
                                : controller.rawCommercialCategory,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Clasificación General *',
                              prefixIcon: const Icon(Icons.category_outlined, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: [
                              ...availableCategories.map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                              const DropdownMenuItem(
                                value: '__custom__',
                                child: Text('+ Otra clasificación...'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                controller.setCommercialCategory(val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(
                              'form_sub_${controller.rawCommercialCategory}_${controller.isCustomSubclass ? "__custom__" : controller.rawSubclassification}',
                            ),
                            initialValue: controller.isCustomSubclass
                                ? '__custom__'
                                : controller.rawSubclassification,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Subclasificación *',
                              prefixIcon: const Icon(Icons.account_tree_outlined, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: [
                              ...availableSubs.map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                              const DropdownMenuItem(
                                value: '__custom__',
                                child: Text('+ Otra subclasificación...'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                controller.setSubclassification(val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    if (controller.isCustomCategory || controller.isCustomSubclass) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (controller.isCustomCategory)
                            Expanded(
                              child: TextFormField(
                                controller: controller.customCategoryController,
                                decoration: InputDecoration(
                                  labelText: 'Especifica la Clasificación Personalizada *',
                                  hintText: 'Ej. Biología Molecular...',
                                  prefixIcon: const Icon(Icons.edit_note, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                validator: (v) {
                                  if (controller.isCustomCategory &&
                                      (v == null || v.trim().isEmpty)) {
                                    return 'Ingresa la clasificación';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          if (controller.isCustomCategory && controller.isCustomSubclass)
                            const SizedBox(width: 12),
                          if (controller.isCustomSubclass)
                            Expanded(
                              child: TextFormField(
                                controller: controller.customSubclassController,
                                decoration: InputDecoration(
                                  labelText: 'Especifica la Subclasificación Personalizada *',
                                  hintText: 'Ej. Serie Plaquetaria, Físico-Químico...',
                                  prefixIcon: const Icon(Icons.edit_note, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                validator: (v) {
                                  if (controller.isCustomSubclass &&
                                      (v == null || v.trim().isEmpty)) {
                                    return 'Ingresa la subclasificación';
                                  }
                                  return null;
                                },
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
