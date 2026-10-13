import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/api_keys_cubit/api_keys_cubit.dart';
import '../../../cubits/api_keys_cubit/api_keys_state.dart';

class ApiKeysScreen extends StatelessWidget {
  const ApiKeysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryProvider.of<ApiKeysRepository>(context);

    return BlocProvider(
      create: (context) => ApiKeysCubit(repo)..loadApiKeys(),
      child: const _ApiKeysScaffold(),
    );
  }
}

class _ApiKeysScaffold extends StatelessWidget {
  const _ApiKeysScaffold();

  void _showCreateDialog(BuildContext context) {
    final cubit = context.read<ApiKeysCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => _CreateApiKeyDialog(
        onSave: (name, serviceType) async {
          final createdKey = await cubit.createApiKey(
            name: name,
            serviceType: serviceType,
          );
          if (createdKey != null && context.mounted) {
            _showCreatedTokenModal(context, createdKey);
          }
        },
      ),
    );
  }

  void _showCreatedTokenModal(BuildContext context, ApiKeyModel apiKey) {
    final tokenToDisplay = apiKey.rawKey ?? apiKey.key;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            const Text("Llave Creada Exitosamente"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Copia esta llave ahora. Por motivos de seguridad, no se volverá a mostrar completa:",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: SelectableText(
                tokenToDisplay,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text("Copiar Llave Serum"),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: tokenToDisplay));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("¡Llave copiada al portapapeles!"),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                // Back Button
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Volver a Administración',
                  onPressed: () => context.pop(),
                ),
                const SizedBox(width: 8),

                // Icon and Titles
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(80),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.key_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Llaves de API / Integraciones',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Control de credenciales criptográficas para conectar Power BI, sistemas externos y servicios autorizados',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Actions
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refrescar',
                  onPressed: () => context.read<ApiKeysCubit>().loadApiKeys(),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _showCreateDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nueva Llave'),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: BlocConsumer<ApiKeysCubit, ApiKeysState>(
              listener: (context, state) {
                if (state is ApiKeysError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ApiKeysLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ApiKeysLoaded) {
                  final keys = state.apiKeys;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _HeaderInfoCard(),
                        const SizedBox(height: 20),
                        if (keys.isEmpty)
                          Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 60),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.key_off_outlined,
                                    size: 56,
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No hay llaves de API creadas aún.\nPresiona "+ Nueva Llave" para generar una.',
                                    textAlign: TextAlign.center,
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: keys.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final keyItem = keys[index];
                              return _ApiKeyCard(apiKey: keyItem);
                            },
                          ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text("Nueva Llave"),
      ),
    );
  }
}

class _HeaderInfoCard extends StatelessWidget {
  const _HeaderInfoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(50),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(70),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.vpn_key_rounded,
              size: 26,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Integraciones y Cabecera X-API-KEY (srm_live_...)",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Permite que aplicaciones externas (Power BI, E-commerce, ERPs, LIS de terceros) consulten de forma segura el servidor enviando la cabecera 'X-API-KEY: srm_live_...' o 'Authorization: Api-Key srm_live_...'. El middleware unificado del servidor autenticará la petición de manera automática.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
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

class _ApiKeyCard extends StatelessWidget {
  final ApiKeyModel apiKey;

  const _ApiKeyCard({required this.apiKey});

  Color _getServiceBadgeColor(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'power_bi':
        return Colors.amber.shade800;
      case 'ecommerce':
        return Colors.blue.shade700;
      case 'accounting':
        return Colors.teal.shade700;
      case 'external_lis':
        return const Color(0xFF0F766E);
      default:
        return Colors.purple.shade700;
    }
  }

  String _formatServiceLabel(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'power_bi':
        return 'Power BI / Analítica';
      case 'ecommerce':
        return 'E-Commerce';
      case 'accounting':
        return 'Contabilidad / ERP';
      case 'external_lis':
        return 'LIS Externo';
      default:
        return 'Personalizado';
    }
  }

  String _formatDate(int timestamp) {
    if (timestamp <= 0) return 'Sin fecha';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final formatter = DateFormat('dd/MM/yyyy hh:mm a');
    return formatter.format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ApiKeysCubit>();
    final theme = Theme.of(context);
    final badgeColor = _getServiceBadgeColor(apiKey.serviceType);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: apiKey.isActive
              ? theme.colorScheme.outlineVariant.withAlpha(90)
              : theme.colorScheme.error.withAlpha(80),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: apiKey.isActive
                  ? Colors.green.withAlpha(30)
                  : Colors.grey.withAlpha(30),
              child: Icon(
                apiKey.isActive
                    ? Icons.check_circle_outline
                    : Icons.pause_circle_outline,
                color: apiKey.isActive ? Colors.green : Colors.grey,
              ),
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
                          apiKey.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: badgeColor.withAlpha(60)),
                        ),
                        child: Text(
                          _formatServiceLabel(apiKey.serviceType),
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withAlpha(80),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          apiKey.maskedKey,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: "Copiar llave enmascarada",
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: apiKey.key));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text("Llave enmascarada copiada al portapapeles"),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 16,
                    children: [
                      Text(
                        "Creada: ${_formatDate(apiKey.createdAt)}",
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        apiKey.lastUsedAt != null
                            ? "Último uso: ${_formatDate(apiKey.lastUsedAt!)}"
                            : "Último uso: Nunca",
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Text(
                  apiKey.isActive ? 'Activa' : 'Pausada',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: apiKey.isActive
                        ? Colors.green
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: apiKey.isActive,
                  onChanged: (val) {
                    cubit.toggleApiKeyStatus(apiKey.id, val);
                  },
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: theme.colorScheme.error,
              ),
              tooltip: "Revocar Llave",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Revocar Llave"),
                    content: Text(
                      "¿Seguro que deseas revocar y eliminar la llave '${apiKey.name}'? Cualquier sistema externo o tablero que use esta llave dejará de tener acceso inmediatamente.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text("Cancelar"),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          cubit.deleteApiKey(apiKey.id);
                        },
                        child: const Text("Revocar"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateApiKeyDialog extends StatefulWidget {
  final Function(String name, String serviceType) onSave;

  const _CreateApiKeyDialog({required this.onSave});

  @override
  State<_CreateApiKeyDialog> createState() => _CreateApiKeyDialogState();
}

class _CreateApiKeyDialogState extends State<_CreateApiKeyDialog> {
  final _nameController = TextEditingController();
  String _selectedServiceType = 'power_bi';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.vpn_key_rounded),
          SizedBox(width: 10),
          Text("Generar Llave de API"),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "Nombre de la Llave",
                  hintText: "Ej. Power BI - Tablero de Indicadores",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedServiceType,
                decoration: const InputDecoration(
                  labelText: "Tipo de Servicio / Integración",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'power_bi',
                    child: Text('Power BI / Analítica'),
                  ),
                  DropdownMenuItem(
                    value: 'ecommerce',
                    child: Text('E-Commerce / Tienda Web'),
                  ),
                  DropdownMenuItem(
                    value: 'accounting',
                    child: Text('Contabilidad / ERP'),
                  ),
                  DropdownMenuItem(
                    value: 'external_lis',
                    child: Text('LIS Externo / Sucursal'),
                  ),
                  DropdownMenuItem(
                    value: 'custom',
                    child: Text('Personalizado / Terceros'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedServiceType = val);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancelar"),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Ingresa un nombre descriptivo para la llave"),
                ),
              );
              return;
            }
            Navigator.of(context).pop();
            widget.onSave(name, _selectedServiceType);
          },
          child: const Text("Generar Llave"),
        ),
      ],
    );
  }
}
