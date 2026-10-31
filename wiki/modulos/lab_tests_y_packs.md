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
  - `LabTestFormScreen` (`view/lab_test_form_screen.dart`): Formulario estructurado para crear o editar pruebas y paquetes con doble selector desplegable en cascada (Clasificación y Subclasificación).
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
