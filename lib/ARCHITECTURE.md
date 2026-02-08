# MVVM Clean Architecture

This project follows MVVM (Model-View-ViewModel) clean architecture principles.

## Folder Structure

```
lib/
├── domain/              # Domain Layer (Business Logic)
│   ├── entities/        # Domain entities (Models)
│   │   ├── member.dart
│   │   ├── membership_plan.dart
│   │   └── check_in.dart
│   └── repositories/    # Repository interfaces (Contracts)
│       └── gym_repository.dart
│
├── data/                # Data Layer (Implementation)
│   ├── repositories/    # Repository implementations
│   │   └── gym_repository_impl.dart
│   └── services/        # Data services (Database, API, etc.)
│       └── database_service.dart
│
├── presentation/        # Presentation Layer (UI)
│   ├── viewmodels/     # ViewModels (State Management)
│   │   ├── gym_viewmodel.dart
│   │   └── theme_viewmodel.dart
│   └── views/          # Views (Screens/Widgets)
│       ├── dashboard_screen.dart
│       ├── members_screen.dart
│       ├── check_in_screen.dart
│       └── membership_plans_screen.dart
│
└── core/               # Core utilities (Optional)
    └── (Future core utilities)
```

## Architecture Layers

### 1. Domain Layer (`domain/`)
- **Entities**: Pure business objects/models
- **Repository Interfaces**: Contracts defining data operations
- **No dependencies** on other layers
- Contains business logic rules

### 2. Data Layer (`data/`)
- **Repository Implementations**: Concrete implementations of domain repositories
- **Services**: Database, API, and external service implementations
- **Depends on**: Domain layer only
- Handles data persistence and retrieval

### 3. Presentation Layer (`presentation/`)
- **ViewModels**: Business logic for UI, state management
- **Views**: UI components (screens, widgets)
- **Depends on**: Domain layer (via repositories)
- Handles user interaction and UI rendering

## Dependency Flow

```
Presentation → Domain ← Data
     ↓           ↓        ↓
  (Views)  (Entities)  (Services)
```

- **Presentation** depends on **Domain** (through repository interfaces)
- **Data** depends on **Domain** (implements repository interfaces)
- **Domain** has **no dependencies** on other layers

## Key Principles

1. **Separation of Concerns**: Each layer has a single responsibility
2. **Dependency Inversion**: High-level modules don't depend on low-level modules
3. **Testability**: Each layer can be tested independently
4. **Maintainability**: Changes in one layer don't affect others unnecessarily

## Naming Conventions

- **Entities**: Pure data classes (e.g., `Member`, `MembershipPlan`)
- **Repositories**: Interface → `GymRepository`, Implementation → `GymRepositoryImpl`
- **ViewModels**: Business logic + state (e.g., `GymViewModel`, `ThemeViewModel`)
- **Views**: UI screens (e.g., `DashboardScreen`, `MembersScreen`)

