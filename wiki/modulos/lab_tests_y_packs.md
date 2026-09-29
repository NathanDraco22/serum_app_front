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
- **Pantalla**: `LabTestScreen` (`view/lab_test_screen.dart`).
- **Widgets Clave**:
  - `LabTestsList` (`widgets/lab_tests_list.dart`): Muestra las pruebas o paquetes con badges indicativos (`Pack` vs `Individual`), categoría clínica, código y precio en moneda legible.
  - `LabTestDetailDialog` (`widgets/lab_test_detail_dialog.dart`): Visor modal amplio para inspeccionar parámetros de referencia, metodología y lista de análisis incluidos si es un paquete.
  - `LabTestFormDialog` (`widgets/lab_test_form_dialog.dart`): Formulario estructurado para crear o editar pruebas y paquetes.
  - `PackTestSelector` (`widgets/pack_test_selector.dart`): Selector clínico para configurar los análisis de un pack.
- **Cubits**:
  - `ReadLabTestCubit`: Estado de catálogo general.
  - `WriteLabTestCubit`: Creación y actualización de análisis/packs.
  - `SearchLabTestsCubit`: Búsqueda reactiva de análisis.

---

## 2. Funcionalidades Detalladas

### A. Soporte para Packs Comerciales
- Al marcar `isPack = true`, la interfaz habilita el selector `PackTestSelector`.
- Permite buscar análisis individuales en tiempo real y agregarlos al paquete.
- **Comparador de Precios**: Calcula la suma de precios individuales de las pruebas seleccionadas vs el precio que se definirá para el paquete, permitiendo al administrador diseñar ofertas atractivas.

### B. Definición de Valores de Referencia
El diálogo permite configurar los tipos de resultados admitidos para cada análisis:
1. **Numérico**: Con rangos mínimos y máximos clasificados por género (`male`, `female`, `both`) y grupos de edad.
2. **Cualitativo**: Lista de opciones predefinidas (ej. "Negativo", "Positivo", "Indeterminado").
3. **Texto Libre**: Para reportes patológicos o interpretaciones descriptivas.

### C. Filtros Multidimensionales
La vista principal incorpora botones de filtro rápido:
- **Todos**: Todo el catálogo disponible.
- **Individuales**: Solo análisis simples.
- **Packs**: Solo perfiles comerciales.
- **Por Categoría**: Filtro desplegable por especialidad (Hematología, Bioquímica, Inmunología, etc.).
