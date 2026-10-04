---
type: index
title: Frontend — Índice de Módulos Funcionales
description: Índice con la lista de módulos funcionales explicados del frontend Flutter.
tags: [frontend, modules, ui, index]
timestamp: 2026-09-28T19:46:00Z
---

# 📦 Módulos Funcionales del Frontend

Este directorio documenta a profundidad cada una de las áreas funcionales de la aplicación Flutter `serum_app_front`, sus pantallas, widgets hijos, formularios modales y los Cubits de estado con los que se comunican.

---

## 📑 Índice de Módulos

| Documento | Módulos Comprendidos | Descripción y Funcionalidades |
| :--- | :--- | :--- |
| **[Autenticación y Sesión](auth_y_sesion.md)** | `splash`, `auth`, `cash_register_selection`, `home_menu` | Ciclo de vida de tokens Hive AES-256, login, selección de caja física, guards de navegación y shell lateral. |
| **[Pacientes y Doctores](pacientes_y_doctores.md)** | `patient`, `doctor` | Expedientes demográficos de pacientes, búsqueda con debounce, directores de médicos referentes y vinculación a sucursales. |
| **[Pruebas de Laboratorio y Packs](lab_tests_y_packs.md)** | `lab_test` | Catálogo de análisis individuales y paquetes comerciales, selector avanzado con comparador de precios y visor de rangos. |
| **[Órdenes, Pagos y Resultados](ordenes_y_resultados.md)** | `order` | Ciclo de órdenes médicas con snapshots inmutables, modal de cobro integrado a caja registradora y captura adaptativa de resultados. |
| **[Cotizaciones](cotizaciones.md)** | `quotation` | Presupuestos para clientes casuales, cálculo de totales y conversión a órdenes. |
| **[Cajas y Kardex](cajas_y_kardex.md)** | `cash_register`, `cash_transaction` | Apertura formal de caja, arqueo con cálculo de sobrante/faltante, cierre y Kardex inmutable de movimientos financieros. |
| **[Administración, Sucursales y Usuarios](administracion_sucursales_y_usuarios.md)** | `administration`, `branch`, `user` | Centro de control de infraestructura clínica, submenú en cuadrícula responsiva, y consolas de gestión en pantalla completa para sucursales y colaboradores con asignación de roles y sedes. |
| **[Reportes Analíticos y Gráficos](reportes_analiticos.md)** | `report` | Inteligencia de negocio con gráficos interactivos `fl_chart`: facturación vs Kardex, top médicos referentes, demanda de análisis/packs, cartera vencida y auditoría de turnos de caja con arqueos y discrepancias. |
