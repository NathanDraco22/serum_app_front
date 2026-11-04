import 'package:flutter/material.dart';

import '../../controllers/branch_form_mediator.dart';

/// Subsección para la captura de datos generales de la sucursal:
/// Nombre comercial, dirección completa, teléfono de contacto, email y Facebook.
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
      ],
    );
  }
}
