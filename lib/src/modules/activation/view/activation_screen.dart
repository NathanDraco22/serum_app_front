import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/app_assets.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../cubit/activation_cubit.dart';

class ActivationScreen extends StatelessWidget {
  const ActivationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final servinRepo = context.read<ServinRepository>();
    return BlocProvider(
      create: (context) => ActivationCubit(servinRepo),
      child: const _RootScaffold(),
    );
  }
}

class _RootScaffold extends StatelessWidget {
  const _RootScaffold();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<ActivationCubit, ActivationState>(
      listener: (context, state) async {
        if (state is ActivationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        if (state is ActivationSuccess) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              icon: Icon(
                Icons.check_circle_outline,
                color: theme.colorScheme.primary,
                size: 48,
              ),
              title: const Text('Terminal Activada'),
              content: Text(
                'Bienvenido a:\n${state.servin.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Continuar al Login'),
                ),
              ],
            ),
          );

          if (!context.mounted) return;
          context.read<AppSessionCubit>().initServinUnauthenticated(state.servin);
        }
      },
      child: const Scaffold(
        body: _Body(),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _serverUrlController = TextEditingController();
  bool _obscureApiKey = true;
  bool _showAdvancedServer = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _apiKeyController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final serverUrl = _serverUrlController.text.trim();
    context.read<ActivationCubit>().activate(
          _apiKeyController.text,
          _nicknameController.text,
          originServerUrl: serverUrl.isNotEmpty ? serverUrl : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.colorScheme.surfaceContainerLow,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Image.asset(
                          AppAssets.serumLogo,
                          height: 72,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => CircleAvatar(
                            radius: 36,
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            child: const Icon(Icons.biotech, size: 40),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Activación de Terminal',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ingresa las credenciales del laboratorio para enlazar esta estación de trabajo.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Campo Alias de Negocio
                      TextFormField(
                        controller: _nicknameController,
                        decoration: const InputDecoration(
                          labelText: 'Alias del Negocio',
                          hintText: 'ej. bio-analisis-centro',
                          prefixIcon: Icon(Icons.business_outlined),
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa el alias del negocio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Campo API Key / Código de Activación
                      TextFormField(
                        controller: _apiKeyController,
                        obscureText: _obscureApiKey,
                        decoration: InputDecoration(
                          labelText: 'API Key / Código de Activación',
                          hintText: 'Clave provista por el administrador',
                          prefixIcon: const Icon(Icons.vpn_key_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureApiKey
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureApiKey = !_obscureApiKey;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa la clave de activación';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Configuración opcional de servidor
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showAdvancedServer = !_showAdvancedServer;
                            });
                          },
                          icon: Icon(
                            _showAdvancedServer
                                ? Icons.keyboard_arrow_up
                                : Icons.tune_rounded,
                            size: 16,
                          ),
                          label: Text(
                            _showAdvancedServer
                                ? 'Ocultar servidor'
                                : 'Ajustes de servidor (opcional)',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      if (_showAdvancedServer) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _serverUrlController,
                          decoration: const InputDecoration(
                            labelText: 'URL del Servidor de Activación',
                            hintText: 'ej. http://localhost:8000',
                            prefixIcon: Icon(Icons.dns_outlined),
                            border: OutlineInputBorder(),
                            helperText:
                                'Opcional. Por defecto usa la URL del cliente',
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Botón Activar
                      BlocBuilder<ActivationCubit, ActivationState>(
                        builder: (context, state) {
                          final isLoading = state is ActivationLoading;
                          return ElevatedButton.icon(
                            onPressed: isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.lock_open_rounded),
                            label: Text(
                              isLoading ? 'Conectando...' : 'Activar Terminal',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
