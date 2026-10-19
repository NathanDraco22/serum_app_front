import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:serum_business/serum_business.dart';

/// Modelo adaptador para unificar la representación de datos del paciente en el diálogo.
class PatientDisplayData {
  final String name;
  final String? phone;
  final String? email;
  final String? cardId;
  final int? dateOfBirth;
  final String? gender;
  final String? address;

  const PatientDisplayData({
    required this.name,
    this.phone,
    this.email,
    this.cardId,
    this.dateOfBirth,
    this.gender,
    this.address,
  });

  factory PatientDisplayData.fromPatientInfo(PatientInfo info) {
    return PatientDisplayData(
      name: info.name,
      phone: info.phone.isNotEmpty ? info.phone : null,
      email: info.email != null && info.email!.isNotEmpty ? info.email : null,
      cardId: info.cardId != null && info.cardId!.isNotEmpty ? info.cardId : null,
      dateOfBirth: info.dateOfBirth > 0 ? info.dateOfBirth : null,
      gender: info.gender,
      address: info.address.isNotEmpty ? info.address : null,
    );
  }

  factory PatientDisplayData.fromPatientInDb(PatientInDb patient) {
    return PatientDisplayData(
      name: patient.name,
      phone: patient.phone.isNotEmpty ? patient.phone : null,
      email: patient.email != null && patient.email!.isNotEmpty ? patient.email : null,
      cardId: patient.cardId != null && patient.cardId!.isNotEmpty ? patient.cardId : null,
      dateOfBirth: patient.dateOfBirth > 0 ? patient.dateOfBirth : null,
      gender: patient.gender,
      address: patient.address != null && patient.address!.isNotEmpty ? patient.address : null,
    );
  }

  factory PatientDisplayData.fromOrder(OrderInDb order, [PatientInDb? fallbackPatient]) {
    if (order.patientInfo != null) {
      final info = order.patientInfo!;
      return PatientDisplayData(
        name: info.name.isNotEmpty
            ? info.name
            : (fallbackPatient?.name ?? 'Paciente'),
        phone: info.phone.isNotEmpty
            ? info.phone
            : (fallbackPatient?.phone.isNotEmpty == true ? fallbackPatient!.phone : null),
        email: info.email != null && info.email!.isNotEmpty
            ? info.email
            : (fallbackPatient?.email != null && fallbackPatient!.email!.isNotEmpty ? fallbackPatient.email : null),
        cardId: info.cardId != null && info.cardId!.isNotEmpty
            ? info.cardId
            : fallbackPatient?.cardId,
        dateOfBirth: info.dateOfBirth > 0
            ? info.dateOfBirth
            : fallbackPatient?.dateOfBirth,
        gender: info.gender.isNotEmpty
            ? info.gender
            : fallbackPatient?.gender,
        address: info.address.isNotEmpty
            ? info.address
            : fallbackPatient?.address,
      );
    }

    if (fallbackPatient != null) {
      return PatientDisplayData.fromPatientInDb(fallbackPatient);
    }

    return const PatientDisplayData(name: 'Paciente no identificado');
  }
}

/// Muestra el diálogo con la información del paciente y botones de copiado.
Future<void> showPatientInfoDialog(
  BuildContext context, {
  required PatientDisplayData patient,
  String? orderShortId,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => PatientInfoDialog(
      patient: patient,
      orderShortId: orderShortId,
    ),
  );
}

/// Helper para mostrar la información del paciente a partir de una orden.
Future<void> showOrderPatientInfoDialog(
  BuildContext context,
  OrderInDb order, [
  List<PatientInDb>? fallbackPatients,
]) async {
  PatientInDb? fallback;
  if (fallbackPatients != null && fallbackPatients.isNotEmpty) {
    try {
      fallback = fallbackPatients.firstWhere((p) => p.id == order.patientId);
    } catch (_) {
      fallback = null;
    }
  }

  final displayData = PatientDisplayData.fromOrder(order, fallback);
  final shortId = order.id.length > 6 ? order.id.substring(order.id.length - 6) : order.id;

  await showPatientInfoDialog(
    context,
    patient: displayData,
    orderShortId: shortId,
  );
}

/// Diálogo modal estilizado para visualizar la información del paciente con acciones de copiado rápido.
class PatientInfoDialog extends StatefulWidget {
  final PatientDisplayData patient;
  final String? orderShortId;

  const PatientInfoDialog({
    super.key,
    required this.patient,
    this.orderShortId,
  });

  @override
  State<PatientInfoDialog> createState() => _PatientInfoDialogState();
}

class _PatientInfoDialogState extends State<PatientInfoDialog> {
  String? _recentlyCopiedKey;

  void _copyToClipboard(String key, String text, String label) {
    if (text.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: text.trim()));

    setState(() {
      _recentlyCopiedKey = key;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('$label copiado al portapapeles: "$text"')),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _recentlyCopiedKey == key) {
        setState(() {
          _recentlyCopiedKey = null;
        });
      }
    });
  }

  int _calculateAge(int? birthDateMs) {
    if (birthDateMs == null || birthDateMs <= 0) return 0;
    final birthDate = DateTime.fromMillisecondsSinceEpoch(birthDateMs);
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age >= 0 ? age : 0;
  }

  String _formatBirthDate(int? timestamp) {
    if (timestamp == null || timestamp <= 0) return 'No registrada';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatGender(String? gender) {
    if (gender == null || gender.isEmpty) return 'No especificado';
    final normalized = gender.toLowerCase();
    if (normalized == 'm' || normalized == 'male' || normalized == 'masculino') {
      return 'Masculino';
    }
    if (normalized == 'f' || normalized == 'female' || normalized == 'femenino') {
      return 'Femenino';
    }
    return gender;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final patient = widget.patient;

    final age = _calculateAge(patient.dateOfBirth);
    final birthDateStr = _formatBirthDate(patient.dateOfBirth);
    final genderStr = _formatGender(patient.gender);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: const Icon(Icons.person_outline, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información del Paciente',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.orderShortId != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Orden #${widget.orderShortId}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Contenido estructurado
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre Completo (con botón de copia)
                    _buildCopyableFieldCard(
                      context: context,
                      fieldKey: 'name',
                      icon: Icons.person,
                      label: 'Nombre Completo',
                      value: patient.name,
                      allowCopy: patient.name.trim().isNotEmpty,
                      isHighlighted: true,
                    ),
                    const SizedBox(height: 12),

                    // Fila de Teléfono y Correo Electrónico
                    _buildCopyableFieldCard(
                      context: context,
                      fieldKey: 'phone',
                      icon: Icons.phone_outlined,
                      label: 'Teléfono',
                      value: patient.phone ?? 'No registrado',
                      allowCopy: patient.phone != null && patient.phone!.trim().isNotEmpty,
                    ),
                    const SizedBox(height: 12),

                    _buildCopyableFieldCard(
                      context: context,
                      fieldKey: 'email',
                      icon: Icons.email_outlined,
                      label: 'Correo Electrónico',
                      value: patient.email ?? 'No registrado',
                      allowCopy: patient.email != null && patient.email!.trim().isNotEmpty,
                    ),
                    const SizedBox(height: 12),

                    // Cédula / Documento de Identidad (con botón de copia)
                    if (patient.cardId != null && patient.cardId!.isNotEmpty) ...[
                      _buildCopyableFieldCard(
                        context: context,
                        fieldKey: 'cardId',
                        icon: Icons.badge_outlined,
                        label: 'Cédula / Documento de Identidad',
                        value: patient.cardId!,
                        allowCopy: true,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Datos Médicos / Demográficos
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.medical_information_outlined,
                                  size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'DATOS DEMOGRÁFICOS',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  context: context,
                                  icon: Icons.cake_outlined,
                                  label: 'Edad / Nacimiento',
                                  value: age > 0 ? '$age años ($birthDateStr)' : birthDateStr,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoItem(
                                  context: context,
                                  icon: Icons.wc_outlined,
                                  label: 'Género',
                                  value: genderStr,
                                ),
                              ),
                            ],
                          ),
                          if (patient.address != null && patient.address!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildInfoItem(
                              context: context,
                              icon: Icons.location_on_outlined,
                              label: 'Dirección',
                              value: patient.address!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer con botón Cerrar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyableFieldCard({
    required BuildContext context,
    required String fieldKey,
    required IconData icon,
    required String label,
    required String value,
    required bool allowCopy,
    bool isHighlighted = false,
  }) {
    final theme = Theme.of(context);
    final isCopied = _recentlyCopiedKey == fieldKey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isHighlighted
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isHighlighted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                    color: allowCopy
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          if (allowCopy) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: isCopied
                    ? const Icon(
                        Icons.check,
                        key: ValueKey('check'),
                        size: 20,
                        color: Colors.green,
                      )
                    : Icon(
                        Icons.content_copy_outlined,
                        key: const ValueKey('copy'),
                        size: 19,
                        color: theme.colorScheme.primary,
                      ),
              ),
              tooltip: isCopied ? '¡Copiado!' : 'Copiar $label',
              onPressed: () => _copyToClipboard(fieldKey, value, label),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
