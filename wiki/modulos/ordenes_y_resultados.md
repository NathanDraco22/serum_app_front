---
title: Módulos — Órdenes Médicas, Pagos y Resultados
description: Especificación funcional del flujo clínico de órdenes de laboratorio, cobros en caja registradora y captura de resultados analíticos.
tags: [orders, payments, clinical_results, pos, ui]
timestamp: 2026-09-28T19:46:00Z
---

# 📦 Órdenes Médicas, Pagos y Resultados (`order`)

El módulo `order` (`lib/src/modules/order/`) es el núcleo operativo y clínico del sistema LIS, donde confluyen la atención al paciente, la facturación POS y la emisión de resultados.

---

## 1. Estructura de Pantalla y Diálogos
- **Pantallas**:
  - `OrderScreen` (`view/order_screen.dart`): Tablero principal de seguimiento y listado de órdenes clínicas.
  - `CreateOrderScreen` (`view/create_order_screen.dart`): Pantalla completa (`/orders/new`) para crear órdenes con layout de dos columnas (catálogo interactivo de pruebas/perfiles a la izquierda y carrito/resumen de orden a la derecha).
- **Widgets Clave**:
  - `OrderCatalogSection` (`widgets/order_catalog_section.dart`): Columna izquierda con buscador debounced, filtros por categoría/tipo y grid interactivo.
  - `OrderCartSection` (`widgets/order_cart_section.dart`): Columna derecha con resumen, totales y listado de análisis seleccionados.
  - `OrderPatientCard` y `OrderDoctorCard` (`widgets/`): Tarjetas interactivas para asignar paciente y médico.
  - `PatientSelectionDialog` y `DoctorSelectionDialog` (`lib/src/widgets/dialogs/selectors/`): Modales dedicados (Pickers) con búsqueda reactiva debounced para miles de registros.
  - `OrdersList` (`widgets/orders_list.dart`): Listado de órdenes activas con badges de estado clínico y financiero.
  - `OrderPayDialog` (`widgets/order_pay_dialog.dart`): Modal de procesamiento de pago directo a caja activa.
  - `OrderResultsDialog` (`widgets/order_results_dialog.dart`): Interfaz para captura, validación y entrega de resultados médicos.
- **Cubits**:
  - `ReadOrderCubit`: Gestión de la lista de órdenes y estados en caché.
  - `WriteOrderCubit`: Creación, abonos y captura de resultados.
  - `ReadLabTestCubit`: Carga del catálogo de análisis y perfiles.
  - `SearchOrdersCubit`: Búsqueda de órdenes por folio o nombre de paciente.
  - `CashRegisterCubit`: Sincronización de saldos tras cobros.

---

## 2. Funcionalidades Detalladas

### A. Generación de Orden con Snapshot Inmutable
- Al dar de alta una orden médica:
  1. Se selecciona el paciente (obligatorio) y el médico referente (opcional).
  2. Se agregan pruebas individuales o packs.
  3. El sistema guarda un **Snapshot Inmutable**: congela el nombre del paciente, edad y sexo en ese momento, el precio de venta aplicado y los valores de referencia clínicos vigentes. Cualquier cambio futuro en el catálogo no alterará esta orden histórica.

### B. Módulo de Cobro Integrado (`OrderPayDialog`)
- Permite pagar el monto total o registrar pagos parciales/anticipos.
- Selección del método de cobro: Efectivo (`cash`), Tarjeta (`card`) o Transferencia (`transfer`).
- Al confirmar el pago:
  - Invoca el endpoint transaccional del backend.
  - Actualiza el estado de la orden (`pending` ➔ `partiallyPaid` ➔ `paid`).
  - Incrementa automáticamente el saldo correspondiente en la caja registradora activa (`activeCashRegister`).
  - Genera una transacción de auditoría en el Kardex.

### C. Captura y Validación de Resultados (`OrderResultsDialog`)
- Lee los parámetros requeridos de cada prueba incluida en la orden:
  - **Campos Numéricos**: Valida el valor ingresado contra el rango de referencia del paciente (considerando sexo y edad). Si está fuera de rango, lo resalta visualmente en color de alerta (rojo o naranja).
  - **Campos Cualitativos**: Selector desplegable con las opciones clínicas configuradas.
  - **Observaciones**: Campo de texto para notas patológicas.
- Permite guardar resultados parciales o marcar la orden como completada (`completed`).
