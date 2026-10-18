import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubits/app_session_cubit/app_session_cubit.dart';

class InactiveScreen extends StatelessWidget {
  const InactiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionCubit = context.watch<AppSessionCubit>();
    final servinName = sessionCubit.servin?.name ?? 'esta instancia';

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.block_rounded,
                        size: 56,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Terminal Bloqueada',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'El acceso a "$servinName" ha sido desactivado temporalmente o suspendido por el administrador del sistema.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Por favor contacte a soporte técnico para regularizar el estado de su licencia.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            context.read<AppSessionCubit>().initSession();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('¿Desvincular Terminal?'),
                                content: const Text(
                                  'Esta acción borrará la configuración del negocio de esta terminal y requerirá una nueva clave de activación.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: theme.colorScheme.error,
                                    ),
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('Desvincular'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && context.mounted) {
                              await context.read<AppSessionCubit>().exitBusiness();
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                          ),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Salir del Negocio'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
