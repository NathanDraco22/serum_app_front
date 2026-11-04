---
title: Módulos — Pruebas de Laboratorio y Packs
description: Especificación funcional del catálogo unificado de análisis clínicos individuales y paquetes comerciales.
tags: [lab_tests, packs, clinical, catalog, ui]
timestamp: 2026-09-28T19:46:00Z
---

# 🧪 Pruebas de Laboratorio y Packs (`lab_test`)

El módulo `lab_test` (`lib/src/modules/lab_test/`) gestiona el catálogo unificado de análisis clínicos. Soporta tanto análisis individuales como paquetes comerciales compuestos.

---

## 1. Estructura de Pantalla y Componentes
- **Pantalla**: `LabTestsScreen` (`view/lab_test_screen.dart`), `LabTestFormScreen` (`view/lab_test_form_screen.dart`).
- **Widgets Clave**:
  - `LabTestsList` (`widgets/lab_tests_list.dart`): Muestra las pruebas o paquetes con badges indicativos (`PACK`, `INDIVIDUAL`, `PARÁMETRO`), categoría clínica, subclasificación, código y precio en moneda legible.
  - `LabTestDetailDialog` (`widgets/lab_test_detail_dialog.dart`): Visor modal amplio para inspeccionar parámetros de referencia, metodología, subclasificación y lista de análisis incluidos si es un paquete.
  - `LabTestFormScreen` (`view/lab_test_form_screen.dart`): Formulario declarativo y modular estructurado según el patrón **ViewController + Mediator** (OKF v0.2), desacoplado en subsecciones limpias (`widgets/sections/`).
  - `LabTestFormViewController` (`controllers/lab_test_form_view_controller.dart`): `ChangeNotifier` que encapsula el 100% del estado efímero del formulario, los controladores `TextEditingController` con su ciclo de vida y `dispose()`, cálculos financieros automáticos de packs y generación validada de DTOs (`CreateLabTest`, `UpdateLabTest`).
  - `LabTestFormMediator` (`controllers/lab_test_form_mediator.dart`): `InheritedWidget` mudo (`updateShouldNotify: false`) para exponer el controlador a lo largo del árbol sin prop-drilling ni redibujados globales.
  - `QuickCreateParameterDialog` (`widgets/quick_create_parameter_dialog.dart`): Diálogo modal ligero para registrar parámetros técnicos directamente dentro de un perfil en edición sin salir al catálogo comercial.
  - `PackTestSelector` (`widgets/pack_test_selector.dart`): Selector clínico ordenado alfabéticamente (A-Z) para configurar los análisis de un pack con comparador de precios y visor de subseries.
  - `ClinicalClassificationRegistry` (`widgets/clinical_classification_registry.dart`): Catálogo unificado de especialidades médicas (*Hematología*, *Química Sanguínea*, *Uroanálisis*, *Coprología*, etc.) y subseries mapeadas en cascada con soporte de personalización (+ Otra...).
- **Cubits**:
  - `ReadLabTestCubit`: Estado de catálogo general.
  - `WriteLabTestCubit`: Creación y actualización de análisis/packs.
  - `SearchLabTestsCubit`: Búsqueda reactiva de análisis.

---

## 2. Funcionalidades Detalladas

### A. Soporte para Packs Comerciales y Creación Rápida de Parámetros
- Al marcar `isPack = true`, la interfaz habilita el selector `PackTestSelector` y el interruptor **"Usar la sumatoria de los precios de las pruebas que contiene"** (`useChildTestsPriceSum`, activo por defecto).
- **Sumatoria Automática (`useChildTestsPriceSum = true`)**: El precio de venta del pack se sincroniza reactivamente con la suma de precios de las pruebas seleccionadas, manteniendo el campo de texto en solo lectura.
- **Tarifa Fija Personalizada (`useChildTestsPriceSum = false`)**: Se habilita la captura manual del precio, aplicando validación estricta de que el valor sea mayor a 0 ($> 0$).
- **Creación Directa de Parámetros en el Perfil**:
  - En la cabecera de pruebas hijas del formulario de packs, el botón *"Crear Parámetro en este Perfil"* permite dar de alta parámetros (ej. *Color*, *Aspecto*, *pH* de un EGO) sin salir de la pantalla.
  - El parámetro se etiqueta automáticamente con `isProfileParameter = true`, hereda la categoría/subclasificación del perfil y se vincula de inmediato a `childTestIds`.
- **Comparador de Precios**: Calcula la suma de precios individuales de las pruebas seleccionadas vs el precio que se definirá para el paquete, mostrando ahorros o descuentos porcentuales si se fijó un precio personalizado.

### B. Mitigación de Ruido Visual en el Catálogo (`isProfileParameter`)
- Los parámetros internos de perfiles no saturan la lista de venta comercial en caja ni el catálogo general.
- En `LabTestsScreen`, el filtro **"Ocultar parámetros de perfil"** permanece activo por defecto.
- Los parámetros cuentan con un badge `PARÁMETRO` y pueden consultarse filtrando por el tipo *"Parámetros de Perfiles"*.

### C. Doble Dropdown en Cascada para Filtrar el Catálogo
En lugar de una lista horizontal de chips con desplazamiento lateral, `LabTestsScreen` implementa dos selectores desplegables:
1. **Clasificación General**: Carga *"Todas las clasificaciones"* más las especialidades clínicas estándar (`ClinicalClassificationRegistry`) y las categorías existentes en la base de datos ordenadas de la A a la Z.
2. **Subclasificación**: Se actualiza de forma reactiva desplegando las subseries de la clasificación seleccionada (*Serie Roja*, *Serie Blanca*, *Físico-Químico*, etc.). Si se cambia la clasificación general, la subclasificación se reinicia automáticamente a *"Todas"*.
3. **Botón "Limpiar filtros"**: Acción en 1-tap visible cuando algún filtro de categoría o subclasificación está activo para regresar al catálogo global.

### D. Definición de Valores de Referencia
El diálogo permite configurar los tipos de resultados admitidos para cada análisis:
1. **Numérico**: Con rangos mínimos y máximos clasificados por género (`male`, `female`, `both`) y grupos de edad.
2. **Cualitativo**: Lista de opciones predefinidas (ej. "Negativo", "Positivo", "Indeterminado").
3. **Texto Libre**: Para reportes patológicos o interpretaciones descriptivas.

### E. Orden Alfabético Estricto (A-Z)
Todas las listas de pruebas, categorías, subclasificaciones y selectores de perfiles se ordenan alfabéticamente (A-Z) garantizando rapidez y predictibilidad al buscar estudios.

### F. Optimización de Ciclo de Vida Global y Botón de Refrescar
1. **Alcance Global en `ProviderContainer`**: `ReadLabTestCubit` reside en `GlobalCubitProvider` bajo el scope de la sucursal activa (`branch_scope_$branchId`). Se instancia una única vez y se mantiene reactivamente sincronizado mediante el stream de eventos del repositorio (`labTestsRepository.eventStream`).
2. **Carga Condicional con `loadIfNotLoaded`**: Los módulos de Crear Orden y Crear Cotización ya no re-instancian cubits ni disparan llamadas HTTP innecesarias; si el catálogo ya está en `ReadLabTestSuccess`, se utiliza de inmediato en memoria (0 ms de retardo).
3. **Botón de Refrescar en `LabTestsScreen`**: Ubicado en la barra de acciones superior (`Icons.refresh_rounded`, tooltip *"Actualizar catálogo"*). Permite forzar la recarga manual (`getAll()`) emitiendo `ReadLabTestRefreshing` con un indicador circular sutil sin desmontar la interfaz.

### G. Sección Superior de Parámetros Seleccionados, Reordenamiento y Edición en Caliente (Lápiz ✏️)
Para resolver la dificultad al editar perfiles complejos con múltiples parámetros técnicos:
1. **Sección Superior de Seleccionados en `PackTestSelector`**:
   - Ubicada directamente arriba del buscador de catálogo general.
   - Muestra el listado ordenado de análisis y parámetros actualmente asignados al perfil con su contador dinámico.
   - Cada fila visualiza: handle de arrastre (`Icons.drag_indicator_rounded`), botones de flechas subir/bajar (`Icons.arrow_drop_up_rounded`, `Icons.arrow_drop_down_rounded`), número secuencial dinámico, nombre, código, badge `PARÁMETRO` si aplica, y resumen clínico de valores de referencia (ej. `Ref: 70 - 100 mg/dL`, `Cualitativo [Esperado: Negativo]`, o texto libre).
2. **Reordenamiento Dinámico (Drag & Drop y Flechas ▲▼)**:
   - Implementado con `ReorderableListView.builder` y `onReorderItem`.
   - Permite arrastrar libremente cualquier parámetro a una nueva posición o pulsar las flechas ▲/▼ para subirlo o bajarlo en 1-tap.
   - La numeración secuencial (`1.`, `2.`, `3.`) se actualiza reactivamente y el orden exacto de `childTestIds` se persiste en la base de datos para la generación de órdenes clínicas y reportes analíticos.
3. **Edición Directa en Caliente (Botón Lápiz ✏️)**:
   - Al tocar el lápiz de cualquier parámetro, se abre `QuickCreateParameterDialog.showEdit(...)` precargado con sus datos actuales.
   - Permite modificar nombre, código, clasificación, subclasificación, unidad de medida, valores de referencia numéricos mínimos y máximos, o listas cualitativas con selector desplegable (dropdown) de valor esperado y notas de referencia explicativas universales.
   - Al guardar, actualiza el análisis en la base de datos vía `repo.updateLabTestById`, sincroniza el catálogo y recalcula el precio del perfil sin abandonar ni reiniciar el formulario.
4. **Deselección Rápida (Botón ✕)**:
   - Permite desvincular un parámetro del perfil en 1-tap sin tener que navegar por el catálogo inferior.
5. **Catálogo Inferior Independiente**:
   - Mantiene la barra de búsqueda por texto, chips de categorías y la lista de selección con checkboxes para agregar pruebas adicionales.

### H. Diálogo Rápido de Parámetros (`QuickCreateParameterDialog`)
Permite crear o editar parámetros técnicos de forma ágil dentro de un perfil:
1. **Notas de Referencia Universales (`referenceText`)**: Disponibles para todos los tipos de resultado (Numérico, Cualitativo y Texto Libre), permitiendo ingresar escalas clínicas explicativas multilínea que se reflejan de inmediato en órdenes y reportes PDF.
2. **Selector Desplegable (Dropdown) de Valor Esperado**: En tipo Cualitativo, el valor normal/esperado se selecciona mediante un dropdown reactivo (`DropdownButtonFormField`) alimentado por las opciones capturadas o las plantillas rápidas (evitando errores tipográficos), con alerta automática si se reciben resultados distintos.

---

## 3. Arquitectura del Formulario: ViewController + Mediator (OKF v0.2)

El formulario `LabTestFormScreen` fue refactorizado siguiendo el estándar OKF v0.2 para eliminar la sobrecarga del estado monolítico previo de ~1,400 líneas:

1. **Controlador Centralizado (`LabTestFormViewController`)**:
   - Implementado como `ChangeNotifier` puro, totalmente independiente de `BuildContext` y de widgets visuales.
   - Centraliza 17+ variables de estado efímero y 10 `TextEditingController` con manejo seguro de su ciclo de vida y liberación en `dispose()`.
   - Cálculos matemáticos y reactivos en memoria: `calculateChildrenSum` y `updateCalculatedPrice` para packs comerciales.
   - Generación desacoplada y validada de DTOs de dominio: `generateCreateDto({required String branchId})` y `generateUpdateDto({required String branchId})`.

2. **Mediador Inmutable (`LabTestFormMediator`)**:
   - `InheritedWidget` mudo con `updateShouldNotify(old) => false`.
   - Expone `LabTestFormMediator.of(context)` y `LabTestFormMediator.controllerOf(context)` eliminando el prop-drilling hacia subcomponentes.

3. **Modularización en 4 Subsecciones Especializadas (`widgets/sections/`)**:
   - `LabTestGeneralInfoSection`: Modalidad (Individual vs Pack), Nombre, Código, Clasificación General y Subclasificación con opción de personalización.
   - `LabTestPricingSection`: Precios comerciales (Nivel 1 Público y Nivel 2 Convenios/Aseguradoras), switch para alternar sumatoria automática de pruebas hijas vs tarifa fija manual.
   - `LabTestReferenceValuesSection`: Configuración técnica para análisis individuales (Numérico con unidades y tabla de rangos por edad/género, Cualitativo con plantillas y dropdown de valor esperado, Texto Libre y escalas explicativas multilínea).
   - `LabTestPackChildrenSection`: Selección de análisis incluidos en packs con integración de `PackTestSelector` y callbacks para creación/edición rápida en caliente.

4. **Pantalla Delgada (`LabTestFormScreen`)**:
   - Reducida de ~1,400 líneas a ~190 líneas de código conciso y declarativo.
   - Gestiona únicamente la instanciación/desecho del controlador (`initState`/`dispose`), escucha eventos de persistencia (`BlocListener<WriteLabTestCubit, WriteLabTestState>`), y orquesta los modales de creación rápida.
