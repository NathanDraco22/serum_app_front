---
title: Módulos — Control de Cajas Registradoras y Kardex Financiero
description: Especificación funcional de los módulos cash_register y cash_transaction para apertura, arqueos, cierres y auditoría de flujo de dinero.
tags: [cash_register, cash_transaction, kardex, accounting, pos, ui]
timestamp: 2026-09-28T19:46:00Z
---

# 💵 Cajas Registradoras y Kardex Financiero

Esta sección aborda la gestión de las terminales de caja física y el libro mayor inmutable de movimientos financieros.

---

## 1. Módulo `cash_register` (`lib/src/modules/cash_register/`)
- **Pantalla**: `CashRegisterScreen` (`view/cash_register_screen.dart`).
- **Widgets Clave**:
  - `CashRegisterCard` (`widgets/cash_register_card.dart`): Tarjeta con indicadores de estado (Abierta/Cerrada), saldos desglosados en efectivo, tarjeta y transferencia.
  - `CashRegisterOpenDialog` (`widgets/cash_register_open_dialog.dart`): Formulario para realizar la apertura formal capturando el fondo inicial.
  - `CashRegisterCloseDialog` (`widgets/cash_register_close_dialog.dart`): Modal de arqueo y corte de caja.
  - `CashRegisterFormDialog` (`widgets/cash_register_form_dialog.dart`): Creación de nuevas terminales físicas.
- **Cubits**:
  - `ReadCashRegisterCubit`: Consulta del estado actual y balances de cada caja.
  - `WriteCashRegisterCubit`: Ejecución de aperturas, cierres y creaciones.
- **Funcionalidades Clave**:
  1. **Apertura de Caja**: Exige ingresar el monto de apertura en efectivo (`initialCash`), emite la transacción contable de tipo `opening` y pasa la caja a estado abierta (`isOpen: true`).
  2. **Arqueo y Cierre Asistido**: El operador cuenta el dinero físico e introduce el valor en `actualCash`. El diálogo calcula automáticamente si hay sobrante o faltante respecto al balance teórico del sistema antes de proceder con el cierre definitivo.

---

## 2. Módulo `cash_transaction` (`lib/src/modules/cash_transaction/`)
- **Pantalla**: `CashTransactionScreen` (`view/cash_transaction_screen.dart`).
- **Widgets Clave**:
  - `CashTransactionList` (`widgets/cash_transaction_list.dart`): Listado ordenado cronológicamente de transacciones.
- **Cubits**:
  - `ReadCashTransactionCubit`: Consulta de transacciones filtradas por sucursal y caja.
- **Funcionalidades Clave**:
  1. **Auditoría Inmutable (Solo Lectura)**: No existen operaciones de edición o borrado de transacciones. Todo movimiento queda permanentemente registrado.
  2. **Tipos de Transacciones Desglosadas**:
     - `opening`: Apertura de caja (Sentido: `in`).
     - `order_payment`: Cobro de orden médica (Sentido: `in`).
     - `income`: Ingreso extraordinario (Sentido: `in`).
     - `withdrawal`: Egreso o retiro por gasto (Sentido: `out`).
     - `closing`: Cierre de caja (Sentido: `out`).
  3. **Visualización de Balances**: Muestra claramente si la transacción afectó saldo en efectivo, tarjeta de débito/crédito o transferencia bancaria.
