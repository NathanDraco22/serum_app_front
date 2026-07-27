import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/cash_register_cubit/read_cash_registers_cubit.dart';

class SelectCashRegisterScreen extends StatelessWidget {
  const SelectCashRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReadCashRegisterCubit>(
      create: (context) => ReadCashRegisterCubit(
        cashRegistersRepository:
            RepositoryProvider.of<CashRegistersRepository>(context),
      )..getAll(),
      child: const _RootScaffold(),
    );
  }
}

class _RootScaffold extends StatelessWidget {
  const _RootScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AppSessionCubit>().state.currentUser;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.colorScheme.surfaceContainerLow,
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    child: const Icon(Icons.biotech),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Serum LIS',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Bienvenido, ${user?.name ?? user?.username ?? "Usuario"}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<AppSessionCubit>().logout();
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Cerrar Sesión'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content Area
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.point_of_sale,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Selecciona una Caja Registradora',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Elige la caja operativa para procesar cobros y transacciones en el turno activo.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // List of Cash Registers
                        BlocBuilder<ReadCashRegisterCubit, ReadCashRegisterState>(
                          builder: (context, state) {
                            if (state is ReadCashRegisterLoading ||
                                state is ReadCashRegisterInitial) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            if (state is ReadCashRegisterError) {
                              return _buildFallbackCard(
                                context,
                                'Error al cargar cajas: ${state.message}',
                              );
                            }

                            final items =
                                state is ReadCashRegisterSuccess ? state.items : <CashRegisterInDb>[];

                            if (items.isEmpty) {
                              return _buildDefaultDemoOption(context);
                            }

                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              children: items.map((register) {
                                return _CashRegisterCard(register: register);
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultDemoOption(BuildContext context) {
    final defaultRegister = CashRegisterInDb(
      id: 'cr_001',
      name: 'Caja Principal #001',
      branchId: 'br_centro_001',
      isOpen: true,
      totalBalance: 5000,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    return Column(
      children: [
        Text(
          'No se encontraron cajas registradas. Puedes seleccionar la caja por defecto:',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        _CashRegisterCard(register: defaultRegister),
      ],
    );
  }

  Widget _buildFallbackCard(BuildContext context, String error) {
    return Column(
      children: [
        Text(error, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 16),
        _buildDefaultDemoOption(context),
      ],
    );
  }
}

class _CashRegisterCard extends StatelessWidget {
  final CashRegisterInDb register;

  const _CashRegisterCard({required this.register});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOpen = register.isOpen;

    return SizedBox(
      width: 240,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isOpen ? theme.colorScheme.primaryContainer : theme.colorScheme.outlineVariant,
            width: isOpen ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            context.read<AppSessionCubit>().selectCashRegister(register);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor: isOpen
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHigh,
                  foregroundColor: isOpen
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                  child: const Icon(Icons.point_of_sale),
                ),
                const SizedBox(height: 12),
                Text(
                  register.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Chip(
                  label: Text(
                    isOpen ? 'Abierta' : 'Cerrada',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOpen
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  backgroundColor: isOpen
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(height: 12),
                Text(
                  'Saldo: \$${register.totalBalance.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<AppSessionCubit>().selectCashRegister(register);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(36),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: const Text('Operar Caja'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
