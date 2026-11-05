---
title: Módulos — Control de Turnos de Caja (CashShift) y Kardex Financiero
description: Especificación funcional de los módulos cash_shift, cash_movement y cash_transaction para apertura, arqueos, cierres, movimientos y auditoría de flujo de dinero multi-sucursal.
tags: [cash_shift, cash_movement, cash_transaction, kardex, accounting, pos, ui, multi_tenant]
timestamp: 2026-11-05T09:25:00Z
---

# 💵 Turnos de Caja (`CashShift`) y Kardex Financiero

Esta sección aborda la gestión de los turnos de trabajo por custodio bajo la premisa **"La Persona es la Caja"**, los movimientos libres de efectivo, y el libro mayor inmutable de auditoría contable.

---

## 1. Módulo `cash_shift` (`lib/src/modules/cash_shift/`)
- **Pantalla**: `CashShiftsScreen` (`view/cash_shifts_screen.dart`).
- **Widgets y Diálogos Clave**:
  - `CashShiftOpenDialog` (`widgets/cash_shift_open_dialog.dart`): Formulario de apertura de turno capturando el fondo inicial en efectivo (`initialBalance`). Si el usuario ya cuenta con un turno abierto, bloquea el formulario y muestra la tarjeta informativa *"Turno Ya Abierto"*.
  - `CashShiftCloseDialog` (`widgets/cash_shift_close_dialog.dart`): Modal de arqueo y corte de turno. Calcula automáticamente diferencias contra el efectivo contado físicamente (`declaredCash`) y desglosa transferencias por banco.
  - `CashShiftViewerDialog` (`widgets/dialogs/viewers/cash_shift_viewer.dart`): Visor interactivo y exportación a PDF del arqueo de turno.
  - `CashMovementsListDialog` (`widgets/cash_movements_list_dialog.dart`): Historial de entradas (`income`) y salidas (`withdrawal`) extraordinarias asociadas al turno.
  - `CashMovementDialog` (`widgets/cash_movement_dialog.dart`): Registro de un movimiento libre de fondos.
- **Cubits**:
  - `ReadCashShiftCubit`: Consulta del listado histórico de turnos con filtros (`all`, `open`, `closed`).
  - `WriteCashShiftCubit`: Ejecución de aperturas (`openShift`) y cortes de arqueo (`closeShift`).
  - `ReadCashMovementCubit` & `WriteCashMovementCubit`: Lectura y creación de movimientos libres de caja.

---

## 2. Módulo `cash_transaction` (`lib/src/modules/cash_transaction/`)
- **Pantalla**: `CashTransactionScreen` (`view/cash_transaction_screen.dart`).
- **Widgets Clave**:
  - `CashTransactionList` (`widgets/cash_transaction_list.dart`): Listado ordenado cronológicamente de transacciones.
- **Cubits**:
  - `ReadCashTransactionCubit`: Consulta de transacciones filtradas por sucursal y turno de caja.
- **Funcionalidades Clave**:
  1. **Auditoría Inmutable (Solo Lectura)**: Asientos contables de solo lectura. Todo movimiento queda permanentemente registrado.
  2. **Tipos de Transacciones Desglosadas**:
     - `opening`: Apertura de turno con fondo inicial (Sentido: `in`).
     - `payment`: Cobro asociado a una orden médica (Sentido: `in`, referencia: `orderId`).
     - `income`: Ingreso extraordinario libre (Sentido: `in`).
     - `withdrawal`: Egreso o retiro por gasto (Sentido: `out`).
     - `closing`: Cierre de turno y arqueo final (Sentido: `out`).
  3. **Visualización de Balances**: Muestra claramente si la transacción afectó efectivo, tarjeta o transferencia bancaria, estampando el saldo total resultante (`resultingBalance`).

---

## 3. Control Multi-Sucursal y Discrepancia de Turno (`Shift Branch Mismatch`)

Para garantizar la integridad del dinero y evitar que los cobros o movimientos se apliquen en una sucursal equivocada mientras el custodio navega en otra sede:

### 3.1 Getters Semánticos en Sesión (`AppSessionState` y `AppSessionCubit`)
- `hasActiveShift`: Indica si el custodio tiene un turno abierto en el sistema (`activeShift != null`).
- `isShiftInCurrentBranch`: `true` si el turno activo pertenece exactamente a la sucursal actual de la sesión (`activeShift.branchId == currentBranch.id`).
- `hasShiftBranchMismatch`: `true` si el custodio tiene un turno abierto, pero está navegando en una sucursal distinta (`activeShift.branchId != currentBranch.id`).

### 3.2 Comportamiento Visual y Restricciones Operativas

| Componente | Comportamiento ante Discrepancia (`hasShiftBranchMismatch = true`) |
| :--- | :--- |
| **`CashShiftsScreen`** | Muestra un **Banner superior de advertencia (ámbar)** indicando el folio del turno y la sucursal de origen. Incluye el botón interactivo **"Cambiar a [Sucursal del Turno]"**. Se deshabilitan los botones de *Movimientos de Caja* y *Corte y Arqueo*, y se oculta el botón de apertura para evitar turnos duplicados. |
| **`CashShiftOpenDialog`** | Si el usuario invoca el diálogo teniendo un turno abierto en otra sede, se reemplaza el formulario por una vista de advertencia: *"Turno Ya Abierto"* con botón directo para cambiar a la sucursal del turno. En `_submit()` se bloquea la creación concurrente. |
| **`OrderPayDialog`** | En lugar de permitir el cobro o mostrar un genérico *"Sin turno"*, muestra una tarjeta de aviso ámbar: *"Turno en Otra Sucursal"* con botón para trasladarse a la sede del turno con un clic. El botón **"Registrar Pago"** queda deshabilitado. |
| **`CashMovementsListDialog` / `CashMovementDialog`** | Deshabilita la creación de nuevos ingresos o retiros y muestra aviso de advertencia si la sucursal de la sesión no coincide con la del turno. |
| **`HomeMenuView`** | La tarjeta compacta de caja en el menú superior adquiere tono ámbar, mostrando *"Turno en '[Sucursal]' • Cambia de sucursal"*, y el botón de acción se transforma en un icono de intercambio (`swap_horiz_rounded`) para regresar a la sucursal del turno en un solo toque. |
