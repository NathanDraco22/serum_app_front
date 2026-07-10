# serum_business

Business logic, data sources, and models for the **Serum LIS** app. Pure Dart package with no Flutter dependency.

## Installation

```yaml
dependencies:
  serum_business:
    path: packages/serum_business
```

## Architecture

```
lib/
├── serum_business.dart          # Main barrel
└── src/
    ├── data/                    # Data Sources (HTTP calls)
    ├── domain/
    │   ├── models/              # Typed models (Base, Create, Update, InDb)
    │   ├── query_params/        # Query parameter classes for filtered endpoints
    │   ├── repositories/        # Business logic + in-memory cache
    │   └── responses/           # Generic response wrappers (ListResponse)
    ├── services/                # Mixins (HttpService, HiveService)
    ├── tools/                   # Utilities (HttpTools, DateTimeTool, ReactiveRepository)
    ├── serum_client.dart        # Singleton config accessor
    ├── serum_client_config.dart # Config interface
    ├── local_storage.dart       # Abstract storage interfaces
    └── constants/               # Shared constants
```

## Business Logic

### What this package solves

`serum_business` encapsulates the domain logic of a **Laboratory Information System (LIS)** — the software that runs clinical labs. Each entity maps to a real-world business concept:

| Entity | Business Problem | What it does |
|---|---|---|
| **Branch** | A lab may have multiple physical locations. | Manage sucursals: add new offices, update contact info, list active branches. |
| **CashRegister** | Each branch needs to track daily cash flow per register. | Open/close registers, track balances per payment method (cash, card, transfer), assign operators. |
| **CashTransaction** | Every cash movement must be audited. | Record all register transactions (income/expense) with filtering by date, type, register, and payment method. **Read-only** historical log. |
| **Doctor** | Labs receive orders from referring physicians. | Maintain a directory of doctors: name, specialty, contact. |
| **Exam** | Labs offer commercial exam packages. | Define exam catalog: name, category, sale price, and which lab tests are included in each exam. |
| **LabTest** | Each exam contains measurable clinical parameters. | Define individual lab tests: parameter name, unit of measure, medical classification, and clinical reference ranges (by age, gender, patient type). |
| **Order** | When a patient gets tested, an order is created. | Track patient orders: which exam, which patient, sale price applied, test results with alert flags. |
| **Patient** | Patients are the core of the system. | Register patients: name, date of birth, gender, contact info. Patient data feeds into orders and results. |
| **Quotation** | Before ordering, patients may request a price quote. | Generate exam quotations with total amount, convert to order when accepted. |
| **User** | The system has staff with different roles. | Manage system access: login credentials, role-based permissions, branch assignments. |

### Key Business Rules

- **Soft delete**: All entities support soft delete (`isDeleted: bool`). Records are never physically removed for audit compliance.
- **Monetary values in cents**: All prices, balances, and amounts are stored as `int` in cents (centavos) to avoid floating-point precision errors.
- **Reference ranges**: Lab test reference values vary by patient type, gender, and age — supporting pediatric, adult, and geriatric ranges.
- **Cash register reconciliation**: Transactions record `resultingBalance` to enable point-in-time balance reconstruction for end-of-day reconciliation.
- **Quote-to-order conversion**: A quotation can be converted to an order (`convertedToOrderId`), linking the sales process end-to-end.

## Entities (10)

| Entity | InDb Model Fields | Repo Methods |
|---|---|---|
| **Branch** | id, name, address, phone, createdAt, updatedAt, isDeleted | create, getAll, getById, updateById, deleteById |
| **CashRegister** | id, branchId, name, isOpen, cashBalance, cardBalance, transferBalance, totalBalance, openedBy, createdAt, updatedAt, isDeleted | create, getAll, getById, updateById, deleteById |
| **CashTransaction** | id, registerId, flowType, subType, paymentMethod, amount, resultingBalance, concept, referenceId, performedBy, createdAt, updatedAt, isDeleted | getAll *(read-only, with filters)* |
| **Doctor** | id, name, specialty, phone, email, createdAt, updatedAt, isDeleted | create, getAll, getById, updateById, deleteById |
| **Exam** | id, name, commercialCategory, salePrice, currency, includedTests, createdAt, updatedAt, isDeleted | create, getAll, getById, updateById, deleteById |
| **LabTest** | id, parameterName, medicalClassification, dataType, unitOfMeasure, referenceValues, createdAt, updatedAt, isDeleted | create, getAll, getById, updateById, deleteById |
| **Order** | id, patientId, quotationId, examId, examName, salePriceApplied, status, results, createdAt, updatedAt, isDeleted | create, getAll, getById, updateById, deleteById |
| **Patient** | id, name, dateOfBirth, gender, phone, address, email, createdAt, updatedAt, isDeleted | create, getAll, getById, updateById, deleteById |
| **Quotation** | id, clientName, patientId, exams, totalAmount, status, convertedToOrderId, createdAt, updatedAt, isDeleted | create, getAll, getById, updateById, deleteById |
| **User** | id, username, password, name, email, role, branches, createdAt, updatedAt, isDeleted | create, getAll, getById, updateById, deleteById |

### Shared Models

| Model | Fields | Used By |
|---|---|---|
| `ReferenceValue` | patientType, gender, minAgeDays, maxAgeDays, minValue, maxValue | LabTest, IncludedTest |
| `IncludedTest` | labTestId, parameterName, medicalClassification, dataType, unitOfMeasure, referenceValues | Exam |
| `QuotedExam` | examId, examName, quotedPrice | Quotation |
| `OrderTestResult` | extends IncludedTest + resultValue, alertFlag | Order |
| `UserInfo` | id, name | CashRegister, CashTransaction |

## Query Parameters (Filtered Endpoints)

**CashTransactionQueryParams:**
| Param | Type | Description |
|---|---|---|
| registerId | String? | Filter by cash register |
| flowType | String? | income / expense |
| subType | String? | Specific transaction subtype |
| paymentMethod | String? | cash / card / transfer |
| startDate | int? | Start timestamp (ms) |
| endDate | int? | End timestamp (ms) |
| offset | int | Pagination offset (default 0) |
| limit | int | Page size (default 50) |

## Reactivity

Repositories with write operations use the `ReactiveRepository<T>` mixin. They emit events through an `eventStream`:

```dart
enum RepoEvent { RepoItemCreated, RepoItemUpdated, RepoItemDeleted }
```

Read Cubits subscribe to this stream to automatically update their state when items are created, updated, or deleted elsewhere — no manual UI coordination needed.

## Usage

```dart
import 'package:serum_business/serum_business.dart';

// 1. Initialize client config
SerumClient.initialize(MySerumConfig());

// 2. Create repository
final repo = BranchesRepository(BranchesDataSource());

// 3. Read
final branches = await repo.getAllBranches();

// 4. Create
final created = await repo.createBranch(
  CreateBranch(name: 'Main St', address: '123 Main', phone: '555-0100'),
);

// 5. Update
final updated = await repo.updateBranchById(
  created.id,
  UpdateBranch(name: 'Main St Updated'),
);

// 6. Delete
await repo.deleteBranchById(created.id);
```

## Static Analysis

```bash
flutter analyze
```
