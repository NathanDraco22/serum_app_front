---
type: index
title: Frontend — Mapa del Proyecto (Project Index)
description: Mapa maestro y exhaustivo de la arquitectura de la aplicación Flutter, módulos, cubits, widgets, flujo de capas y responsabilidades funcionales.
tags: [frontend, architecture, flutter, dart, bloc, cubit, index, map]
timestamp: 2026-09-28T19:46:00Z
---

# 🗺️ Project Index — Frontend (Serum App Flutter & LIS)

Este documento constituye el **mapa central y rector** del frontend (`serum_app_front` y `serum_business`). Cualquier agente o desarrollador que trabaje en la interfaz de usuario, manejo de estados, integración de APIs o persistencia local DEBE utilizar este índice para comprender la arquitectura, localizar los componentes adecuados y respetar el flujo de capas establecido.

---

## 🏛️ 1. Arquitectura General y Flujo de Capas

El frontend se divide en dos proyectos principales:
1. **`serum_app_front`**: La aplicación Flutter (UI, Diálogos, Widgets, Navegación con `go_router`, Cubits de UI y Sesión).
2. **`serum_business`**: Paquete Dart puro (`serum_app_front/packages/serum_business/`) que encapsula la lógica de negocio, clientes HTTP, almacenamiento seguro de tokens con Hive AES-256, modelos de datos fuertemente tipados, data sources y repositorios reactivos (`ReactiveRepository`).

### Flujo Unidireccional de Capas:
```
[ Vista (UI / Widgets / Dialogs) ]
               ↓ Invoca métodos / Escucha estados
[ Capa de Estado (BLoC / Cubit: Read, Write, Search, Session) ]
               ↓ Consulta o muta
[ Capa de Repositorios (Repositories / ReactiveRepository en serum_business) ]
               ↓ Consume y mapea
[ Capa de Fuentes de Datos (DataSources en serum_business) ]
               ↓ Emite peticiones HTTP o persistencia
[ Capa de Servicios e Infraestructura (HttpService / HiveTokenStorage) ]
```

---

## 📦 2. Árbol de Directorios del Frontend

```
serum_app_front/
├── lib/
│   ├── config/                         # Tema (app_theme.dart), Rutas (app_router.dart), Service Locator
│   ├── main.dart                       # Entrada principal, Hive.initFlutter(), inicialización
│   ├── material_app_builder.dart       # Builder con MediaQuery textScaler clamp
│   ├── provider_container.dart         # MultiRepositoryProvider y GlobalCubitProvider
│   └── src/
│       ├── cubits/                     # Cubits de alcance global o transversal
│       │   ├── app_session_cubit/      # Sesión de usuario activo y caja registradora en operación
│       │   ├── branch_cubit/           # Sucursal activa
│       │   ├── cash_register_cubit/    # Operaciones y lectura de cajas
│       │   ├── cash_transaction_cubit/ # Kardex financiero
│       │   ├── doctor_cubit/           # Médicos (Read, Write, Search)
│       │   ├── lab_test_cubit/         # Análisis y Packs (Read, Write, Search)
│       │   ├── order_cubit/            # Órdenes médicas (Read, Write, Search)
│       │   ├── patient_cubit/          # Pacientes (Read, Write, Search)
│       │   ├── quotation_cubit/        # Cotizaciones (Read, Write, Search)
│       │   ├── report_cubit/           # Reportes analíticos y métricas de negocio
│       │   └── user_cubit/             # Usuarios y colaboradores
│       ├── modules/                    # Módulos de pantalla (UI)
│       │   ├── administration/         # Hub central de administración (submenú en cuadrícula)
│       │   ├── auth/                   # Pantalla de Login y autenticación
│       │   ├── branch/                 # Consola de Sucursales / Sedes (CRUD en pantalla completa)
│       │   ├── cash_register_selection/# Selección obligatoria de caja física
│       │   ├── cash_register/          # Gestión de cajas, apertura y arqueo/cierre
│       │   ├── cash_transaction/       # Kardex contable de auditoría
│       │   ├── dashboard/              # Panel principal y bienvenida
│       │   ├── doctor/                 # Directorio de médicos referentes
│       │   ├── home_menu/              # Shell interactivo con barra lateral (StatefulNavigationShell)
│       │   ├── lab_test/               # Catálogo de pruebas clínicas y packs
│       │   ├── order/                  # Registro de órdenes, cobros y captura de resultados
│       │   ├── patient/                # Padrón de pacientes y expediente
│       │   ├── quotation/              # Presupuestos de venta con PDF e impresión inmediata
│       │   ├── report/                 # Reportes analíticos con gráficos interactivos (fl_chart)
│       │   ├── splash/                 # Pantalla de carga e hidratación de sesión
│       │   └── user/                   # Consola de Usuarios y Accesos (CRUD en pantalla completa)
│       ├── services/                   # Implementaciones de servicios locales (Secure storage)
│       ├── tools/                      # Formateadores, helpers y utilidades de UI
│       │   └── exports/                # Exportadores PDF (PdfExportTool, templates/reports/)
│       └── widgets/                    # Widgets y selectores transversales compartidos
├── packages/
│   └── serum_business/                 # Capa de negocio agnóstica en Dart puro
│       └── lib/src/
│           ├── constants/              # Códigos de error y constantes
│           ├── data/                   # DataSources que llaman a la API HTTP
│           ├── domain/                 # Modelos InDb/Create/Update y Repositorios
│           └── services/               # HttpService, HiveTokenStorage, TokenManager
└── wiki/                               # Esta Wiki
    ├── project_index.md                # ESTE ARCHIVO (Mapa rector del frontend)
    ├── AGENTS.md                       # Protocolo obligatorio para agentes IA
    ├── INDEX.md                        # Índice de navegación OKF
    ├── modulos/                        # Documentación funcional detallada por módulo
    └── arquitectura/                   # Arquitectura de capas y flujo de datos
```

---

## 🧭 3. Explicación Exhaustiva de las Funciones de Cada Módulo

A continuación se detalla la responsabilidad operativa, interfaz gráfica, cubits involucrados y funciones de cada módulo del sistema:

---

### 🔐 3.1 Módulo `splash` (Inicialización de Aplicación)
* **Ubicación**: `lib/src/modules/splash/`
* **Vistas**: `view/splash_screen.dart`
* **Cubits Asociados**: `AppSessionCubit`
* **Funciones Clave**:
  1. **Hidratación de Sesión Segura**: Al iniciar la aplicación, lee los tokens almacenados en `HiveTokenStorage` cifrados con clave AES-256.
  2. **Validación Preventiva de Token**: Si existe un token almacenado y está próximo a expirar (menos de 10 minutos), solicita preventivamente un refresh al endpoint `/auth/refresh`.
  3. **Comprobación de Estado de Usuario**: Valida contra `/auth/check-user` que el usuario siga activo y no haya sido revocado en MongoDB.
  4. **Enrutamiento Inteligente**: Si la sesión es válida y tiene caja seleccionada, redirige al Dashboard (`/`). Si la sesión es válida pero no tiene caja, redirige a Selección de Caja (`/select-cash-register`). Si no hay sesión válida, envía a Login (`/login`).

---

### 🔑 3.2 Módulo `auth` (Autenticación e Inicio de Sesión)
* **Ubicación**: `lib/src/modules/auth/`
* **Vistas**: `view/login_screen.dart`
* **Cubits Asociados**: `AppSessionCubit`, `WriteUserCubit`
* **Funciones Clave**:
  1. **Inicio de Sesión con Validación**: Captura usuario (`username`) y contraseña con validación de campos obligatorios en tiempo real.
  2. **Persistencia Cifrada**: Guarda `sessionToken` y `refreshToken` localmente en la caja Hive de sesión.
  3. **Control de Errores y Feedback**: Muestra errores claros en pantalla ante credenciales inválidas o falla de conexión sin bloquear la aplicación.
  4. **Disparo de Redirección Automática**: Una vez autenticado, GoRouter detecta el cambio de estado de sesión y lo transfiere a la pantalla de selección de caja.

---

### 🏧 3.3 Módulo `cash_register_selection` (Selección de Caja Operativa)
* **Ubicación**: `lib/src/modules/cash_register_selection/`
* **Vistas**: `view/select_cash_register_screen.dart`
* **Cubits Asociados**: `ReadCashRegisterCubit`, `AppSessionCubit`
* **Funciones Clave**:
  1. **Filtrado por Sucursal Activa**: Carga las cajas registradoras físicas asociadas a la sucursal del usuario logueado.
  2. **Identificación de Estado Operativo**: Muestra visualmente mediante tarjetas interactivas si cada caja está abierta (`isOpen: true`) o cerrada (`isOpen: false`), con el balance actual en efectivo.
  3. **Asignación a la Sesión Global**: Al hacer click en una caja, se establece como `activeCashRegister` en `AppSessionCubit`, permitiendo desbloquear el acceso al resto del sistema POS.

---

### 📊 3.4 Módulo `dashboard` & `home_menu` (Navegación y Panel General)
* **Ubicación**: `lib/src/modules/dashboard/` y `lib/src/modules/home_menu/`
* **Vistas**: `dashboard/view/dashboard_screen.dart`, `home_menu/home_menus_view.dart`
* **Cubits Asociados**: `AppSessionCubit`
* **Funciones Clave**:
  1. **Layout Shell Responsivo**: `HomeMenusView` implementa el contenedor con `StatefulNavigationShell` de `go_router`, manteniendo el estado de cada pestaña en memoria (`IndexedStack`).
  2. **Menú Lateral Dinámico (`_SideNav`)**: Lista los módulos del sistema con íconos, títulos y resaltado visual de la ruta activa.
  3. **Footer Informativo del Operador**: Muestra en la barra lateral el nombre del usuario conectado, su rol, la sucursal y la caja registradora asignada.
  4. **Acciones Rápidas de Sesión**: Proporciona botones inmediatos para cambiar de caja registradora activa o cerrar sesión de manera segura.

---

### 👤 3.5 Módulo `patient` (Catálogo y Expediente de Pacientes)
* **Ubicación**: `lib/src/modules/patient/`
* **Vistas**: `view/patient_screen.dart`
* **Widgets**: `widgets/patients_list.dart`, `widgets/patient_form_dialog.dart`
* **Cubits Asociados**: `ReadPatientCubit`, `WritePatientCubit`, `SearchPatientsCubit`
* **Funciones Clave**:
  1. **Listado con Paginación/Actualización**: Muestra el catálogo de pacientes con datos esenciales (nombre completo, documento de identidad, edad calculada, sexo y teléfono).
  2. **Búsqueda Instantánea**: Integra `SearchPatientsCubit` para buscar por nombre o número de identificación con debounce, sin borrar la vista ante búsquedas vacías.
  3. **Creación y Edición Integral**: Formulario modal para registrar o modificar datos demográficos, fecha de nacimiento, contacto y sucursal de origen (`originBranch`).
  4. **Reactividad Automática**: Tras crear o editar un paciente, `ReactiveRepository` emite el evento y la lista se actualiza instantáneamente sin requerir recarga manual del servidor.

---

### 🩺 3.6 Módulo `doctor` (Catálogo de Médicos Referentes)
* **Ubicación**: `lib/src/modules/doctor/`
* **Vistas**: `view/doctor_screen.dart`
* **Widgets**: `widgets/doctors_list.dart`, `widgets/doctor_form_dialog.dart`
* **Cubits Asociados**: `ReadDoctorCubit`, `WriteDoctorCubit`, `SearchDoctorsCubit`
* **Funciones Clave**:
  1. **Directorio de Médicos**: Despliega lista de médicos con nombre, especialidad, número de cédula o licencia médica y teléfono.
  2. **Búsqueda en Tiempo Real**: Búsqueda por texto con `SearchDoctorsCubit`.
  3. **Alta y Modificación**: Formulario para crear o actualizar el perfil de médicos que remiten pacientes al laboratorio, vinculados a la sucursal correspondiente.
  4. **Asignación en Órdenes**: Sirve de catálogo maestro para autocompletar el médico solicitante al generar órdenes de laboratorio.

---

### 🧪 3.7 Módulo `lab_test` (Catálogo Unificado de Pruebas y Packs)
* **Ubicación**: `lib/src/modules/lab_test/`
* **Vistas**: `view/lab_test_screen.dart`, `view/lab_test_form_screen.dart`
* **Widgets**: `widgets/lab_tests_list.dart`, `widgets/lab_test_detail_dialog.dart`, `widgets/pack_test_selector.dart`
* **Cubits Asociados**: `ReadLabTestCubit`, `WriteLabTestCubit`, `SearchLabTestsCubit`
* **Funciones Clave**:
  1. **Soporte Híbrido (Individuales vs Packs)**: Gestiona tanto pruebas analíticas individuales como paquetes comerciales (`isPack: true`) que agrupan múltiples análisis.
  2. **Filtros Multidimensionales**: Permite filtrar entre "Todas", "Pruebas Individuales", "Packs/Perfiles" y por categoría comercial.
  3. **Selector Avanzado para Packs (`PackTestSelector`)**: Modal interactivo que permite buscar, seleccionar múltiples pruebas existentes y comparar el precio de lista sumado contra el precio de paquete asignado.
  4. **Definición de Rangos y Valores de Referencia**: Permite configurar rangos por sexo y edad para valores numéricos, listas de opciones para valores cualitativos (ej. Positivo/Negativo) y formato de texto libre.
  5. **Visor de Ficha Técnica (`LabTestDetailDialog`)**: Diálogo amplio para inspeccionar parámetros clínicos, metodología y desglose de análisis incluidos.

---

### 📝 3.8 Módulo `quotation` (Cotizaciones, Preventa y Presupuestos PDF)
* **Ubicación**: `lib/src/modules/quotation/`
* **Vistas**: `view/quotation_screen.dart`, `view/create_quotation_screen.dart` (Ruta `/quotations/new`)
* **Widgets**: `widgets/quotation_cart_section.dart`, `widgets/quotation_client_card.dart`, `widgets/quotations_list.dart`, visor `lib/src/widgets/dialogs/viewers/quotation_viewer.dart`, plantilla `lib/src/tools/exports/pdf/templates/quotation_pdf_template.dart`
* **Cubits Asociados**: `ReadQuotationCubit`, `WriteQuotationCubit`, `ReadLabTestCubit`
* **Funciones Clave**:
  1. **Creación en Dos Columnas (`CreateQuotationScreen`)**: Flujo análogo a creación de órdenes en ruta `/quotations/new`, con catálogo clínico a la izquierda y carrito de presupuesto a la derecha.
  2. **Cliente y Médico Totalmente Opcionales**: Admite capturar clientes casuales ingresando un nombre provisional en texto libre (o dejando `"Cliente General"`), o bien seleccionando pacientes del catálogo maestro. Médico referente opcional.
  3. **Flujo Directo (Menos Pasos)**: No genera resultados clínicos de laboratorio ni obliga a realizar cobros inmediatos o asociar arqueos de caja.
  4. **Exportación e Impresión Inmediata a PDF**: Se abre automáticamente al confirmar la cotización con la plantilla `SingleQuotationTemplate` para imprimir en ticket/láser (`Printing.layoutPdf`) o descargar como archivo PDF (`PdfExportTool.export`).
  5. **Búsqueda en Historial e Impresión Rápida**: Listado con búsqueda en tiempo real por cliente, número de folio o análisis, y botón directo de impresión/visor (`Icons.print_outlined`) en cada tarjeta.
  6. **Carácter Exclusivamente Presupuestario**: Una cotización es estrictamente un presupuesto informativo independiente; no se procesa como orden médica ni genera resultados clínicos.

---

### 📦 3.9 Módulo `order` (Órdenes Clínicas, Pagos y Resultados)
* **Ubicación**: `lib/src/modules/order/`
* **Vistas**: `view/order_screen.dart`, `view/create_order_screen.dart`
* **Widgets**: `widgets/order_catalog_section.dart`, `widgets/order_cart_section.dart`, `widgets/order_patient_card.dart`, `widgets/order_doctor_card.dart`, `widgets/orders_list.dart`, `widgets/order_pay_dialog.dart`, `widgets/order_results_dialog.dart`
* **Cubits Asociados**: `ReadOrderCubit`, `WriteOrderCubit`, `ReadLabTestCubit`, `SearchOrdersCubit`, `CashRegisterCubit`
* **Funciones Clave**:
  1. **Creación en Pantalla Completa y Dos Columnas (`CreateOrderScreen`)**: Interfaz dedicada (`/orders/new`) con catálogo interactivo de análisis y perfiles a la izquierda y panel de orden/carrito a la derecha.
  2. **Selectores Especializados (Pickers) para Paciente y Médico**: Diálogos con búsqueda debounced (`SearchFieldDebounced`) preparados para miles de registros, con tarjetas interactivas de asignación (`OrderPatientCard`, `OrderDoctorCard`).
  3. **Captura con Snapshot Inmutable**: Al crear una orden, congela una copia idéntica del paciente, precios de venta y parámetros de referencia vigentes en ese instante, protegiendo los registros históricos.
  4. **Monitoreo de Estados**: Tarjetas de orden con insignias dinámicas según estado de flujo (`pending`, `sample_taken`, `in_process`, `completed`, `delivered`) y estado de pago (`unpaid`, `partially_paid`, `paid`).
  5. **Módulo de Cobro Integrado (`OrderPayDialog`)**:
     - Permite abonar o liquidar el saldo de la orden.
     - Permite seleccionar el método de pago (`cash`, `card`, `transfer`).
     - Afecta de inmediato la caja registradora activa y genera un movimiento en el Kardex.
  6. **Captura y Validación de Resultados Clínicos (`OrderResultsDialog`)**:
     - Despliega formulario adaptativo según el tipo de dato de cada prueba (campo numérico, selector cualitativo o área de texto).
     - Compara automáticamente los valores numéricos contra los rangos de referencia y alerta visualmente si un resultado está fuera de límites.
     - Permite marcar la orden como completada para su entrega al paciente.

---

### 💵 3.10 Módulo `cash_register` (Apertura, Cierre y Control de Cajas)
* **Ubicación**: `lib/src/modules/cash_register/`
* **Vistas**: `view/cash_register_screen.dart`
* **Widgets**: `widgets/cash_register_card.dart`, `widgets/cash_register_open_dialog.dart`, `widgets/cash_register_close_dialog.dart`, `widgets/cash_register_form_dialog.dart`
* **Cubits Asociados**: `ReadCashRegisterCubit`, `WriteCashRegisterCubit`
* **Funciones Clave**:
  1. **Supervisión de Cajas**: Despliega el balance consolidado por método de pago (`cashBalance`, `cardBalance`, `transferBalance`) de cada terminal física.
  2. **Apertura Formal (`CashRegisterOpenDialog`)**: Registra el fondo de caja inicial en efectivo (`initialCash`) y pasa el estado a abierta.
  3. **Arqueo y Cierre (`CashRegisterCloseDialog`)**: Captura el efectivo real contado, calcula automáticamente diferencias (sobrantes o faltantes) y genera la transacción de cierre en el sistema.
  4. **Creación y Configuración**: Permite al administrador crear nuevas terminales físicas asignadas a la sucursal.

---

### 📜 3.11 Módulo `cash_transaction` (Kardex Financiero e Historial de Movimientos)
* **Ubicación**: `lib/src/modules/cash_transaction/`
* **Vistas**: `view/cash_transaction_screen.dart`
* **Widgets**: `widgets/cash_transaction_list.dart`
* **Cubits Asociados**: `ReadCashTransactionCubit`
* **Funciones Clave**:
  1. **Auditoría Inmutable**: Libro contable de solo lectura donde se visualizan todos los movimientos monetarios de la sucursal y caja activa.
  2. **Tipificación de Transacciones**: Clasifica los movimientos en Apertura (`opening`), Cobro de Orden (`order_payment`), Ingreso Extraordinario (`income`), Retiro/Gasto (`withdrawal`) y Cierre (`closing`).
  3. **Desglose de Montos y Métodos**: Muestra el sentido contable (entrada `in` / salida `out`), método utilizado y nota de justificación.

---

### ⚙️ 3.12 Módulo `administration` (Hub Central de Administración)
* **Ubicación**: `lib/src/modules/administration/`
* **Vistas**: `view/administration_screen.dart`
* **Widgets**: `widgets/admin_module_card.dart`
* **Cubits Asociados**: Integrado en el Shell de navegación (`HomeMenusScreen`, Branch 8 `/admin`).
* **Funciones Clave**:
  1. **Consola Central**: Submenú moderno con tarjetas interactivas en cuadrícula responsiva (`GridView.extent`) para acceder a las áreas de configuración del sistema.
  2. **Tarjetas de Submódulos (`AdminModuleCard`)**: Componentes con hover interactivo y microanimaciones que abren las consolas de gestión en pantalla completa.
  3. **Extensibilidad**: Estructura modular preparada para la incorporación progresiva de nuevos módulos administrativos (roles, auditoría, configuración general).

---

### 🏢 3.13 Submódulos `branch` y `user` (Consolas de Gestión en Pantalla Completa)
* **Ubicación**: `lib/src/modules/branch/`, `lib/src/modules/user/`
* **Vistas**: `branch/view/branch_screen.dart` (`/admin/branches`), `user/view/user_screen.dart` (`/admin/users`)
* **Widgets**:
  - `branch/widgets/branches_list.dart`, `branch/widgets/branch_form_dialog.dart`
  - `user/widgets/users_list.dart`, `user/widgets/user_form_dialog.dart`
* **Cubits Asociados**: `ReadBranchCubit`, `WriteBranchCubit`, `ReadUserCubit`, `WriteUserCubit`
* **Funciones Clave**:
  1. **Apertura a Pantalla Completa (`parentNavigatorKey: _rootNavigatorKey`)**: Oculta la barra lateral para otorgar máxima amplitud y concentración operativa, con botón de retroceso (`Icons.arrow_back`) para volver al hub.
  2. **CRUD Completo de Sucursales**: Alta, edición y eliminación de sedes con buscador reactivo y protección para la sede matriz (`ORIGIN_BRANCH`).
  3. **CRUD Completo de Usuarios**: Control de credenciales, roles (`Admin`, `Cashier`, `Bioanalyst`, `Doctor`), asignación dinámica de sucursales autorizadas (`FilterChip`), switch de usuario activo y blindaje de la cuenta `root`.

---

### 📊 3.14 Módulo `report` (Reportes Analíticos y Business Intelligence)
* **Ubicación**: `lib/src/modules/report/`
* **Vistas**: `view/reports_screen.dart` (`/reports`, Branch 8 de `StatefulShellRoute`)
* **Widgets**:
  - `widgets/reports_filter_bar.dart`
  - `widgets/report_export_button.dart`
  - `widgets/financial_report_view.dart`
  - `widgets/top_doctors_report_view.dart`
  - `widgets/lab_tests_volume_view.dart`
  - `widgets/pending_balances_view.dart`
  - `widgets/shifts_audit_view.dart`
* **Cubits Asociados**: `ReportCubit` (inyectando `ReportsRepository` de `serum_business`)
* **Funciones Clave**:
  1. **Inteligencia Financiera**: Comparativa visual entre volumen facturado, cobranza real en Kardex y cartera insoluta, junto con desglose porcentual por método de pago (`PieChart`).
  2. **Top Médicos Prescriptores**: Ranking clínico de derivaciones con gráfico de barras ordenado por volumen facturado y número de órdenes.
  3. **Demanda de Catálogo y Packs**: Análisis de frecuencia de órdenes y cotizaciones distinguiendo visualmente entre análisis individuales y paquetes clínicos.
  4. **Cuentas por Cobrar y Morosidad**: Padrón interactivo de pacientes con saldos pendientes, días de mora acumulada y alertas de antigüedad.
  5. **Auditoría de Turnos de Caja**: Control de descuadres de caja con gráfico de dispersión/barras diferenciando sobrantes en verde ($>0$), faltantes en rojo ($<0$) y arqueos cuadrados ($0).
  6. **Control de Acceso Sensible (`PermissionGate`)**: Bloqueo y protección de las pestañas Financiera y Auditoría restringidas exclusivamente a usuarios con nivel supervisor o superior (`AccessLevels.supervisor` / 4+).
  7. **Exportación e Impresión Institucional a PDF (`ReportExportButton`)**: Generación de documentos PDF A4 con membrete institucional de sucursal, resumen de métricas clave en KPIs, tablas de auditoría detalladas con montos en centavos formateados, y soporte para descarga local (`export`) e impresión/vista previa física (`printPdf`).

---

## 💎 4. Convenciones Críticas de Datos y UI en Flutter

1. **Montos Siempre en Centavos**: Todos los precios y saldos son enteros (`int`). En la UI se formatean dividiendo entre 100 mediante utilidades de `tools/` (ej. `(amount / 100).toStringAsFixed(2)`).
2. **Timestamps en Milisegundos**: Las fechas de creación y actualización son enteros Unix en milisegundos (`DateTime.fromMillisecondsSinceEpoch(ms)`).
3. **Manejo Seguro de Contexto Asíncrono**: En todas las operaciones asíncronas de diálogos y pantallas, validar siempre `if (!context.mounted) return;` antes de usar `context` tras un `await`.
4. **Listados con `Refreshing`**: Las búsquedas o recargas no borran la lista previa; emiten el estado `Refreshing` mostrando un `LinearProgressIndicator` superior para máxima fluidez.
5. **No Reglas de Negocio en `widgets/` o `tools/`**: La validación de negocio reside en los Cubits y Repositorios; los widgets solo se encargan de la presentación y captura de eventos.
