---
title: Módulos — Autenticación, Sesión y Navegación
description: Especificación funcional de los módulos splash, auth, selección de caja y shell de navegación.
tags: [auth, session, splash, navigation, cash_register_selection]
timestamp: 2026-09-28T19:46:00Z
---

# 🔐 Autenticación, Sesión y Navegación

Esta sección documenta el flujo de acceso, seguridad del cliente, selección de terminal de cobro y navegación general.

---

## 1. Módulo `splash` (`lib/src/modules/splash/`)
- **Pantalla**: `SplashScreen` (`view/splash_screen.dart`).
- **Cubit**: `AppSessionCubit`.
- **Propósito y Funcionalidad**:
  - Se ejecuta como pantalla inicial (`/splash`).
  - Llama a `AppSessionCubit.initSession()`.
  - Lee los tokens almacenados en `HiveTokenStorage` (cifrado AES-256).
  - Si el token está por expirar en menos de 10 minutos, solicita refresco automático a la API.
  - Comprueba la validez del usuario contra `/auth/check-user`.
  - Redirige mediante los guards de `GoRouter`:
    - Sesión inválida / expirada ➔ `/login`.
    - Sesión válida sin caja seleccionada ➔ `/select-cash-register`.
    - Sesión válida con caja activa ➔ `/` (Dashboard).

---

## 2. Módulo `auth` (`lib/src/modules/auth/`)
- **Pantalla**: `LoginScreen` (`view/login_screen.dart`).
- **Cubits**: `AppSessionCubit`, `WriteUserCubit`.
- **Propósito y Funcionalidad**:
  - Captura credenciales (`username`, `password`) con validación de formularios en tiempo real.
  - Ejecuta `appSessionCubit.login(username, password)`.
  - Almacena el `sessionToken` y `refreshToken` en Hive.
  - Despliega estados de carga y retroalimentación de error mediante SnackBar accesible y seguro.

---

## 3. Módulo `cash_register_selection` (`lib/src/modules/cash_register_selection/`)
- **Pantalla**: `SelectCashRegisterScreen` (`view/select_cash_register_screen.dart`).
- **Cubits**: `ReadCashRegisterCubit`, `AppSessionCubit`.
- **Propósito y Funcionalidad**:
  - Consulta las cajas registradoras existentes para la sucursal del operador.
  - Presenta tarjetas interactivas indicando el nombre de la caja, estado (Abierta / Cerrada) y saldo actual.
  - Al seleccionar una caja, ejecuta `appSessionCubit.setActiveCashRegister(cashRegister)`.
  - Los guards de `GoRouter` detectan la asignación y permiten el paso automático al POS (`/`).

---

## 4. Módulo `home_menu` y Shell Lateral
- **Vista**: `HomeMenusView` (`lib/src/modules/home_menu/home_menus_view.dart`).
- **Estructura**: `StatefulNavigationShell` de `go_router`.
- **Propósito y Funcionalidad**:
  - Implementa navegación por ramas independientes (`IndexedStack`), preservando el estado de scroll y datos en cada pestaña.
  - Barra lateral con íconos de acceso a Dashboard, Pacientes, Médicos, Pruebas, Órdenes, Cotizaciones, Cajas y Kardex.
  - Footer de sesión permanente mostrando:
    - Nombre del usuario conectado y su rol.
    - Caja registradora en uso con balance.
    - Botón para cambiar de caja operativa.
    - Botón de cierre de sesión seguro (`appSessionCubit.logout()`).
