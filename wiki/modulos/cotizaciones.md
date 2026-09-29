---
title: Módulos — Cotizaciones y Presupuestos Rápidos
description: Especificación funcional del módulo quotation para presupuestos de venta y su posterior conversión a órdenes.
tags: [quotations, pricing, sales, ui]
timestamp: 2026-09-28T19:46:00Z
---

# 📝 Cotizaciones y Presupuestos Rápidos (`quotation`)

El módulo `quotation` (`lib/src/modules/quotation/`) está diseñado para el mostrador de atención al público, permitiendo elaborar presupuestos al instante para personas que solo desean consultar precios.

---

## 1. Estructura de Pantalla y Diálogos
- **Pantalla**: `QuotationScreen` (`view/quotation_screen.dart`).
- **Widgets Clave**:
  - `QuotationsList` (`widgets/quotations_list.dart`): Listado de cotizaciones con datos de cliente, fecha, vigencia, total y estado (`draft`, `issued`, `converted`, `expired`).
  - `QuotationFormDialog` (`widgets/quotation_form_dialog.dart`): Diálogo para presupuestar pruebas y paquetes.
- **Cubits**:
  - `ReadQuotationCubit`: Lectura y caché de cotizaciones.
  - `WriteQuotationCubit`: Creación y conversión a orden.
  - `SearchQuotationsCubit`: Búsqueda por folio o cliente.

---

## 2. Funcionalidades Detalladas

### A. Presupuestos sin Expediente Previo
- A diferencia de las órdenes clínicas, una cotización no exige crear un paciente formal en la base de datos; basta con capturar un nombre en texto libre (ej. "Cliente Mostrador").

### B. Selección Dinámica y Totales en Centavos
- Permite añadir o remover pruebas y packs sobre la marcha.
- Calcula el total general garantizando consistencia monetaria en centavos (`int`).

### C. Conversión a Orden Médica
- Cuando el cliente decide realizarse los estudios, la cotización se convierte en orden médica.
- En este paso, el sistema exige seleccionar o registrar al paciente formal para generar el expediente clínico inmutable correspondiente.
