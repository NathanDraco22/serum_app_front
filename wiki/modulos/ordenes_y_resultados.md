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
  - `AddServiceDialog` (`widgets/add_service_dialog.dart`): Modal con atajos rápidos para agregar y editar servicios adicionales libres (ej. servicio a domicilio, toma especial de muestra).
  - `OrderResultsDialog` (`widgets/order_results_dialog.dart`): Orquestador principal de captura, autocalculado reactivo y guardado de resultados médicos.
  - `OrderInvoiceViewer` (`lib/src/widgets/dialogs/viewers/order_invoice_viewer.dart`): Visor interactivo para el Comprobante de Factura de la orden con soporte para impresión directa, exportación y envío de PDF.
  - `OrderInvoicePdfTemplate` (`lib/src/tools/exports/pdf/templates/order_invoice_pdf_template.dart`): Plantilla PDF oficial A4 para comprobantes de factura con desglose de pruebas, servicios y recibos.
  - Subwidgets especializados en `widgets/order_results_dialogs/`:
    - `ParameterCard`: Tarjeta analítica con valores de referencia, selector cualitativo, input numérico reactivo y badge `Auto ⚡`.
    - `ParameterBadgePill`: Pill visual de alertas médicas (`ALTO ▲`, `BAJO ▼`, `NORMAL`, `ANORMAL`, `PENDIENTE`).
    - `OrderResultsHeader`: Cabecera visual con icono de laboratorio, nombre del examen, `#ID` de orden, paciente y botón de cierre.
    - `OrderResultsSummaryBar`: Barra métrica de progreso, chip de balance diferencial leucocitario al 100% y conteo de alertas.
    - `OrderResultsFooter`: Acciones de pie para visualización de informe clínico PDF, cancelar y guardar/completar con spinner animado.
- **Herramientas de Soporte (`lib/src/tools/calculators/`)**:
  - `ClinicalFormula`: Modelo inmutable de definición de fórmulas y resultados formateados.
  - `ClinicalFormulasRegistry`: Catálogo maestro de fórmulas médicas estándar y resolución canónica por alias.
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

### C. Captura Reactiva de Resultados y Motor de Fórmulas Clínicas (`OrderResultsDialog`)

La captura de resultados incorpora el **Motor de Fórmulas Clínicas** (`lib/src/tools/calculators/`), permitiendo el autocalculado reactivo e instantáneo en el frontend sin latencia ni roundtrips al servidor:

#### 1. Fórmulas Médicas Integradas (Estándares Internacionales)
- **Serie Roja / Hematología (Regla de los 3 e Índices de Wintrobe, 1929)**:
  - **Hematocrito (`HTC` / `HTO`) — Disparador Principal**: Medición física en centrífuga. Al capturarse, dispara en cascada:
    - **Hemoglobina (`HB`)**: $\text{HB} = \frac{\text{HTC}}{3}$ (redondeo a 1 decimal, g/dL).
    - **Eritrocitos (`ERI`)**: $\text{ERI} = \frac{\text{HB}}{3} = \frac{\text{HTC}}{9}$ (redondeo a 3 decimales en escala millones, x mm³).
    - **VCM (Volumen Corpuscular Medio)**: $\text{VCM} = \frac{\text{HTC (\%)} \times 10}{\text{ERI (millones/mm}^3)}$ en $\mu\text{m}^3$ (fL) (constante 90 si deriva estrictamente de regla de los 3).
    - **HCM (Hemoglobina Corpuscular Media)**: $\text{HCM} = \frac{\text{HB (g/dL)} \times 10}{\text{ERI (millones/mm}^3)}$ en $\text{pg}$ (constante 30).
    - **CHCM (Concentración de Hb Corpuscular Media)**: $\text{CHCM} = \frac{\text{HB (g/dL)} \times 100}{\text{HTC (\%)}}$ en $\text{g/dL}$ (constante 33).
  - **Recálculo Dinámico (Sobreescritura Manual)**: Si el bioanalista edita manualmente la hemoglobina o los eritrocitos en casos patológicos, **NO** se recalcula el hematocrito, pero **SÍ** se recalculan en tiempo real los índices `VCM`, `HCM` y `CHCM` usando los valores en pantalla.
  - **Normalización de Escala**: `normalizeErythrocytesToMillions(eri)` garantiza que los eritrocitos ingresados en millones (5.000), miles (5000) o enteros absolutos siempre se calculen sobre base de millones.
- **Bioquímica / Perfil Hepático**:
  - **Bilirrubina Indirecta**: $\text{BIL-I} = \text{BIL-T} - \text{BIL-D}$ en $\text{mg/dL}$.
- **Serie Blanca / Diferencial Leucocitario**:
  - Parámetros de entrada directa: Leucocitos (`LEU`) y Plaquetas (`PLAQ`).
  - 7 parámetros diferenciales porcentuales con valor por defecto `0`: $\text{SEG} + \text{LINF} + \text{EOS} + \text{MON} + \text{BAN} + \text{BAS} + \text{LINF-ATIP} = 100\%$.
  - Validación Bloqueante de Negocio: Si se ingresan datos en el diferencial, la suma debe ser **estrictamente igual a 100%**. Si es menor o mayor a 100%, se muestra una alerta visual y se **impide el cierre o guardado** del resultado.

#### 2. Detección Inteligente y Resolución Canónica de Parámetros
- `ClinicalFormulasRegistry.resolveCanonicalKey(text)` analiza el parámetro examinando códigos oficiales (`VCM`, `HCM`, `CHCM`, `HB`, `HTC`, `ERI`, `LEU`, `PLAQ`, `BIL-T`, `BIL-D`, `BIL-I`) y alias textuales en español (`"Volumen Corpuscular Medio"`, `"Hemoglobina"`, `"Hematocrito"`, etc.).
- Utiliza una lista de alias ordenada por **longitud descendente**, garantizando que frases compuestas (ej. `"hemoglobina corpuscular media"`) se evalúen antes que términos más generales (`"hemoglobina"`), evitando falsos positivos.

#### 3. Control Clínico, Flags H/L y Transparencia
- **Badge `"Auto ⚡"`**: Los campos autocalculados despliegan una insignia distintiva con un tooltip que expone la fórmula matemática utilizada.
- **Sobreescritura Manual Respetada**: Si el laboratorio cuenta con analizadores hematológicos automatizados (Sysmex/Mindray) o mide parámetros por separado, el usuario puede teclear sobre cualquier campo autocalculado; el sistema respetará su captura manual.
- **Indicadores Fuera de Rango (Flags H / L)**: Cada resultado numérico se valida contra los límites normales (`minValue` y `maxValue` para la demografía del paciente):
  - $\text{Resultado} > \text{maxValue} \to$ Flag **`H`** (`ALTO ▲ (H)`).
  - $\text{Resultado} < \text{minValue} \to$ Flag **`L`** (`BAJO ▼ (L)`).
  - Dentro de rango normal $\to$ Sin flag (`null` / badge verde `NORMAL`).
  - Pruebas cualitativas que difieren del esperado $\to$ Flag **`ABNORMAL`** (`ANORMAL`).

### D. Informes Clínicos y Sobres Físicos de Entrega
- **Informe Clínico PDF (`ClinicalOrderViewer` y `SingleClinicalOrderTemplate`)**:
  - Emisión del documento A4 oficial con membrete de sucursal, subseries clínicas (`SERIE ROJA`, `SERIE BLANCA`, `DIFERENCIAL`, etc.) y alertas clínicas discretas `H`/`L` en rojo al rebasar límites biológicos.
- **Sobre Físico de Entrega (`OrderEnvelopeViewer` y `ClinicalOrderEnvelopePdfTemplate`)**:
  - Rotulación directa de sobres comerciales \#10 / Oficio ($10.5\text{ cm} \times 24.0\text{ cm}$) alimentados en vertical en la bandeja manual de la impresora.
  - Recuadro central delimitado con línea negra que incluye médico tratante (condicional: solo si existe), paciente y fecha.
  - Pie de sobre con marco redondeado azul y datos de contacto de la sede.
  - Para detalles de hardware, alimentación e implementación, ver **[Impresión de Sobres Clínicos](impresion_sobres_clinicos.md)**.

### E. Modificación Arbitraria de Precios, Bloqueo de Órdenes (`isBlocked`) y Aprobación por Supervisor

Para facilitar acuerdos comerciales en ventanilla sin perder el control de auditoría interna:

#### 1. Edición de Precios en el Carrito (`OrderCartSection`)
- **Interacción por Pulsación Prolongada (`onLongPress`)**: Al mantener presionado cualquier examen o paquete seleccionado en el carrito de `CreateOrderScreen`, se abre el diálogo [`EditItemPriceDialog`](file:///c:/Users/sytru/Developer/Projects/lab_project/serum_app_front/lib/src/modules/order/widgets/edit_item_price_dialog.dart).
- **Control de Precio Base y Aviso**: El diálogo muestra el precio original del catálogo (`originalPrice`, Precio 1) y permite capturar el nuevo valor.
- **Indicadores Visuales en Carrito**:
  - Badge `"Modificado"` sobre el precio del ítem.
  - Banner informativo amarillo al final del carrito advirtiendo al personal que la orden requerirá autorización de un supervisor para poder procesarse.

#### 2. Detección de Bloqueo al Emitir la Orden
- **Creación por Operador (`accessLevel <= 3`)**: Si cualquier examen tiene un precio diferente a su precio de lista, la orden se emite con `isBlocked: true` y `approval.requiresApproval: true`.
- **Creación por Supervisor (`accessLevel > 3`)**: Si quien está creando la orden en ventanilla es un usuario con nivel mayor a 3, el sistema pre-autoriza la orden automáticamente con sus datos, permitiendo su cobro inmediato sin pasos adicionales.

#### 3. Restricciones Visuales y Preventivas en el Listado (`OrdersList`)
- **Avatar con Candado**: Las órdenes bloqueadas despliegan un avatar de candado rojo (`Icons.lock`).
- **Badges de Auditoría**: Despliega el badge ámbar `BLOQUEADA (REQ. AUTORIZACIÓN)` o, tras autorizarse, el badge verde `AUTORIZADO: <Nombre del Supervisor>`.
- **Acciones Protegidas**:
  - El botón de **Pagar** (`Icons.payments_outlined`) y el de **Capturar Resultados** (`Icons.assignment_outlined`) se deshabilitan preventivamente en color atenuado. Al hacer clic, muestran un SnackBar explicativo recordando que la orden requiere desbloqueo previo.
  - El botón de **Eliminar** se mantiene activo siempre y cuando `paidAmount == 0`, permitiendo desechar órdenes bloqueadas emitidas por error.

#### 4. Flujo de Desbloqueo y Autorización (`Icons.lock_open`)
Al pulsar el botón de candado abierto, la interfaz se adapta dinámicamente según el usuario en sesión:
- **Modalidad Presencial (Operador $\le 3$)**: Se abre [`SupervisorAuthDialog`](file:///c:/Users/sytru/Developer/Projects/lab_project/serum_app_front/lib/src/modules/order/widgets/supervisor_auth_dialog.dart), solicitando usuario, contraseña y motivo al supervisor.
- **Modalidad Directa (Supervisor $> 3$)**: Se muestra un diálogo de confirmación de 1 solo clic aprovechando la sesión activa.
- **Invocación y Reactividad**: Ambos flujos llaman a `WriteOrderCubit.approveOrder(order.id, request)`. Tras la respuesta del servidor (`POST /api/v1/orders/{id}/approve`), se emite `OrderApproved`, se notifica al usuario con un SnackBar y se refresca la lista con `ReadOrderCubit.getAll()`.

---

### F. Servicios Adicionales en la Orden (Servicio a Domicilio y Otros)

Para cubrir las atenciones auxiliares no analíticas del laboratorio (ej. recargos por desplazamiento, tomas domiciliarias o urgencias):

1. **Captura con Atajos Rápidos (`AddServiceDialog`)**:
   - Botón `+ Agregar Servicio` en el carrito de formulación.
   - Proporciona botones de atajo rápido de un solo toque:
     - *"Servicio a Domicilio"*
     - *"Toma Especial de Muestra"*
     - *"Atención de Urgencia"*
     - *"Transporte de Muestras"*
     - *"Honorario Clínico Extra"*
   - Admite nombre libre y precio en moneda regular (convertido internamente a centavos enteros).
2. **Gestión en el Carrito (`OrderCartSection`)**:
   - Cada servicio se lista con icono distintivo, precio editable al vuelo y botón para remover.
   - Desglose contable en tiempo real:
     - *Subtotal Análisis:* Monto de las pruebas y perfiles.
     - *Subtotal Servicios:* Sumatoria de los servicios agregados.
     - *Total a Cobrar:* Consolidación global para la caja registradora.
3. **Persistencia e Integración**:
   - Se serializa en el arreglo `services: List<OrderService>` de la orden médica, impactando el `totalPrice` oficial.

---

### G. Comprobante de Factura y Estado de Cuenta Oficial (`OrderInvoiceViewer`)

Documento formal para el paciente y la administración que unifica el aspecto clínico y financiero:

1. **Contenido Estructurado**:
   - **Membrete Corporativo**: Nombre de la sede, dirección, teléfonos y correo del laboratorio.
   - **Datos de Paciente y Médico**: Nombre, cédula/ID, edad calculada, sexo y médico remitente.
   - **Tabla de Análisis Clínicos**: Listado de pruebas individuales y perfiles con su precio aplicado.
   - **Tabla de Servicios Adicionales**: Listado de servicios (ej. Servicio a Domicilio) con su precio individual.
   - **Totales de Facturación**: Subtotal análisis, subtotal servicios y total consolidado de la orden.
   - **Historial de Abonos y Pagos**: Tabla cronológica de recibos emitidos (`ReceiptInDb`), detallando folio de recibo, fecha, método de pago (`Efectivo`, `Tarjeta`, `Transferencia`), concepto y monto recibido.
   - **Estado de Cuenta de la Orden**: Total de la orden, total abonado y saldo pendiente (con distintivo verde *"PAGADA EN SU TOTALIDAD"* o azul/ámbar de saldo pendiente).
2. **Visor Interactivo y Exportación**:
   - Previsualización nativa e instantánea en pantalla (Scaffold a 0 ms).
   - Acciones integradas en la barra superior:
     - 🖨️ **Imprimir**: Envío directo a impresoras físicas o de red mediante `Printing.layoutPdf`.
     - 📄 **Exportar PDF**: Guardado del archivo PDF local mediante `PdfExportTool.export`.
     - 📤 **Compartir**: Envío mediante clientes de correo o mensajería con `Printing.sharePdf`.
3. **Puntos de Acceso en la Aplicación**:
   - **Listado de Órdenes (`OrdersList`)**: Icono `Icons.receipt_long_outlined` en cada tarjeta de orden.
   - **Historial de Recibos (`OrderReceiptsHistoryDialog`)**: Botón inferior *"Ver Comprobante de Factura"* para abrir el documento consolidado.


