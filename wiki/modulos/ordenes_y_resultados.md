---
title: Módulos — Órdenes Médicas, Pagos y Resultados
description: Especificación funcional del flujo clínico de órdenes de laboratorio, cobros en caja registradora y captura de resultados analíticos.
tags: [orders, payments, clinical_results, pos, ui]
timestamp: 2026-11-12T12:00:00Z
---

# 📦 Órdenes Médicas, Pagos y Resultados (`order`)

El módulo `order` (`lib/src/modules/order/`) es el núcleo operativo y clínico del sistema LIS, donde confluyen la atención al paciente, la facturación POS y la emisión de resultados.

---

## 1. Estructura de Pantalla y Diálogos
- **Controladores y Mediadores (`lib/src/modules/order/controllers/`)**:
  - `CreateOrderViewController`: Controlador `ChangeNotifier` (estándar OKF) que concentra el estado en memoria de la pantalla de creación (paciente, médico, ítems, servicios, descuentos, niveles de precios, notas), getters derivados de cálculos financieros y la generación del DTO inmutable `CreateOrder`.
  - `CreateOrderMediator`: `InheritedWidget` mudo (`updateShouldNotify: false`) que expone el controlador hacia los árboles de widgets sin redibujados globales involuntarios.
  - `OrderResultsViewController`: Controlador `ChangeNotifier` (estándar OKF v0.2) que administra el ciclo de vida de los controladores de texto, integración reactiva del motor de fórmulas de Wintrobe, diferencial leucocitario al 100%, alertas demográficas H/L y generación del DTO inmutable `UpdateOrder`.
  - `OrderResultsMediator`: `InheritedWidget` mudo (`updateShouldNotify: false`) para la captura de resultados clínicos sin prop-drilling en subwidgets.
- **Pantallas**:
  - `OrderScreen` (`view/order_screen.dart`): Tablero principal de seguimiento y listado de órdenes clínicas.
  - `CreateOrderScreen` (`view/create_order_screen.dart`): Pantalla completa (`/orders/new`) para crear órdenes con layout de dos columnas, orquestada mediante `CreateOrderMediator`.
- **Widgets Clave**:
  - `OrderCatalogSection` (`widgets/order_catalog_section.dart`): Columna izquierda con buscador debounced, filtros por categoría/tipo, filtro predeterminado `_hideProfileParameters = true` ("Ocultar parámetros de perfil") con chip interactivo y badge visual `PARÁMETRO`, y grid interactivo de selección de estudios comerciales conectado al controlador vía `ListenableBuilder`.
  - `OrderCartSection` (`widgets/order_cart_section.dart`): Columna derecha con resumen, totales y listado de análisis seleccionados; consume reactivamente el `CreateOrderViewController` eliminando prop-drilling.
  - `OrderPatientCard` y `OrderDoctorCard` (`widgets/`): Tarjetas interactivas para asignar paciente y médico.
  - `PatientSelectionDialog` y `DoctorSelectionDialog` (`lib/src/widgets/dialogs/selectors/`): Modales dedicados (Pickers) con búsqueda reactiva debounced para miles de registros.
  - `OrdersList` (`widgets/orders_list.dart`): Listado de órdenes activas con badges de estado clínico y financiero, con diseño limpio y despojado de prefijos redundantes (nombre del paciente como título directo junto a su ID, fila visual con icono clínico `Icons.science_outlined` para el estudio, y pastilla con estetoscopio para el médico remitente).
  - `OrderPayDialog` (`widgets/order_pay_dialog.dart`): Modal de procesamiento de pago directo a caja activa.
  - `AddServiceDialog` (`widgets/add_service_dialog.dart`): Modal con atajos rápidos para agregar y editar servicios adicionales libres (ej. servicio a domicilio, toma especial de muestra).
  - `OrderResultsDialog` (`widgets/order_results_dialog.dart`): Orquestador principal de captura, autocalculado reactivo y guardado de resultados médicos.
  - `OrderInvoiceViewer` (`lib/src/widgets/dialogs/viewers/order_invoice_viewer.dart`): Visor interactivo para el Comprobante de Factura de la orden con soporte para impresión directa, exportación y envío de PDF.
  - `OrderInvoicePdfTemplate` (`lib/src/tools/exports/pdf/templates/order_invoice_pdf_template.dart`): Plantilla PDF oficial A4 para comprobantes de factura con desglose de pruebas, servicios y recibos.
  - Subwidgets especializados en `widgets/order_results_dialogs/`:
    - `ParameterCard`: Tarjeta analítica con valores de referencia, selector cualitativo, input numérico reactivo, chips de atajos rápidos para texto libre y badge `Auto ⚡`.
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

Orquestado bajo el patrón **ViewController + Mediator (OKF v0.2)**, el diálogo desacopla la lógica clínica en `OrderResultsViewController` y `OrderResultsMediator`. La captura de resultados incorpora el **Motor de Fórmulas Clínicas** (`lib/src/tools/calculators/`), permitiendo el autocalculado reactivo e instantáneo en el frontend sin latencia ni roundtrips al servidor:

#### 1. Fórmulas Médicas Integradas (Estándares Internacionales)
- **Serie Roja / Hematología (Regla de los 3 e Índices de Wintrobe, 1929)**:
  - **Hematocrito (`HTC` / `HTO`) — Disparador Principal**: Medición física en centrífuga. Al capturarse o reescribirse, desbloquea y dispara siempre en cascada:
    - **Hemoglobina (`HB`)**: $\text{HB} = \frac{\text{HTC}}{3}$ (redondeo a 1 decimal, g/dL).
    - **Eritrocitos (`ERI`)**: $\text{ERI} = \frac{\text{HB}}{3} = \frac{\text{HTC}}{9}$ (redondeo a 3 decimales en escala millones, x mm³).
    - **VCM (Volumen Corpuscular Medio)**: $\text{VCM} = \frac{\text{HTC (\%)} \times 10}{\text{ERI (millones/mm}^3)}$ en $\mu\text{m}^3$ (fL) (constante 90 si deriva estrictamente de regla de los 3).
    - **HCM (Hemoglobina Corpuscular Media)**: $\text{HCM} = \frac{\text{HB (g/dL)} \times 10}{\text{ERI (millones/mm}^3)}$ en $\text{pg}$ (constante 30).
    - **CHCM (Concentración de Hb Corpuscular Media)**: $\text{CHCM} = \frac{\text{HB (g/dL)} \times 100}{\text{HTC (\%)}}$ en $\text{g/dL}$ (constante 33).
  - **Cálculo Bidireccional (`HB` $\to$ `HTC` y `Wintrobe`)**:
    - Si el bioanalista ingresa primero la **Hemoglobina** (`HB`), el sistema calcula de forma bidireccional $\text{HTC} = \text{HB} \times 3$, $\text{ERI} = \text{HB} / 3$ y los índices de Wintrobe.
    - **Preservación de Mediciones Manuales**: Si el bioanalista ya había ingresado manualmente un `HTC` (ej. `40`) y posteriormente ajusta la `HB` leída en espectrofotómetro (ej. `12.8`), el sistema **respeta el `HTC` manual** y recalcula `ERI` y Wintrobe utilizando los valores reales en pantalla.
    - **Prioridad Absoluta de Hematocrito**: Si en cualquier momento el bioanalista vuelve a escribir en `HTC`, este actúa como disparador maestro y recalcula de inmediato toda la Serie Roja sin quedar bloqueado.
  - **Limpieza Reactiva ante Insumos Vaciados**: Si se borra `ERI` en pantalla, `VCM` y `HCM` se limpian de inmediato (evitando cálculos fantasma con valores residuales en memoria), mientras `CHCM` se mantiene si `HB` y `HTC` siguen presentes. Si se vacía `HTC`, se limpian sus campos derivados autocalculados.
  - **Normalización de Escala**: `normalizeErythrocytesToMillions(eri)` garantiza que los eritrocitos ingresados en millones (5.000), miles (5000) o enteros absolutos siempre se calculen sobre base de millones.
- **Bioquímica / Función Renal**:
  - **Nitrógeno de Urea (BUN)**: $\text{BUN} = \text{Urea} \times 0.47$ (redondeo a 1 decimal, mg/dL). Escribir en `Urea` desbloquea y recalcula `BUN` en vivo.
- **Bioquímica / Perfil Hepático**:
  - **Bilirrubina Indirecta**: $\text{BIL-I} = \text{BIL-T} - \text{BIL-D}$ en $\text{mg/dL}$.
- **Bioquímica / Perfil Lipídico (Friedewald y Castelli)**:
  - **Colesterol VLDL**: $\text{VLDL} = \frac{\text{TRIG}}{5}$ en $\text{mg/dL}$.
  - **Colesterol LDL**: $\text{LDL} = \text{COL-T} - \text{HDL} - \text{VLDL}$ en $\text{mg/dL}$.
  - **Riesgo Coronario (Castelli I)**: $\text{RIESG-COR} = \frac{\text{COL-T}}{\text{HDL}}$ (ratio a 1 decimal).
- **Serie Blanca / Diferencial Leucocitario**:
  - Parámetros de entrada directa: Leucocitos (`LEU`) y Plaquetas (`PLAQ`).
  - 7 parámetros diferenciales porcentuales con valor por defecto `0`: $\text{SEG} + \text{LINF} + \text{EOS} + \text{MON} + \text{BAN} + \text{BAS} + \text{LINF-ATIP} = 100\%$.
  - **Control de Guardado Parcial (`hasDifferentialStarted`)**: Los ceros iniciales no bloquean el guardado de análisis no hematológicos si la Serie Blanca no ha iniciado. La validación estricta de suma al 100% se activa si al menos un parámetro diferencial es $> 0$ o si ya se capturó el conteo de `Leucocitos` (`LEU > 0`). Si el usuario revierte un diferencial a `0`, el bloqueo se levanta reactivamente.

#### 2. Detección Inteligente y Blindaje Contra Colisiones Canónicas
- `ClinicalFormulasRegistry.resolveCanonicalKey(text, ...)` analiza el parámetro examinando códigos oficiales y alias textuales en español ordenados por **longitud descendente** con delimitadores de frontera.
- **Blindaje Contextual Multi-Perfil**:
  - **Aislamiento de Glicohemoglobina (`HBA1C`)**: Exclusión estricta de términos como `'glico'`, `'a1c'`, `'fetal'`, `'electroforesis'` y unidades en `%` para que `HbA1c` jamás colisione ni altere la `Hemoglobina` (`HB`, g/dL) de la BHC en órdenes combinadas.
  - **Aislamiento de Eosinófilos Absolutos (`EOS-SANG`)**: Exige que los parámetros del diferencial se midan exclusivamente en `%`, evitando que recuentos absolutos en $\text{mm}^3$ contaminen la sumatoria leucocitaria.
  - **Exclusión de Líquidos Biológicos y Muestras Urinarias**: Se descartan muestras de orina, líquidos pleurales o ascíticos para que no colisionen con los lípidos séricos ni con `BUN`/`Urea` sanguíneos.
- **Restauración Determinista al Reabrir Órdenes (`_detectAndRestoreAutoCalculatedFields`)**:
  - Al abrir o reabrir una orden guardada, se detectan matemáticamente los campos que coinciden con las fórmulas para restaurar su badge `Auto ⚡` sin depender del orden de los resultados en la lista.
  - Los valores guardados que difieren de la fórmula se registran como modificaciones manuales, blindándolos de sobreescrituras accidentales al reabrir la orden.

#### 3. Control Clínico, Flags H/L y Transparencia
- **Badge `"Auto ⚡"`**: Los campos autocalculados despliegan una insignia distintiva con un tooltip que expone la fórmula matemática utilizada.
- **Sobreescritura Manual Respetada**: Si el laboratorio cuenta con analizadores hematológicos automatizados (Sysmex/Mindray) o mide parámetros por separado, el usuario puede teclear sobre cualquier campo autocalculado; el sistema respetará su captura manual.
- **Indicadores Fuera de Rango (Flags H / L)**: Cada resultado numérico se valida contra los límites normales (`minValue` y `maxValue` para la demografía del paciente):
  - $\text{Resultado} > \text{maxValue} \to$ Flag **`H`** (`ALTO ▲ (H)`).
  - $\text{Resultado} < \text{minValue} \to$ Flag **`L`** (`BAJO ▼ (L)`).
  - Dentro de rango normal $\to$ Sin flag (`null` / badge verde `NORMAL`).
  - Pruebas cualitativas que difieren del esperado $\to$ Flag **`ABNORMAL`** (`ANORMAL`).
- **Resolución demográfica centralizada (`ReferenceValueResolver`)**:
  - La edad se calcula en **días exactos** desde `dateOfBirth`; para órdenes históricas se usa `order.createdAt` como fecha de referencia. Si no hay fecha de nacimiento, se usa `explicitAge * 365`.
  - Solo se evalúan las dimensiones marcadas en cada `ReferenceValue`: `useAge` y `useGender`. Si `useAge = false` se ignora la edad; si `useGender = false` se ignora el género.
  - Si varios rangos coinciden, gana el más específico (ambos flags > solo edad > solo género > rango general), con desempate por género exacto, mayor `minAgeDays` y rango más angosto.
  - Si no hay rango aplicable, la tarjeta muestra **“Sin rango para esta edad/género”** y el badge pasa a **`SIN RANGO`**; no se calcula `H`/`L`.
  - El mismo resolvedor se usa en el visor clínico, los PDFs y la app móvil para evitar inconsistencias entre pantalla e impresión.
   - El visor y los PDFs recalculan la alerta con `ClinicalAlertEvaluator` a partir del valor actual y del rango resuelto; ignoran el `alertFlag` guardado y normalizan `NORMAL` como ausencia de alerta.
   - Para pacientes con `dateOfBirth > 0` o `explicitAge != null`, la edad exacta en días se usa incluso cuando es `0` (recién nacidos). El respaldo `patientAge * 365` solo aplica cuando no existe ningún dato demográfico. La UI muestra `0 días` cuando corresponde.
   - En resultados numéricos sin rango aplicable, la etiqueta principal es `Sin rango para esta edad/género`; si existe `referenceText`, se conserva como segunda línea explicativa en visor y PDF individual, sin sustituir la advertencia.

#### 4. Captura de Parámetros de Texto Libre y Atajos Rápidos
- **Campo Multilínea Amplio**: Para análisis descriptivos (`dataType: 'text'`), `ParameterCard` despliega un `TextFormField` multilínea (`minLines: 3`, `maxLines: null`, `textInputAction: TextInputAction.newline`) que ocupa el ancho completo disponible si no hay escala referencial.
- **Chips de Atajos Rápidos (`ActionChip`)**: Debajo del área de texto libre, se disponen chips compactos con las respuestas más habituales de laboratorio:
  - **"Ninguno"**, **"No se observa"**, **"Normal"**, **"Negativo"**.
  - Si el análisis posee opciones personalizadas en `qualitativeOptions` (o un `expectedQualitativeValue`), la tarjeta prioriza dinámicamente dichos valores como atajos.
- **Sincronización Inmediata y Estado Activo**: Al tocar un chip, se transcribe instantáneamente al campo de texto y se sincroniza reactivamente con el estado de la orden (`onNumericChanged`), marcando el parámetro como completado. El chip seleccionado se resalta con un icono de verificación (`Icons.check`). En modo solo lectura (`isReadOnly`), los chips permanecen deshabilitados.

#### 5. Valores por Defecto en Pruebas Cualitativas
- Las pruebas cualitativas inician con la primera opción de `qualitativeOptions` (normalmente `Negativo` o `No reactivo`) y se guardan con ese valor si el bioanalista no lo cambia. Es un comportamiento esperado para agilizar la captura de resultados negativos.
- El bioanalista debe cambiar explícitamente la opción cuando el resultado sea positivo o anormal.
- Si la primera opción no coincide con `expectedQualitativeValue`, la tarjeta puede mostrar `ANORMAL` desde el inicio; en ese caso se recomienda revisar el orden de `qualitativeOptions` o el valor esperado en el catálogo, no el flujo de captura.

### C.2. Revisión y Finalización Explícita de la Orden (`in_review` → `completed`)

Cuando el bioanalista guarda el último resultado pendiente, la orden **no se cierra automáticamente**: pasa al estado clínico `in_review`.

- **Badge `EN REVISIÓN`**: se muestra en `OrdersList` con color ámbar.
- **Botón `Finalizar Orden`**: aparece en la tarjeta de la orden cuando el estado es `in_review`, el usuario tiene `accessLevel >= 3` y la orden no está bloqueada. Abre una confirmación y llama a `POST /api/v1/orders/{id}/finalize`.
- **Filtro `En revisión`**: disponible en `OrdersScreen` y en el historial del paciente.
- **Edición**: mientras está en `in_review`, el botón de resultados abre el diálogo editable. Si se vacía un resultado y se guarda, la orden vuelve a `pending`.
- **Reapertura**: en una orden `completed`, el avatar o badge de estado abre `ReopenOrderDialog`, que exige un motivo y llama a `POST /api/v1/orders/{id}/reopen`. La orden vuelve a `in_review` conservando pagos e historial.
- **Permisos**: finalizar y reabrir requieren `accessLevel >= 3` (operador/bioanalista o superior).
- **Independencia del pago**: el PDF clínico está disponible con resultados completos, esté pagada o no. El pago solo actualiza el badge financiero, el recibo y el Kardex.
- **PDF clínico**: muestra `Estado: En revisión` mientras está en `in_review` y `Finalizado por: [nombre] — [fecha]` cuando está `completed`, tanto en el visor como en la plantilla PDF.

### D. Informes Clínicos y Sobres Físicos de Entrega
- **Informe Clínico PDF y Visor en Pantalla (`ClinicalOrderViewer`, `SingleClinicalOrderTemplate` y `ClinicalOrderGrouper`)**:
  - Emisión del documento A4 oficial con membrete institucional de sucursal, datos completos del paciente y fecha/hora de proceso.
  - **Separación Jerárquica por Estudio (Packs y Pruebas Individuales)**:
    - En órdenes multi-análisis (ej. Biometría Hemática + Examen General de Orina + Examen General de Heces), los resultados no se muestran concatenados ni corridos. Cada examen cuenta con su bloque independiente encabezado por el título del estudio en negrita (`examTitle`).
    - **Trazabilidad Inmutable (`parentExamName`)**: Los parámetros capturados en `order.results` registran el estudio de origen, garantizando una agrupación precisa y determinista. Para órdenes legadas, `ClinicalOrderGrouper` resuelve la pertenencia por identificadores clínicos o clasificación médica.
    - **Separadores Visuales Inter-Estudio**: Divisores sutiles con espaciado armónico delimitan claramente el final de un estudio y el inicio del siguiente sin forzar saltos de página innecesarios.
    - **Clasificaciones y Subseries por Estudio**: Bajo cada título de estudio se despliegan sus respectivas series (`SERIE ROJA`, `SERIE BLANCA`, `EXAMEN FÍSICO-QUÍMICO`, `SEDIMENTO MICROSCÓPICO`, etc.) con sus tablas y valores de referencia.
  - **Jerarquía Tipográfica Unificada (Texto Libre y Tabulares)**:
    - Los títulos del examen (`examTitle`) y las cabeceras de subgrupo (`groupTitle`) conservan tipografía destacada en negrita (`FontWeight.bold`).
    - Las etiquetas de parámetros de texto libre (`dataType: 'text'`) se renderizan con tipografía estándar (`FontWeight.normal`), alineadas visualmente con los parámetros tabulares normales para no confundirse con subtítulos o secciones mayores. El texto multilínea se encuadra en una caja clara con borde atenuado y criterio de referencia inferior en itálica discreta.
  - Alertas clínicas discretas `H` / `L` en rojo al rebasar límites biológicos de referencia.
  - **Firma y Sello de Validación Clínica**:
    - Disposición vertical secuencial: el sello del bioanalista representante se posiciona en el espacio superior a la línea de firma con una rotación realista de -5° (`-0.087 rad`), tolerando imágenes con fondo blanco o transparencia PNG sin tapar textos ni líneas.
    - Línea continua divisoria de firma inmediatamente bajo el sello.
    - Datos del profesional: nombre en negrita, título/cargo y registro oficial MINSA.
    - Si la sucursal no cuenta con sello digital configurado, se reserva un espacio en blanco de 48 px para firma física manuscrita y sellado en papel.
  - **Optimización Vertical y Paginación**:
    - Se prescinde de recuadros o notas legales aclaratorias extensas para asegurar que el informe entre limpiamente en una sola página sin desbordes.
    - En el pie de página institucional se renderiza la paginación oficial en negrita (`Página X de Y`) junto a los canales de contacto de la sede.
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

### G. Optimización de Apertura Rápida de Formularios (Catálogo en Memoria)
- `CreateOrderScreen` consume el catálogo provisto globalmente por `ProviderContainer` (`ReadLabTestCubit`).
- Al abrir la pantalla de crear orden, se invoca `loadIfNotLoaded`: si el catálogo ya fue cargado previamente, no se realizan llamadas de red redundantes, mostrando el catálogo de inmediato sin pantallas de carga.

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


