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
  - `PatientsList` (`widgets/patients_list.dart`): Listado con cards informativas que muestran nombre completo, identificación, edad, sexo y teléfono.
  - `PatientFormDialog` (`widgets/patient_form_dialog.dart`): Diálogo modal para captura o edición de datos de paciente.
- **Cubits**:
  - `ReadPatientCubit`: Carga inicial (`getAll()`) y mantenimiento del estado en caché local.
  - `WritePatientCubit`: Operaciones de creación y modificación (`createPatient()`, `updatePatient()`).
  - `SearchPatientsCubit`: Búsqueda reactiva por texto libre (cédula o nombre).
- **Funcionalidades Clave**:
  1. **Búsqueda Instantánea**: Integra una barra de búsqueda con debounce. Si la caja de búsqueda se limpia, retorna la lista completa sin llamar innecesariamente a la red.
  2. **Validación de Datos Demográficos**: Valida campos obligatorios (nombre, fecha de nacimiento, sexo y sucursal de origen `originBranch`).
  3. **Sincronización Reactiva**: El `ReactiveRepository` emite eventos (`RepoItemCreated`, `RepoItemUpdated`) que el `ReadPatientCubit` escucha directamente, reflejando cambios en la pantalla al instante.

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
