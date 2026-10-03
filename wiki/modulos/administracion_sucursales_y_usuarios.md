---
type: doc
title: Módulo de Administración — Hub, Sucursales y Usuarios
description: Documentación funcional del centro de administración, submenú en cuadrícula responsiva y consolas de gestión en pantalla completa para sucursales y colaboradores.
tags: [frontend, admin, branches, users, security, roles, permissions]
timestamp: 2026-10-03T16:25:00Z
---

# ⚙️ Módulo de Administración, Sucursales y Usuarios

El módulo de **Administración** actúa como la consola central de configuración de infraestructura, sedes clínicas y personal autorizado de la clínica/laboratorio en Serum LIS.

---

## 🏛️ 1. Arquitectura y Enrutamiento

El módulo combina dos patrones de navegación mediante `go_router`:
1. **Hub Central en el Shell Lateral (`/admin`)**:
   - Integrado en el menú principal (`HomeMenusScreen`) como el Branch 8 (`_adminNavKey`).
   - Permite que el operador acceda a las áreas de configuración manteniendo siempre visible la barra lateral.
2. **Consolas en Pantalla Completa (`/admin/branches` y `/admin/users`)**:
   - Ambas pantallas están configuradas a nivel de raíz con `parentNavigatorKey: _rootNavigatorKey`.
   - Ocultan temporalmente el menú lateral para brindar máxima ergonomía, espacio de visualización de tablas/listados y foco operativo.
   - Cada consola cuenta con su AppBar superior que incluye botón de retroceso (`Icons.arrow_back` ejecutando `context.pop()`) para regresar instantáneamente al Hub de Administración.

```
┌──────────────────────────────────────────────────────────────┐
│ Shell Principal (/admin)                                     │
│ ┌───────────────┬──────────────────────────────────────────┐ │
│ │ Menú Lateral  │ Hub de Administración (Grid de Tarjetas)  │ │
│ │ • Dashboard   │ ┌────────────────┐ ┌────────────────┐    │ │
│ │ • Pacientes   │ │  [Sucursales]  │ │   [Usuarios]   │    │ │
│ │ • ...         │ └───────┬────────┘ └────────┬───────┘    │ │
│ │ • Admin       │         │ (clic)            │ (clic)     │ │
│ └───────────────┴─────────┼───────────────────┼────────────┘ │
└───────────────────────────┼───────────────────┼────────────┘ │
                            ▼                   ▼
     ┌─────────────────────────────┐    ┌─────────────────────────────┐
     │ Full Screen (_rootNavigator)│    │ Full Screen (_rootNavigator)│
     │ /admin/branches             │    │ /admin/users                │
     │ ◄ Volver a Administración   │    │ ◄ Volver a Administración   │
     │ [CRUD Sucursales Completo]  │    │ [CRUD Usuarios Completo]    │
     └─────────────────────────────┘    └─────────────────────────────┘
```

---

## 🎛️ 2. Hub Central (`administration`)

* **Ubicación**: `lib/src/modules/administration/`
* **Vistas**: `view/administration_screen.dart`
* **Widgets**: `widgets/admin_module_card.dart`
* **Funcionalidad**:
  - Despliega un encabezado con título institucional y subtítulo descriptivo.
  - Maqueta un layout responsivo en cuadrícula (`GridView.extent` con `maxCrossAxisExtent: 420`) que organiza tarjetas de módulos (`AdminModuleCard`).
  - **`AdminModuleCard`**: Componente visual interactivo con animación al pasar el cursor (`MouseRegion`), contenedor tonal con icono grande, título en negrita, descripción de funciones, badge descriptivo ("Sedes Físicas", "Personal") y flecha con microanimación de traslación hacia la derecha.
  - Diseñado de manera extensible para incorporar fácilmente futuros submódulos (auditoría, roles personalizados, configuración general de facturación, etc.).

---

## 🏬 3. Consola de Sucursales (`branch`)

* **Ubicación**: `lib/src/modules/branch/`
* **Vistas**: `view/branch_screen.dart`
* **Widgets**: `widgets/branches_list.dart`, `widgets/branch_form_dialog.dart`
* **Cubits Asociados**: `ReadBranchCubit`, `WriteBranchCubit`
* **Funciones Clave**:
  1. **Supervisión de Sedes**: Tarjetas estilizadas en `BranchesList` con nombre, dirección completa, teléfono y distinción especial mediante badge temático para la sede matriz (`ORIGIN_BRANCH`).
  2. **Búsqueda en Tiempo Real**: Filtrado dinámico y sin peticiones innecesarias de red por nombre de sede, calle o teléfono.
  3. **Registro y Edición (`BranchFormDialog`)**: Formulario modal con validación estricta de campos obligatorios (nombre, dirección y teléfono de contacto).
  4. **Eliminación Segura**: Diálogo modal de confirmación con alerta visual roja antes de invocar `WriteBranchCubit.delete()`, con protección para impedir la eliminación accidental de la sede matriz inicial.

---

## 👥 4. Consola de Usuarios y Accesos (`user`)

* **Ubicación**: `lib/src/modules/user/`
* **Vistas**: `view/user_screen.dart`
* **Widgets**: `widgets/users_list.dart`, `widgets/user_form_dialog.dart`
* **Cubits Asociados**: `ReadUserCubit`, `WriteUserCubit`, `ReadBranchCubit`
* **Funciones Clave**:
  1. **Directorio de Personal**: Listado en `UsersList` con avatar de iniciales, nombre, identificador (`@username`), badges cromáticos según el rol asignado (`Admin`, `Cashier`, `Bioanalyst`, `Doctor`), badge de estado (`Activo` en verde / `Inactivo` en gris) y chips con las sedes donde el colaborador tiene autorización para operar.
  2. **Búsqueda Multicriterio**: Buscador en tiempo real que evalúa nombre completo, nombre de usuario, rol operativo y correo electrónico.
  3. **Gestión de Credenciales y Formulario (`UserFormDialog`)**:
     - Nombre completo y nombre de usuario.
     - Contraseña con alternador de visibilidad (`obscureText`): obligatoria al crear un nuevo usuario y opcional al editar (permite conservar la actual o definir una nueva).
     - Selección de rol operativo mediante Dropdown tipado.
     - Correo y teléfono de contacto opcionales.
     - Switch interactivo para activar o suspender el acceso del usuario (`isActive`).
     - **Asignación Múltiple de Sucursales**: Chips interactivos (`FilterChip`) alimentados dinámicamente desde `ReadBranchCubit`, exigiendo la vinculación obligatoria de al menos una sede operativa.
  4. **Protección del Usuario Root**: Se inhabilita la opción de borrado para el usuario administrador fundamental (`root` / `Serum`) para garantizar la persistencia del acceso administrativo al sistema.
