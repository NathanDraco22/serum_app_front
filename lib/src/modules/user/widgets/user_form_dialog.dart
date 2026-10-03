import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/branch_cubit/read_branches_cubit.dart';
import '../../../cubits/user_cubit/write_users_cubit.dart';

class UserFormDialog extends StatefulWidget {
  const UserFormDialog({super.key, this.user});

  final UserInDb? user;

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  late String _selectedRole;
  late bool _isActive;
  late List<String> _selectedBranches;

  bool _obscurePassword = true;
  bool _isSaving = false;

  bool get _isEditing => widget.user != null;

  static const _availableRoles = [
    {'value': 'Admin', 'label': 'Administrador (Acceso total)'},
    {'value': 'Cashier', 'label': 'Cajero (Módulo POS y caja)'},
    {'value': 'Bioanalyst', 'label': 'Bioanalista (Resultados de lab)'},
    {'value': 'Doctor', 'label': 'Médico (Consultas y órdenes)'},
  ];

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameController = TextEditingController(text: u?.name ?? '');
    _usernameController = TextEditingController(text: u?.username ?? '');
    _passwordController = TextEditingController();
    _emailController = TextEditingController(text: u?.email ?? '');
    _phoneController = TextEditingController(text: u?.phone ?? '');

    // Normalizar rol
    final currentRole = u?.role ?? 'Cashier';
    _selectedRole = _availableRoles.any(
            (r) => r['value']!.toLowerCase() == currentRole.toLowerCase())
        ? _availableRoles.firstWhere((r) =>
            r['value']!.toLowerCase() == currentRole.toLowerCase())['value']!
        : 'Cashier';

    _isActive = u?.isActive ?? true;
    _selectedBranches = List<String>.from(u?.branches ?? []);

    // Cargar sucursales si no están cargadas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReadBranchCubit>().getAll();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBranches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes asignar al menos una sucursal al usuario.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final writeCubit = context.read<WriteUserCubit>();

    try {
      if (_isEditing) {
        await writeCubit.update(
          widget.user!.id,
          UpdateUser(
            name: _nameController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text.isNotEmpty
                ? _passwordController.text
                : null,
            email: _emailController.text.trim().isNotEmpty
                ? _emailController.text.trim()
                : null,
            phone: _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
            role: _selectedRole,
            branches: _selectedBranches,
            isActive: _isActive,
          ),
        );
      } else {
        await writeCubit.create(
          CreateUser(
            name: _nameController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            email: _emailController.text.trim().isNotEmpty
                ? _emailController.text.trim()
                : null,
            phone: _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
            role: _selectedRole,
            branches: _selectedBranches,
            isActive: _isActive,
          ),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.secondaryContainer.withAlpha(90),
                        foregroundColor: theme.colorScheme.secondary,
                        child: Icon(
                          _isEditing
                              ? Icons.manage_accounts_rounded
                              : Icons.person_add_alt_1_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing
                                  ? 'Editar Usuario'
                                  : 'Nuevo Usuario del Sistema',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _isEditing
                                  ? 'Modifica los accesos, roles y datos del colaborador'
                                  : 'Ingresa las credenciales y accesos para el nuevo colaborador',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // Fila 1: Nombre y Username
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre Completo *',
                            hintText: 'Ej. Juan Pérez González',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Campo obligatorio'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de Usuario *',
                            hintText: 'Ej. jperez',
                            prefixIcon: Icon(Icons.alternate_email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Campo obligatorio'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Fila 2: Contraseña y Rol
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: _isEditing
                                ? 'Nueva Contraseña (Opcional)'
                                : 'Contraseña *',
                            hintText: _isEditing
                                ? 'Dejar en blanco para conservar'
                                : 'Mínimo 6 caracteres',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (!_isEditing &&
                                (val == null || val.trim().isEmpty)) {
                              return 'Contraseña requerida';
                            }
                            if (val != null &&
                                val.isNotEmpty &&
                                val.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Rol Operativo *',
                            prefixIcon: Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: _availableRoles.map((role) {
                            return DropdownMenuItem<String>(
                              value: role['value'],
                              child: Text(role['label']!),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedRole = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Fila 3: Email y Teléfono
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo Electrónico (Opcional)',
                            hintText: 'juan@laboratorio.com',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono Móvil (Opcional)',
                            hintText: 'Ej. 555-987-6543',
                            prefixIcon: Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Switch Estado Activo
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(80),
                      ),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Usuario Activo',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        _isActive
                            ? 'El usuario puede iniciar sesión y operar en el sistema'
                            : 'Usuario deshabilitado; se bloqueará el acceso al sistema',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: _isActive,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Selección de Sucursales
                  Text(
                    'Sucursales Autorizadas *',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selecciona las sedes en las que este usuario tiene autorización para laborar:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),

                  BlocBuilder<ReadBranchCubit, ReadBranchState>(
                    builder: (context, branchState) {
                      if (branchState is ReadBranchLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      } else if (branchState is ReadBranchSuccess) {
                        final branches = branchState.items;
                        if (branches.isEmpty) {
                          return const Text(
                            'No hay sucursales registradas en el sistema.',
                            style: TextStyle(color: Colors.orange),
                          );
                        }

                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: branches.map((b) {
                            final isSelected =
                                _selectedBranches.contains(b.id);
                            return FilterChip(
                              avatar: Icon(
                                isSelected
                                    ? Icons.check
                                    : Icons.storefront_outlined,
                                size: 16,
                              ),
                              label: Text(b.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedBranches.add(b.id);
                                  } else {
                                    _selectedBranches.remove(b.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 28),

                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _submit,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(_isSaving
                            ? 'Guardando...'
                            : (_isEditing
                                ? 'Guardar Cambios'
                                : 'Crear Usuario')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
