---
type: index
title: Frontend — Arquitectura y Flujo de Datos
description: Documentación de la arquitectura interna de la aplicación Flutter y flujo de capas.
tags: [architecture, layers, flutter, cubit, reactive]
timestamp: 2026-09-28T19:46:00Z
---

# 🏛️ Arquitectura del Frontend y Flujo de Capas

En este directorio se documenta el diseño arquitectónico de `serum_app_front` y la integración con el paquete de negocio `serum_business`.

---

## 📑 Documentos

| Documento | Descripción |
| :--- | :--- |
| **[Flujo de Capas (flujo_de_capas.md)](flujo_de_capas.md)** | Desglose paso a paso del ciclo de vida de los datos: View ➔ Cubit ➔ Repository ➔ DataSource ➔ Services. |
| **[Patrón ViewController + Mediator (view_controller_mediator.md)](view_controller_mediator.md)** | Estándar OKF v0.2 para pantallas complejas con estado efímero, eliminación de prop-drilling y generación de DTOs. |
| **[Formatter Global con Resolver Inyectado](/wiki/convenciones/global-formatter-resolver.md)** | Moneda global resuelta por callback desde `AppSettingsCubit`; formatters puros sin dependencias del frontend. |
