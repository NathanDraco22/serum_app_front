import 'package:flutter/material.dart';

import '../../controllers/branch_form_mediator.dart';

/// Subsección para la captura de datos generales de la sucursal:
/// Nombre comercial, dirección completa, teléfono de contacto, email, Facebook
/// y preferencias de cálculo automático de fórmulas clínicas.
class BranchGeneralInfoSection extends StatelessWidget {
  const BranchGeneralInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = BranchFormMediator.controllerOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información General',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),

        // Nombre de la sucursal
        TextFormField(
          controller: controller.nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre de la Sucursal *',
            hintText: 'Ej. Sucursal Matriz, Centro, Norte...',
            prefixIcon: Icon(Icons.storefront_rounded),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingresa el nombre de la sucursal';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Dirección completa
        TextFormField(
          controller: controller.addressController,
          decoration: const InputDecoration(
            labelText: 'Dirección Completa *',
            hintText: 'Calle, número, colonia, ciudad...',
            prefixIcon: Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingresa la dirección de la sede';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Teléfono
        TextFormField(
          controller: controller.phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Teléfono de Contacto *',
            hintText: 'Ej. 555-123-4567',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingresa un teléfono de contacto';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Correo Electrónico
        TextFormField(
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo Electrónico (Email)',
            hintText: 'Ej. contacto@laboratorio.com',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Facebook
        TextFormField(
          controller: controller.facebookController,
          decoration: const InputDecoration(
            labelText: 'Página de Facebook',
            hintText: 'Ej. facebook.com/laboratorioclinico o @laboratorio',
            prefixIcon: Icon(Icons.facebook_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Preferencia clínica: Fórmulas automáticas
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return Material(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withAlpha(120),
                ),
              ),
              child: SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                secondary: Icon(
                  Icons.calculate_outlined,
                  color: controller.autoCalculateFormulas
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                title: const Text(
                  'Cálculo automático de fórmulas clínicas',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                subtitle: Text(
                  'Autocalcular en vivo serie roja (HTC ↔ HB), índices de Wintrobe, lípidos y BUN. Si se desactiva, los campos se capturan manualmente para transcribir equipos analizadores.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: controller.autoCalculateFormulas,
                onChanged: controller.isSaving
                    ? null
                    : controller.setAutoCalculateFormulas,
              ),
            );
          },
        ),
      ],
    );
  }
}
