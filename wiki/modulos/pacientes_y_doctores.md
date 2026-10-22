---
title: Módulos — Pacientes y Médicos
description: Especificación funcional de los módulos patient y doctor para la gestión demográfica y referentes médicos.
tags: [patients, doctors, demographics, ui]
timestamp: 2026-09-28T19:46:00Z
---

# 👤 Pacientes y Médicos Referentes

Este documento describe la operativa de los módulos de expedientes demográficos de pacientes y directorio de médicos solicitantes.

---

## 1. Módulo `patient` (`lib/src/modules/patient/`)
- **Pantalla**: `PatientScreen` (`view/patient_screen.dart`).
- **Widgets**:
  - `PatientsList` (`widgets/patients_list.dart`): Listado con cards informativas que muestran el código incremental correlativo (`#0001`), nombre completo, cédula de identidad (`cardId`), edad, sexo y teléfono.
  - `PatientFormDialog` (`widgets/patient_form_dialog.dart`): Diálogo modal para captura o edición de datos de paciente (en modo edición despliega el código asignado).
- **Cubits**:
  - `ReadPatientCubit`: Carga inicial (`getAll()`) y mantenimiento del estado en caché local.
  - `WritePatientCubit`: Operaciones de creación y modificación (`createPatient()`, `updatePatient()`).
  - `SearchPatientsCubit`: Búsqueda reactiva por texto libre (código correlativo, cédula o nombre).
- **Funcionalidades Clave**:
  1. **Código Correlativo de Expediente (`id`)**: Generado atómicamente por `CounterManager().next_patient_number()` formateado a 4 dígitos (`0001`, `0002`, etc.). Es visible en listados, tarjetas de creación de órdenes (`OrderPatientCard`), cotizaciones (`QuotationClientCard`), selector modal (`PatientSelectionDialog`), ficha de detalles con copiado a 1 toque (`PatientInfoDialog`), visor clínico y documentos PDF impresos.
  2. **Diferenciación de Cédula (`cardId`)**: Se distingue visualmente de forma estricta el identificador correlativo de laboratorio del documento de identidad oficial.
  3. **Búsqueda Instantánea**: Integra una barra de búsqueda con debounce indexada en MongoDB (`TextSearchIndex` que abarca `name`, `cardId`, `phone` y `id`). Si la caja de búsqueda se limpia, retorna la lista completa sin llamar innecesariamente a la red.
  4. **Validación de Datos Demográficos**: Valida campos obligatorios (nombre, fecha de nacimiento, sexo y sucursal de origen `originBranch`).
  5. **Sincronización Reactiva**: El `ReactiveRepository` emite eventos (`RepoItemCreated`, `RepoItemUpdated`) que el `ReadPatientCubit` escucha directamente, reflejando cambios en la pantalla al instante.
  6. **Expediente e Historial de Órdenes (`PatientOrdersHistoryScreen`)**: Vista completa accesible por ruta `/patients/:patientId/orders` y métodos estáticos `.show()`, listando todas las órdenes clínicas históricas, balances y recibos.
  7. **Comparativa Evolutiva y Delta Check de Biometrías (`ClinicalComparisonViewerDialog`)**: Motor analítico que detecta automáticamente si el paciente cuenta con dos o más Biometrías Hemáticas para compararlas a un solo clic, o mediante selección manual de dos órdenes cualesquiera. Calcula variaciones absolutas ($\Delta$), porcentuales ($\% \Delta$), tendencias ($\uparrow, \downarrow, \approx$) y genera el reporte oficial en PDF (`ClinicalComparisonPdfTemplate`).

---

## 2. Módulo `doctor` (`lib/src/modules/doctor/`)
- **Pantalla**: `DoctorScreen` (`view/doctor_screen.dart`).
- **Widgets**:
  - `DoctorsList` (`widgets/doctors_list.dart`): Listado de médicos con especialidad, número de cédula profesional y teléfono.
  - `DoctorFormDialog` (`widgets/doctor_form_dialog.dart`): Formulario modal para alta y edición de médicos.
- **Cubits**:
  - `ReadDoctorCubit`: Consulta y caché de médicos referentes.
  - `WriteDoctorCubit`: Mutaciones de datos de médicos.
  - `SearchDoctorsCubit`: Búsqueda rápida por nombre o especialidad.
- **Funcionalidades Clave**:
  1. **Catálogo de Referencias**: Permite llevar el registro exacto de qué médicos canalizan pacientes al laboratorio.
  2. **Vínculo con Órdenes**: Facilita la selección inmediata del médico remitente en el diálogo de creación de órdenes clínicas.
