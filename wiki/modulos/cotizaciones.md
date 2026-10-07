---
type: doc
title: Módulos — Cotizaciones y Presupuestos Rápidos
description: Especificación funcional y de interfaz del módulo quotation para presupuestos de venta con dos columnas, datos opcionales, y exportación e impresión a PDF de carácter estrictamente informativo.
tags: [quotations, pricing, sales, ui, pdf]
timestamp: 2026-10-06T18:00:00Z
---

# 📝 Cotizaciones y Presupuestos Rápidos (`quotation`)

El módulo `quotation` (`lib/src/modules/quotation/`) está diseñado para el mostrador de atención y recepción, permitiendo elaborar cotizaciones de venta al instante para personas que desean presupuestar análisis individuales o perfiles/packs clínicos, con un flujo directo y sin requerir un expediente obligatorio de paciente.

---

## 1. Arquitectura de Pantallas y Componentes

### A. Vistas Principales
* **`QuotationScreen` (`view/quotation_screen.dart`)**:
  - Vista general del historial de cotizaciones.
  - Barra de búsqueda reactiva por cliente, número de folio o nombre de análisis.
  - Botón de acción principal `"Nueva Cotización"` que navega con `context.push` hacia `/quotations/new`.
* **`CreateQuotationScreen` (`view/create_quotation_screen.dart`)**:
  - Pantalla completa dedicada en ruta `/quotations/new` montada sobre el `_rootNavigatorKey`.
  - Diseño responsivo en dos columnas (58% catálogo / 42% carrito en escritorio, apilado en pantallas reducidas).
  - Al completar la cotización, abre de forma inmediata y automática el visor interactivo de PDF listo para imprimir o guardar.

### B. Widgets y Componentes Modulares
* **`QuotationClientCard` (`widgets/quotation_client_card.dart`)**:
  - Permite capturar clientes de dos formas:
    1. **Cliente Casual en Texto Libre**: Escribir un nombre directamente en un campo de texto (o dejar por defecto `"Cliente General"`).
    2. **Paciente Registrado**: Botón `"Buscar"` que abre `PatientSelectionDialog`, o alta rápida en modal (`PatientFormDialog`). Muestra resumen de edad, sexo, teléfono y botón para alternar o desvincular.
* **`OrderDoctorCard` (`../order/widgets/order_doctor_card.dart`)**:
  - Selector de médico referente reutilizable y 100% opcional (permite asignar médico del catálogo, dar de alta al vuelo o dejar vacío para venta directa).
* **`QuotationCartSection` (`widgets/quotation_cart_section.dart`)**:
  - Panel del presupuesto que integra:
    - Tarjeta de cliente/paciente y tarjeta de médico.
    - Encabezado con contador de ítems y botón para vaciar.
    - Selector global y por ítem de tarifas clínicas (**P1 Regular** / **P2 Especial**).
    - Lista de análisis y packs agregados con indicador visual y precio cotizado.
    - Resumen dinámico del total presupuestado en centavos (`int`).
    - Botón `"Generar Cotización"`, habilitado tan pronto se añade al menos 1 análisis.
* **`QuotationsList` (`widgets/quotations_list.dart`)**:
  - Listado enriquecido de cotizaciones con avatar temático, cliente, folio abreviado (`#XXXX`), desglose de análisis, fecha y monto total.
  - Botón directo de **Ver / Imprimir Cotización** (`Icons.print_outlined`) en cada tarjeta para acceder al PDF en 1 solo clic.
  - Eliminación lógica con diálogo de confirmación.

---

## 2. Herramientas de Exportación e Impresión a PDF

### A. Plantilla de Presupuesto (`SingleQuotationTemplate`)
* **Ubicación**: `lib/src/tools/exports/pdf/templates/quotation_pdf_template.dart`
* **Especificaciones**:
  - Formato de página A4 con membrete institucional de la sucursal activa (`branch.name`, dirección y teléfonos).
  - Folio único de presupuesto y fecha formateada (`dd/MM/yy HH:mm`).
  - Datos de cliente casual o paciente (edad, sexo, identificación, contacto).
  - Datos del médico referente (o leyenda *"Venta directa / Solicitud particular"*).
  - Tabla desglosada de análisis cotizados (`#`, Descripción, Tipo `PACK` vs `INDIVIDUAL`, Tarifa `P1/P2`, Precio Cotizado).
  - Caja de total presupuestado destacada.
  - Cláusula de validez del presupuesto (15 días de vigencia con tarifas congeladas).
  - Espacio formal para firma de recepción y sello del laboratorio.

### B. Visor Modal Interactivo (`showQuotationViewerDialog`)
* **Ubicación**: `lib/src/widgets/dialogs/viewers/quotation_viewer.dart`
* **Acciones Integradas**:
  - **Exportar PDF**: Descarga el archivo generado vía `PdfExportTool.export`.
  - **Imprimir**: Abre el spooler nativo del sistema operativo mediante `Printing.layoutPdf`.
  - **Compartir**: Envía el archivo por correo o aplicaciones instaladas vía `Printing.sharePdf`.

---

## 3. Reglas Operativas y Comparación con Órdenes

| Característica | Módulo `order` (Órdenes Clínicas) | Módulo `quotation` (Cotizaciones) |
|---|---|---|
| **Ruta de Creación** | `/orders/new` (`CreateOrderScreen`) | `/quotations/new` (`CreateQuotationScreen`) |
| **Cliente / Paciente** | **Obligatorio** registrado en base de datos (`patientId`) | **Opcional** (admite cliente casual en texto libre o paciente registrado) |
| **Médico Referente** | Opcional | Opcional |
| **Generación de Resultados** | Genera `OrderTestResult` con valores de referencia vacíos para laboratorio | **No genera resultados clínicos** (es solo presupuesto) |
| **Cobro y Kardex** | Permite cobro parcial/total que afecta caja y Kardex | **No procesa cobro inmediato** en la creación |
| **Salida a PDF** | Informe clínico con resultados y flags | Presupuesto comercial con validez de 15 días y tabla de tarifas |
| **Apertura de PDF** | Manual desde el visor de orden completada | **Inmediata y automática** tras presionar *"Generar Cotización"* |
| **Naturaleza del Documento** | Orden clínica formal con trazabilidad | Presupuesto informativo de preventa (sin conversión a orden) |
