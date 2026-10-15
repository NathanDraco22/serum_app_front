---
title: Módulos — Impresión de Sobres Físicos de Laboratorio
description: Guía y especificación técnica para la generación, previsualización e impresión de sobres físicos (#10 / Oficio) con alimentación vertical y diseño fiel a muestra física.
tags: [envelope, printing, pdf, orders, clinical, physical_printer]
timestamp: 2026-10-15T13:20:00Z
---

# ✉️ Impresión de Sobres Físicos de Laboratorio Clínico

Este documento describe la arquitectura, mecánica física de alimentación, diseño gráfico y puntos de integración para la impresión de **sobres físicos de entrega de resultados** en el sistema Serum.

---

## 1. Contexto Operativo y Propósito

En los laboratorios clínicos es práctica estándar entregar los resultados de exámenes dentro de un sobre físico formal para proteger la confidencialidad médica del paciente.

El sistema permite generar e imprimir este sobre en dos momentos clave del flujo de trabajo:
1. **En Recepción / Toma de Muestras:** Al registrar la orden médica, el recepcionista puede imprimir inmediatamente el sobre para rotular y resguardar la papelería del paciente.
2. **En Entrega de Resultados:** Una vez capturados y validados los resultados, el personal imprime el sobre y guarda los informes clínicos impresos en su interior.

---

## 2. Mecánica Física de la Impresora

### Formato y Dimensiones Físicas
- **Tipo de sobre:** Sobre estándar \#10 / Oficio comercial liso (sin membrete previo).
- **Dimensiones físicas:** $10.5\text{ cm}$ de ancho $\times 24.0\text{ cm}$ de largo.

### Alimentación en Bandeja Manual (Bypass)
- La mayoría de impresoras láser y de inyección (HP, Brother, Canon, Epson) disponen de una **bandeja multipropósito con guías laterales ajustables**.
- El sobre se coloca **en sentido vertical en el centro de la bandeja**, introduciendo primero su **lado angosto de $10.5\text{ cm}$**.
- La impresora tracciona el sobre a lo largo de sus $24.0\text{ cm}$.

```
             Bandeja Manual / Bypass de la Impresora
                [Guía]                     [Guía]
                   |     +---------------+     |
                   |     |    10.5 cm    |     |  <- Entra primero este extremo
                   |     |               |     |
                   |     | Contenido a   |     |  <- Imprime rotado a 90°
                   |     |     90°       |     |     (Lectura de izquierda a derecha)
                   |     |               |     |
                   |     |    24.0 cm    |     |
                   |     +---------------+     |
                               Rodillos
```

---

## 3. Especificación Visual (Fiel a la Muestra Física)

El diseño está optimizado para ser sobrio, elegante y despejado, modelado directamente sobre la muestra física real utilizada en el laboratorio:

```
+--------------------------------------------------------------------------------------------------+
|                                                                                                  |
|   [LOGO] Laboratorio Clínico                                                                     |
|          BIOMEDIC                                                                                |
|                                                                                                  |
|                                     +-------------------------------------------+                |
|                                     | CON ATENCION A:                           |                |
|                                     | KIRLA ARAUZ                               |  <- Condicional|
|                                     |                                           |     (Solo si   |
|                                     | Resultados de paciente:                   |    médico !=   |
|                                     | ADELA DUARTE                              |      null)     |
|                                     | FECHA: 15/10/2026                         |                |
|                                     +-------------------------------------------+                |
|                                                                                                  |
|   +------------------------------------------------------------------------------------------+   |
|   |   Consultorio Médico De Especialidades Divino Niño, de Unión FENOSA 1 C y 75 vrs al...   |   |
|   |   (f) Laboratorio clínico Biomedic   (@) info@biomedic.com   (W) 8783-4873               |   |
|   +------------------------------------------------------------------------------------------+   |
+--------------------------------------------------------------------------------------------------+
```

### Elementos Gráficos:
1. **Esquina Superior Izquierda (Logo y Razón Social):**
   - Logotipo oficial de la sucursal (descargado de forma asíncrona y segura).
   - Rótulo estilizado en cursiva: *"Laboratorio Clínico"*.
   - Nombre de la sucursal en negrita (`branch.name.toUpperCase()`).
   - El resto de la zona superior permanece completamente despejada.
2. **Zona Central (Recuadro Delimitado con Línea Negra Fina):**
   - Recuadro geométrico de $290\text{ pt}$ de ancho con borde negro continuo delgado ($0.75\text{ pt}$).
   - **`CON ATENCION A:` (Condicional):** Solo se muestra si la orden tiene un médico asignado. Si el médico es `null` o está vacío, **la sección se omite por completo**, subiendo el bloque de paciente.
   - **`Resultados de paciente:`:** Rótulo en negrita seguido del nombre del paciente en mayúsculas en la línea siguiente.
   - **`FECHA: dd/MM/yyyy`:** Fecha formateada de emisión/recepción de la orden.
3. **Pie del Sobre (Marco Azul Redondeado):**
   - Contenedor con borde azul claro ($0.8\text{ pt}$) y esquinas redondeadas (`BorderRadius.circular(6)`).
   - **Línea Superior:** Dirección física completa de la sucursal (`branch.address`).
   - **Línea Inferior:** Canales de contacto con iconos circulares estilizados:
     - Facebook / Marca (`f`) con el nombre del laboratorio.
     - Correo institucional (`@`).
     - Teléfono / WhatsApp (`W`) con el número de contacto.

---

## 4. Arquitectura de Software

La solución sigue la arquitectura modular establecida en `serum_app_front`:

### A. Plantilla PDF (`ClinicalOrderEnvelopePdfTemplate`)
- **Ubicación:** `lib/src/tools/exports/pdf/templates/clinical_order_envelope_pdf_template.dart`
- **Interfaz:** Implementa `PdfTemplate`.
- **Dimensiones Físicas:**
  ```dart
  static final PdfPageFormat envelopeVerticalFormat = PdfPageFormat(
    10.5 * PdfPageFormat.cm,
    24.0 * PdfPageFormat.cm,
    marginAll: 0.8 * PdfPageFormat.cm,
  );
  ```
- **Rotación Automática:** Se aplica `orientation: pw.PageOrientation.landscape` en el `PageTheme`. Como el papel es más alto que ancho ($24.0 > 10.5\text{ cm}$), el motor PDF rota automáticamente el lienzo a $90^\circ$.
- **Inversión $180^\circ$:** Recibe el parámetro opcional `bool rotate180`. Cuando es `true`, envuelve el contenido en `pw.Transform.rotateBox(angle: math.pi)` para alimentar por el extremo opuesto según la bandeja de la impresora.

### B. Visor y Panel de Control (`OrderEnvelopeViewer`)
- **Ubicación:** `lib/src/widgets/dialogs/viewers/order_envelope_viewer.dart`
- **Función de Entrada:** `showOrderEnvelopeViewerDialog(BuildContext context, OrderInDb order, {PatientInfo? patientInfo, DoctorInfo? doctorInfo})`.
- **Características:**
  - **Banner de Orientación Física:** Recuerda al operador cómo introducir el sobre por su lado angosto de $10.5\text{ cm}$.
  - **Botón de Invertir Sentido ($180^\circ$):** Permite girar la orientación en tiempo real en la pantalla.
  - **Componente `PdfPreview`:** Previsualización vectorial interactiva con soporte para impresión nativa (`Printing.layoutPdf`) o descarga directa (`PdfExportTool.export`).

### C. Puntos de Integración en la Interfaz de Usuario
1. **Listado Principal de Órdenes (`OrdersList`):**
   - Archivo: `lib/src/modules/order/widgets/orders_list.dart`.
   - Botón directo con icono de sobre (`Icons.mail_outline`) en cada tarjeta de orden.
   - Permite imprimir el sobre en cualquier momento sin necesidad de entrar al informe clínico.
2. **Visor de Informe Clínico (`ClinicalOrderViewer`):**
   - Archivo: `lib/src/widgets/dialogs/viewers/clinical_order_viewer.dart`.
   - Botón de acción con icono de sobre (`Icons.mail_outline`) en el `AppBar` superior junto a los botones de exportar informe.

---

## 5. Pruebas y Verificación

- **Suite de Pruebas Automatizadas:**
  - Archivo: `test/tools/exports/clinical_order_envelope_pdf_template_test.dart`.
  - Verifica:
    1. Dimensiones físicas exactas de $10.5\text{ cm} \times 24.0\text{ cm}$.
    2. Inclusión de `CON ATENCION A:` cuando la orden tiene médico asignado.
    3. Omisión estricta de `CON ATENCION A:` cuando el médico es nulo o vacío.
    4. Generación correcta con inversión de orientación (`rotate180: true`).
- **Comando de Ejecución:**
  ```bash
  flutter test test/tools/exports/clinical_order_envelope_pdf_template_test.dart
  flutter analyze
  ```
