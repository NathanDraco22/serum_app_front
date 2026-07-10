# serum_business

Lógica de negocio, fuentes de datos y modelos para la aplicación **Serum LIS**. Paquete Dart puro sin dependencia de Flutter.

## Instalación

```yaml
dependencies:
  serum_business:
    path: packages/serum_business
```

## Arquitectura

```
lib/
├── serum_business.dart          # Barrel principal
└── src/
    ├── data/                    # Data Sources (llamadas HTTP)
    ├── domain/
    │   ├── models/              # Modelos tipados (Base, Create, Update, InDb)
    │   ├── query_params/        # Clases de parámetros para endpoints con filtros
    │   ├── repositories/        # Lógica de negocio + caché en memoria
    │   └── responses/           # Envoltorios de respuesta genéricos (ListResponse)
    ├── services/                # Mixins (HttpService, HiveService)
    ├── tools/                   # Utilidades (HttpTools, DateTimeTool, ReactiveRepository)
    ├── serum_client.dart        # Acceso singleton a configuración
    ├── serum_client_config.dart # Interfaz de configuración
    ├── local_storage.dart       # Interfaces abstractas de almacenamiento
    └── constants/               # Constantes compartidas
```

## Lógica de Negocio

### ¿Qué problemas resuelve este paquete?

`serum_business` encapsula la lógica de dominio de un **Sistema de Información de Laboratorio (LIS)** — el software que gestiona laboratorios clínicos. Cada entidad representa un concepto de negocio real:

| Entidad | Problema de Negocio | Qué hace |
|---|---|---|
| **Branch** | Un laboratorio puede tener múltiples ubicaciones físicas. | Gestionar sucursales: agregar nuevas oficinas, actualizar datos de contacto, listar sucursales activas. |
| **CashRegister** | Cada sucursal necesita controlar el flujo de caja diario por registro. | Abrir/cerrar cajas, rastrear saldos por método de pago (efectivo, tarjeta, transferencia), asignar operadores. |
| **CashTransaction** | Cada movimiento de caja debe ser auditado. | Registrar todas las transacciones de caja (ingresos/egresos) con filtros por fecha, tipo, registro y método de pago. **Solo lectura** — histórico contable. |
| **Doctor** | Los laboratorios reciben órdenes de médicos remitentes. | Mantener un directorio de médicos: nombre, especialidad, contacto. |
| **Exam** | Los laboratorios ofrecen paquetes de exámenes comerciales. | Definir catálogo de exámenes: nombre, categoría, precio de venta y qué pruebas de laboratorio incluye cada examen. |
| **LabTest** | Cada examen contiene parámetros clínicos medibles. | Definir pruebas de laboratorio individuales: nombre del parámetro, unidad de medida, clasificación médica y rangos de referencia clínicos (por edad, género, tipo de paciente). |
| **Order** | Cuando un paciente se realiza un examen, se crea una orden. | Rastrear órdenes de pacientes: qué examen, qué paciente, precio aplicado, resultados con banderas de alerta. |
| **Patient** | Los pacientes son el núcleo del sistema. | Registrar pacientes: nombre, fecha de nacimiento, género, datos de contacto. Los datos del paciente alimentan las órdenes y resultados. |
| **Quotation** | Antes de ordenar, los pacientes pueden solicitar una cotización. | Generar cotizaciones de exámenes con monto total, convertir a orden cuando sea aceptada. |
| **User** | El sistema tiene personal con diferentes roles. | Gestionar acceso al sistema: credenciales de inicio de sesión, permisos basados en roles, asignación de sucursales. |

### Reglas de Negocio Clave

- **Soft delete**: Todas las entidades soportan eliminación suave (`isDeleted: bool`). Los registros nunca se eliminan físicamente por cumplimiento de auditoría.
- **Valores monetarios en centavos**: Todos los precios, saldos y montos se almacenan como `int` en centavos para evitar errores de precisión de punto flotante.
- **Rangos de referencia**: Los valores de referencia de pruebas de laboratorio varían por tipo de paciente, género y edad — soportando rangos pediátricos, adultos y geriátricos.
- **Conciliación de caja**: Las transacciones registran `resultingBalance` para permitir la reconstrucción del saldo en un punto específico del tiempo para la conciliación de fin de día.
- **Conversión de cotización a orden**: Una cotización puede convertirse en una orden (`convertedToOrderId`), vinculando el proceso de venta de principio a fin.

## Entidades (10)

| Entidad | Campos del Modelo InDb | Métodos del Repo |
|---|---|---|
| **Branch** | id, name, address, phone, createdAt, updatedAt, isDeleted | create, getAll, getById, updateById, deleteById |
| **CashRegister** | id, branchId, name, isOpen, cashBalance, cardBalance, transferBalance, totalBalance, openedBy, createdAt, updatedAt, isDeleted | create, getAll, getById, updateById, deleteById |
| **CashTransaction** | id, registerId, flowType, subType, paymentMethod, amount, resultingBalance, concept, referenceId, performedBy, createdAt, updatedAt, isDeleted | getAll *(solo lectura, con filtros)* |
| **Doctor** | id, name, specialty, phone, email, createdAt, updatedAt, isDeleted | create, getAll, getById, updateById, deleteById |
| **Exam** | id, name, commercialCategory, salePrice, currency, includedTests, createdAt, updatedAt, isDeleted | create, getAll, getById, updateById, deleteById |
| **LabTest** | id, parameterName, medicalClassification, dataType, unitOfMeasure, referenceValues, createdAt, updatedAt, isDeleted | create, getAll, getById, updateById, deleteById |
| **Order** | id, patientId, quotationId, examId, examName, salePriceApplied, status, results, createdAt, updatedAt, isDeleted | create, getAll, getById, updateById, deleteById |
| **Patient** | id, name, dateOfBirth, gender, phone, address, email, createdAt, updatedAt, isDeleted | create, getAll, getById, updateById, deleteById |
| **Quotation** | id, clientName, patientId, exams, totalAmount, status, convertedToOrderId, createdAt, updatedAt, isDeleted | create, getAll, getById, updateById, deleteById |
| **User** | id, username, password, name, email, role, branches, createdAt, updatedAt, isDeleted | create, getAll, getById, updateById, deleteById |

### Modelos Compartidos

| Modelo | Campos | Usado por |
|---|---|---|
| `ReferenceValue` | patientType, gender, minAgeDays, maxAgeDays, minValue, maxValue | LabTest, IncludedTest |
| `IncludedTest` | labTestId, parameterName, medicalClassification, dataType, unitOfMeasure, referenceValues | Exam |
| `QuotedExam` | examId, examName, quotedPrice | Quotation |
| `OrderTestResult` | extiende IncludedTest + resultValue, alertFlag | Order |
| `UserInfo` | id, name | CashRegister, CashTransaction |

## Parámetros de Consulta (Endpoints Filtrados)

**CashTransactionQueryParams:**
| Parámetro | Tipo | Descripción |
|---|---|---|
| registerId | String? | Filtrar por caja registradora |
| flowType | String? | income / expense |
| subType | String? | Subtipo específico de transacción |
| paymentMethod | String? | cash / card / transfer |
| startDate | int? | Timestamp inicial (ms) |
| endDate | int? | Timestamp final (ms) |
| offset | int | Desplazamiento de paginación (default 0) |
| limit | int | Tamaño de página (default 50) |

## Reactividad

Los repositorios con operaciones de escritura usan el mixin `ReactiveRepository<T>`. Emiten eventos a través de un `eventStream`:

```dart
enum RepoEvent { RepoItemCreated, RepoItemUpdated, RepoItemDeleted }
```

Los Read Cubits se suscriben a este stream para actualizar su estado automáticamente cuando se crean, actualizan o eliminan ítems desde cualquier parte de la app — sin necesidad de coordinación manual desde la UI.

## Uso

```dart
import 'package:serum_business/serum_business.dart';

// 1. Inicializar configuración del cliente
SerumClient.initialize(MiSerumConfig());

// 2. Crear repositorio
final repo = BranchesRepository(BranchesDataSource());

// 3. Leer
final sucursales = await repo.getAllBranches();

// 4. Crear
final creada = await repo.createBranch(
  CreateBranch(name: 'Sucursal A', address: 'Av. Principal 123', phone: '555-0100'),
);

// 5. Actualizar
final actualizada = await repo.updateBranchById(
  creada.id,
  UpdateBranch(name: 'Sucursal A (Actualizada)'),
);

// 6. Eliminar
await repo.deleteBranchById(creada.id);
```

## Static Analysis

```bash
flutter analyze
```
