---
title: Arquitectura — Flujo de Capas y Ciclo de Datos
description: Detalle del flujo unidireccional de datos en la aplicación Flutter y serum_business.
tags: [architecture, layers, data_flow, flutter, dart]
timestamp: 2026-09-28T19:46:00Z
---

# 🏛️ Flujo de Capas y Ciclo de Datos

La aplicación implementa un patrón estricto y desacoplado de capas unidireccionales que separa la presentación en Flutter de la lógica de negocio pura en `serum_business`:

```
[ View (UI / Screen / Dialog) ]
             ↕️ Escucha estados / Dispara métodos
[ Cubit (Read / Write / Search / Session) ]
             ↕️ Retorna modelos tipados / Notifica reactividad
[ Repository (serum_business / ReactiveRepository) ]
             ↕️ Llama con parámetros / Retorna JSON tipado
[ DataSource (serum_business / Endpoints) ]
             ↕️ Envía peticiones / Retorna payload
[ Services (HttpService / HiveTokenStorage / Secure Storage) ]
```

---

## 1. Responsabilidades por Capa

### A. Vista (UI / Widgets / Dialogs)
- **Ubicación**: `lib/src/modules/<modulo>/view/` y `lib/src/modules/<modulo>/widgets/`.
- **Regla**: Componentes puros de presentación. No contienen lógica de negocio ni llamadas HTTP.
- **Acceso a Cubits**: Consumen cubits mediante `context.read<MiCubit>()` para disparar acciones o `BlocBuilder<MiCubit, MiEstado>` para pintar la interfaz.

### B. Gestores de Estado (Cubits)
- **Ubicación**: `lib/src/cubits/<modulo>_cubit/`.
- **Clasificación Estándar**:
  - `Read<Entity>Cubit`: Carga inicial (`getAll()`), refresco discreto con estado `Refreshing` e inserción en caché reactiva.
  - `Write<Entity>Cubit`: Mutaciones (`create`, `update`, `delete`), emite estados de éxito o error con mensajes de retroalimentación amigables.
  - `Search<Entity>Cubit`: Búsqueda instantánea con control de debounce.
  - `AppSessionCubit`: Control global de tokens, usuario conectado y caja registradora activa.

### C. Repositorios (`Repositories`)
- **Ubicación**: `packages/serum_business/lib/src/domain/repositories/`.
- **Responsabilidad**: Mapea payloads JSON a modelos de datos Dart inmutables (`fromJson`), implementa caché en memoria (`List<T> _items`) y notifica cambios en tiempo real mezclando el mixin `ReactiveRepository<T>`.

### D. Fuentes de Datos (`DataSources`)
- **Ubicación**: `packages/serum_business/lib/src/data/`.
- **Responsabilidad**: Encapsula las URLs de endpoints, verbos HTTP y serialización de parámetros a `Map<String, dynamic>`. No realiza conversión a modelos de dominio.

### E. Servicios e Infraestructura (`Services`)
- **Ubicación**: `packages/serum_business/lib/src/services/`.
- **Responsabilidad**:
  - `HttpService`: Cliente HTTP centralizado que inyecta headers de autorización (`Bearer <token>`) automáticamente.
  - `HiveTokenStorage`: Manejo de base de datos Hive cifrada con AES-256 para persistir tokens de sesión y refresh de forma 100% multiplataforma.
