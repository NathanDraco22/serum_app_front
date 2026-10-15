import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/app_assets.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionState = context.watch<AppSessionCubit>().state;
    final currentBranch = sessionState.currentBranch;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Visual Brand Element (IsoLogo -> Logotipo -> App Asset -> Icon)
              _buildBrandVisual(context, currentBranch),
              const SizedBox(height: 28),
              Text(
                currentBranch != null
                    ? 'Bienvenido a ${currentBranch.name}'
                    : 'Bienvenido a Serum LIS',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Text(
                  'Selecciona una sección en la barra lateral para comenzar a gestionar el laboratorio clínico.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (currentBranch != null &&
                  (currentBranch.address.isNotEmpty ||
                      currentBranch.phone.isNotEmpty ||
                      (currentBranch.email != null &&
                          currentBranch.email!.isNotEmpty))) ...[
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (currentBranch.address.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            currentBranch.address,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    if (currentBranch.phone.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_outlined,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            currentBranch.phone,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    if (currentBranch.email != null &&
                        currentBranch.email!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.email_outlined,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            currentBranch.email!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandVisual(BuildContext context, dynamic currentBranch) {
    // 1. IsoLogo remoto de la sucursal activa
    final isoLogoUrl = currentBranch?.isoLogoUrl as String?;
    if (isoLogoUrl != null && isoLogoUrl.isNotEmpty) {
      return Image.network(
        isoLogoUrl,
        height: 110,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _buildLogoFallback(context, currentBranch),
      );
    }

    // 2. Si no hay IsoLogo remoto, intentar Logotipo remoto de la sucursal activa
    return _buildLogoFallback(context, currentBranch);
  }

  Widget _buildLogoFallback(BuildContext context, dynamic currentBranch) {
    final logoUrl = (currentBranch?.effectiveLogo as String?);
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return Image.network(
        logoUrl,
        height: 90,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _buildAssetFallback(context),
      );
    }

    // 3. Fallback a los Assets locales de la aplicación
    return _buildAssetFallback(context);
  }

  Widget _buildAssetFallback(BuildContext context) {
    final theme = Theme.of(context);

    // Intentar cargar el IsoLogo local empaquetado con el proyecto
    return Image.asset(
      AppAssets.serumIsoLogo,
      height: 100,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Si no está disponible, intentar el Logotipo local
        return Image.asset(
          AppAssets.serumLogo,
          height: 80,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // 4. Respaldo final a icono Biotech
            return Icon(
              Icons.biotech,
              size: 80,
              color: theme.colorScheme.primary,
            );
          },
        );
      },
    );
  }
}
