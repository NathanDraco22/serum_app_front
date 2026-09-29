# AGENTS.md — Instrucciones Obligatorias para Agentes de IA (Frontend)

Este archivo establece las directrices que **todo agente de IA o desarrollador DEBE cumplir estrictamente** antes de analizar, planificar o realizar cambios en el frontend (`serum_app_front` y `serum_business`).

---

## 🚨 Regla de Oro: Consulta Obligatoria de `project_index.md`

**Antes de proponer cualquier cambio de código, responder preguntas de arquitectura o modificar cualquier archivo en `serum_app_front` o `serum_business`:**

1. **Consulta `project_index.md` como mapa rector**:
   Debes leer [project_index.md](project_index.md) para ubicar en qué módulo, capa, vista o cubit reside la funcionalidad requerida, cuáles son sus widgets asociados y cómo interactúan las capas.

2. **Verificación de Módulos Funcionales**:
   Antes de editar pantallas, diálogos o cubits, revisa la sección del módulo correspondiente en [modulos/](modulos/INDEX.md):
   - Flujo de sesión y guardias: Lee [modulos/auth_y_sesion.md](modulos/auth_y_sesion.md).
   - Catálogos demográficos: Lee [modulos/pacientes_y_doctores.md](modulos/pacientes_y_doctores.md).
   - Pruebas clínicas y paquetes: Lee [modulos/lab_tests_y_packs.md](modulos/lab_tests_y_packs.md).
   - Flujo clínico y pagos: Lee [modulos/ordenes_y_resultados.md](modulos/ordenes_y_resultados.md).
   - Cotizaciones comerciales: Lee [modulos/cotizaciones.md](modulos/cotizaciones.md).
   - Control de caja y Kardex: Lee [modulos/cajas_y_kardex.md](modulos/cajas_y_kardex.md).

3. **Arquitectura y Flujo Unidireccional**:
   Consulta [arquitectura/flujo_de_capas.md](arquitectura/flujo_de_capas.md). **Jamás** invoques llamadas HTTP directas desde widgets o cubits; toda interacción remota pasa por `Repository` ➔ `DataSource` ➔ `HttpService`.

---

## 🛠️ Normas de Trabajo y Comandos CLI `onion`

Para generar nuevas entidades, cubits o módulos completos en el cliente Flutter, utiliza las herramientas CLI oficiales:
- Generar capa de datos (Modelos, DataSource y Repository):
  ```bash
  onion dart <entity>
  ```
- Generar Cubits (`Read` y `Write` con estados `Refreshing` y jerarquía BLoC):
  ```bash
  onion dart-cubit <entity>
  ```
- Generar módulo Flutter completo (`view/`, `widgets/`, `cubit/`):
  ```bash
  onion flutter-module <entity>
  ```

---

## 🧪 Verificación Posterior a Cambios de Código

Tras modificar cualquier archivo en `serum_app_front` o `serum_business`, ejecuta siempre la suite de análisis estático:

```powershell
flutter analyze
```

*(Ambos proyectos deben reportar 0 errores y 0 warnings antes de dar por terminada una tarea).*
