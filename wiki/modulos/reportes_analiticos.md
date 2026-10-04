---
type: doc
title: Frontend — Módulo de Reportes Analíticos con Gráficos (fl_chart)
description: Documentación de la capa visual y de estado para métricas de facturación, demanda de estudios clínicos, cuentas por cobrar y arqueos de turnos de caja.
tags: [frontend, reports, fl_chart, analytics, cubit, permission_gate]
timestamp: 2026-10-04T15:30:00Z
---

# 📊 Módulo de Reportes Analíticos (`report`)

El módulo **Reportes Analíticos** proporciona al personal clínico, supervisores y administradores un centro de control analítico e inteligencia de negocio (**BI**) dentro de Serum App. Permite visualizar tendencias de ingresos, demanda de exámenes de laboratorio, ranking de médicos prescriptores, cartera vencida y auditorías de caja mediante gráficos estadísticos interactivos implementados con el paquete **`fl_chart`** y tablas de detalle.

---

## 🏛️ 1. Arquitectura y Ubicación

```
serum_app_front/
├── lib/
│   ├── config/
│   │   ├── app_router.dart                     # Branch 8: /reports (StatefulShellRoute)
│   │   └── service_locator.dart                # Inyección de ReportsDataSource y ReportsRepository
│   ├── provider_container.dart                 # MultiRepositoryProvider con ReportsRepository
│   └── src/
│       ├── cubits/
│       │   └── report_cubit/
│       │       ├── report_cubit.dart           # Lógica y llamadas analíticas
│       │       └── report_state.dart           # Estado inmutable, pestañas y caché
│       └── modules/
│           └── report/
│               ├── view/
│               │   └── reports_screen.dart     # Pantalla principal con pestañas y PermissionGate
│               └── widgets/
│                   ├── reports_filter_bar.dart      # Selector de rangos de fechas y sucursales
│                   ├── financial_report_view.dart   # Facturado vs Cobrado (BarChart + PieChart)
│                   ├── top_doctors_report_view.dart # Top médicos prescriptores (BarChart + tabla)
│                   ├── lab_tests_volume_view.dart   # Demanda de pruebas/packs (BarChart + tabla)
│                   ├── pending_balances_view.dart   # Cuentas por cobrar y morosidad (KPIs + tabla)
│                   └── shifts_audit_view.dart       # Arqueos y diferencias de caja (BarChart + tabla)
```

En la capa de negocio (`serum_business`):
- **Modelos**: [`packages/serum_business/lib/src/domain/models/report_model/report_models.dart`](file:///c:/Users/sytru/Developer/Projects/lab_project/serum_app_front/packages/serum_business/lib/src/domain/models/report_model/report_models.dart).
- **DataSource**: [`packages/serum_business/lib/src/data/reports_data_source.dart`](file:///c:/Users/sytru/Developer/Projects/lab_project/serum_app_front/packages/serum_business/lib/src/data/reports_data_source.dart) consumiendo `/api/v1/reports/*`.
- **Repositorio**: [`packages/serum_business/lib/src/domain/repositories/reports_repository.dart`](file:///c:/Users/sytru/Developer/Projects/lab_project/serum_app_front/packages/serum_business/lib/src/domain/repositories/reports_repository.dart).

---

## 🔒 2. Seguridad y Niveles de Acceso (`PermissionGate`)

Las pestañas del módulo se dividen por su nivel de sensibilidad:

| Pestaña | Nivel Requerido | Modo de Protección |
| :--- | :--- | :--- |
| **Financiero** | `AccessLevels.supervisor` (Lvl 4+) | `PermissionGate`: Si el usuario no tiene nivel supervisor/admin, se bloquea la vista y muestra placeholder restrictivo. |
| **Top Médicos** | General (Lvl 1+) | Accesible para personal médico y operativo. |
| **Volumen de Exámenes** | General (Lvl 1+) | Accesible para bioanalistas y administradores. |
| **Cuentas por Cobrar** | General (Lvl 1+) | Accesible para personal de recepción y cobranza. |
| **Auditoría de Turnos** | `AccessLevels.supervisor` (Lvl 4+) | `PermissionGate`: Acceso estrictamente limitado a supervisores de caja y administradores generales. |

---

## 📈 3. Los 5 Reportes y sus Componentes Visuales

### 3.1 Reporte Financiero (`FinancialReportView`)
- **KPIs**: Total Facturado, Total Cobrado Real en Caja (Kardex), Cartera Pendiente por Cobrar y Ratio de Cumplimiento de Cobro.
- **`BarChart` Comparativo**: Facturado vs Cobrado Real vs Pendiente con tooltips formateados en moneda.
- **`PieChart` de Métodos de Pago**: Distribución porcentual entre Efectivo (`cash`), Tarjeta (`card`) y Transferencia (`transfer`).
- **Tabla Desglosada por Sucursal**: Comparativa multi-sucursal cuando se consulta a nivel global.

### 3.2 Top Médicos Referentes (`TopDoctorsReportView`)
- **KPIs**: Cantidad de médicos activos con órdenes derivadas e ingresos generados.
- **`BarChart` de Ranking**: Facturación generada por médico (destacando al prescriptor principal).
- **Tabla de Ranking Clínico**: Puesto (#), Médico, Especialidad, Órdenes emitidas e Importe facturado total.

### 3.3 Demanda de Exámenes y Packs (`LabTestsVolumeView`)
- **Conmutador de Fuente**: `SegmentedButton` interactivo para alternar entre **Órdenes Clínicas** y **Cotizaciones** preventivas.
- **`BarChart` Diferenciado**: Grafica las frecuencias de solicitud diferenciando visualmente mediante colores de la paleta (`ColorPalette.tertiary` vs `ColorPalette.primary`) si se trata de un Pack o un Análisis individual.
- **Tabla Detallada**: Nombre, Badge de Tipo (PACK / INDIVIDUAL), Categoría, Frecuencia e Ingresos generados.

### 3.4 Cuentas por Cobrar (`PendingBalancesView`)
- **KPIs**: Saldo total insoluto, conteo de pacientes deudores y ticket promedio de deuda.
- **Tabla de Pacientes Deudores**: Identificador de orden, Nombre del paciente, Teléfono de contacto, Total facturado, Monto abonado, Saldo deudor e indicador visual de días de antigüedad (destacando deudas con más de 15 y 30 días de retraso).

### 3.5 Auditoría de Turnos y Arqueos (`ShiftsAuditView`)
- **Filtro Rápido**: `FilterChip` "Solo con discrepancias" para auditar exclusivamente turnos descuadrados.
- **`BarChart` de Discrepancias**: Barras bidireccionales donde las diferencias positivas se dibujan en verde (sobrante en caja), las negativas en rojo (faltante) y las exactas ($0) en color neutro.
- **Tabla de Auditoría**: Turno, Cajero responsable, Fecha/hora de apertura y cierre, Saldo del sistema, Efectivo físico declarado, Descuadre ($) y Observaciones/notas del cajero.

---

## 🕹️ 4. Gestión de Estado (`ReportCubit`)

El cubit gestiona filtros y almacena en caché los reportes cargados:
- **Rango de Fechas**: Normaliza timestamps a inicio del día (`00:00:00`) y fin del día (`23:59:59.999`).
- **Sucursal**: Permite seleccionar una sede específica o consultar el consolidado (`branchId = null`).
- **Caché Reactiva**: Si el usuario ya cargó un reporte y alterna entre pestañas con los mismos filtros, no se re-consulta la red innecesariamente a menos que invoque `refresh()` o modifique fechas/sucursal.

---

## 🖨️ 5. Exportación e Impresión a PDF (`tools/exports/`)

El módulo integra exportación profesional e impresión de reportes institucionales en PDF mediante `package:pdf` y `package:printing`, organizados en `lib/src/tools/exports/`:

```
serum_app_front/lib/src/tools/exports/
├── pdf_export_tool.dart                                # Herramienta con export() y printPdf()
├── exports.dart                                        # Barrel general de herramientas
└── pdf/
    ├── pdf_template.dart                               # Interfaz base PdfTemplate
    └── templates/
        └── reports/                                    # Plantillas de reportes analíticos
            ├── report_pdf_base.dart                    # Helpers compartidos (encabezados, KPIs, tablas, footer)
            ├── financial_report_pdf_template.dart      # Template PDF Financiero y Métodos de Pago
            ├── top_doctors_report_pdf_template.dart    # Template PDF Top Médicos Prescriptores
            ├── lab_tests_volume_report_pdf_template.dart # Template PDF Demanda de Análisis y Packs
            ├── pending_balances_report_pdf_template.dart # Template PDF Cuentas por Cobrar y Mora
            ├── shifts_audit_report_pdf_template.dart   # Template PDF Auditoría de Turnos y Descuadres
            └── reports_templates.dart                  # Barrel de plantillas
```

### Características de los Documentos PDF Generados:
1. **Formato Institucional A4**: Márgenes homogéneos, tipografía limpia, paleta de colores coherente con `ColorPalette`.
2. **Encabezado Completo**: Identidad de la sede o consolidado general, dirección, teléfono, rango de fechas analizado, fecha/hora de generación y usuario operador que emite el reporte.
3. **Resumen de KPIs**: Tarjetas estilizadas en la parte superior con los totales y promedios clave.
4. **Tablas Detalladas**: Listados con encabezados destacados, alineación numérica a la derecha, formateo de centavos a moneda (\$X.XX con comas de miles) y filas alternadas.
5. **Pie de Página con Paginación**: Separador tenue, mención a Serum LIS y numeración dinámica `Página X de Y`.
6. **Integración en la UI (`ReportExportButton`)**: Menú desplegable en la barra de filtros (`ReportsFilterBar`) con opciones para **"Descargar / Compartir PDF"** (`PdfExportTool.export`) e **"Imprimir / Vista Previa"** (`PdfExportTool.printPdf`), desactivándose automáticamente durante la carga y mostrando feedback contextual.

