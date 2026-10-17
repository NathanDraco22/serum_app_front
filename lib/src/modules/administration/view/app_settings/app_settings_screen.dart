import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../cubits/app_settings/app_settings_cubit.dart';
import '../../../../cubits/app_settings/app_settings_state.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _initialized = false;
  bool _useCost = false;
  bool _usePrice2 = false;
  bool _allowEditPrice = false;

  void _syncWithSettings(AppSettingModel settings) {
    if (!_initialized) {
      _useCost = settings.useCost;
      _usePrice2 = settings.usePrice2;
      _allowEditPrice = settings.allowEditPrice;
      _initialized = true;
    }
  }

  Future<void> _saveSettings() async {
    final cubit = context.read<AppSettingsCubit>();
    final update = UpdateAppSetting(
      useCost: _useCost,
      usePrice2: _usePrice2,
      allowEditPrice: _allowEditPrice,
    );

    final success = await cubit.updateSettings(update);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada exitosamente'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final state = cubit.state;
      final msg = state is AppSettingsError
          ? state.message
          : 'Error al actualizar la configuración';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocConsumer<AppSettingsCubit, AppSettingsState>(
        listener: (context, state) {
          if (state is AppSettingsLoaded) {
            _syncWithSettings(state.settings);
          }
        },
        builder: (context, state) {
          final cubit = context.read<AppSettingsCubit>();
          final current = cubit.currentSettings;

          if (current != null && !_initialized) {
            _syncWithSettings(current);
          }

          final isLoading = state is AppSettingsLoading && current == null;
          final isSaving = state is AppSettingsSaving;

          return Column(
            children: [
              // Header Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outlineVariant.withAlpha(120),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Volver a Administración',
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withAlpha(80),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configuración del Sistema',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Parámetros comerciales y reglas operativas de mostrador',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: isSaving ? null : _saveSettings,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 20),
                      label: Text(isSaving ? 'Guardando...' : 'Guardar Cambios'),
                    ),
                  ],
                ),
              ),

              // Content Body
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 850),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Parámetros Comerciales y Catálogo',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Configura el comportamiento de costos, listas de precios y permisos de edición para la toma de órdenes y cotizaciones.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Card Container
                                Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: theme.colorScheme.outlineVariant
                                          .withAlpha(120),
                                    ),
                                  ),
                                  color: theme.colorScheme.surface,
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    children: [
                                      // 1. Usar Costo
                                      _SettingSwitchTile(
                                        title: 'Usar Costo',
                                        subtitle:
                                            'Permite registrar, visualizar y calcular el costo de reactivos e insumos en el catálogo de análisis clínicos (LabTests).',
                                        icon: Icons.attach_money_rounded,
                                        value: _useCost,
                                        onChanged: (val) {
                                          setState(() => _useCost = val);
                                        },
                                      ),
                                      const Divider(height: 1),

                                      // 2. Usar Precio 2
                                      _SettingSwitchTile(
                                        title: 'Usar Precio 2',
                                        subtitle:
                                            'Habilita la lista secundaria de precios (Precio 2) en el catálogo de pruebas, cotizaciones y órdenes médicas para convenios o médicos referentes.',
                                        icon: Icons.price_change_outlined,
                                        value: _usePrice2,
                                        onChanged: (val) {
                                          setState(() => _usePrice2 = val);
                                        },
                                      ),
                                      const Divider(height: 1),

                                      // 3. Permitir Editar Precios
                                      _SettingSwitchTile(
                                        title: 'Permitir Editar Precios',
                                        subtitle:
                                            'Autoriza al personal operativo en caja y recepción a modificar manualmente el precio pactado al elaborar órdenes o cotizaciones en mostrador.',
                                        icon: Icons.edit_note_rounded,
                                        value: _allowEditPrice,
                                        onChanged: (val) {
                                          setState(() => _allowEditPrice = val);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: value
                    ? theme.colorScheme.primaryContainer.withAlpha(120)
                    : theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: value
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
