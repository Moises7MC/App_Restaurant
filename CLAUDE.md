# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Flutter app for a restaurant's order-taking and kitchen-calling workflow. Two roles share one app:

- **Mozo** (waiter): picks a meal type/table, browses products, builds a cart, sends orders.
- **Cantador** (caller): a real-time dashboard that aggregates pending dishes across tables, lets staff mark dishes as served, and "sings" orders to the chef.

The app talks to a separate .NET backend (not in this repo) over REST plus a SignalR hub for the cantador's live updates.

## Commands

```bash
flutter pub get                 # install dependencies
flutter run                     # run on a connected device/emulator
flutter analyze                 # lint (flutter_lints via analysis_options.yaml)
flutter test                    # run all tests
flutter test test/widget_test.dart   # run a single test file
```

There is no CI config in this repo; `flutter analyze` and `flutter test` are the checks to run before considering a change done.

## Backend URL configuration

`lib/core/config/api_config.dart` has a hardcoded `mode` switch (`'local' | 'localNetwork' | 'production'`) plus a hardcoded `localNetworkIp`. This is how the app points at the .NET backend during development (typically a laptop on the restaurant's WiFi). When testing changes that hit the network, check this file first — a wrong IP/mode is a common source of "nothing works" during dev, not a code bug.

## Architecture

Feature-first under `lib/features/<feature>/`, each split into `data/`, `domain/`, `presentation/`. In practice two different depths of "clean architecture" coexist:

- **`auth`** is the fullest example: `domain/entities` (pure), `domain/repositories` (abstract contracts), `domain/usecases` (`LoginUseCase`, `LogoutUseCase`), `data/datasources` + `data/repositories` (impl), `data/models` (JSON (de)serialization, e.g. `UserModel.fromJson`/`toJson`/`toEntity`). Wired together by the hand-rolled singleton `lib/core/di/dependency_injection.dart`, whose `init()` must run before `runApp` (see `lib/main.dart`).
- **`meals`** and **`cantador`** skip the repository/usecase layers — their BLoCs call `lib/services/api_service.dart` (a static class, one method per backend endpoint) directly. Don't add a repository layer here unless asked; follow the existing pattern in the feature you're touching.

State management is `flutter_bloc` throughout: each feature has `bloc/`, `event.dart`, `state.dart` files. `CartBloc` and `CashFlowBloc` are provided app-wide via `MultiBlocProvider` in `main.dart`; `AuthBloc` is created per-app via the DI container; `CantadorBloc` is created locally where the cantador screens are built.

Routing is `go_router`, centralized in `lib/core/routes/app_router.dart`, with a `NavigationExtension` on `BuildContext` (`context.goToMeals()`, etc.) as the preferred way to navigate rather than calling `context.go(...)` with raw path strings. Post-login routing is role-based: `main.dart`'s `BlocListener<AuthBloc, AuthState>` sends `User.isCantador` to `/cantador` and everyone else to `/meals`.

### Cantador real-time flow

`CantadorSignalRService` (`lib/features/cantador/data/services/`) connects to the backend's `/hubs/orders` hub, joins the `Cantadores` group, and listens for `ActualizacionPedido`, `ItemServed`, `OrderSung`, `OrderStatusChanged`. On any event it calls an `onUpdate` callback (wired to dispatch `RefreshCantadorData` into `CantadorBloc`) — there is no separate local-state reconciliation, the backend's `pendingQuantity`/status fields are the source of truth on every refresh. SignalR connection failures are swallowed (logged, not rethrown) so the cantador screen still works via manual/polling refresh if the hub is unreachable.

`PisoResolver` (`lib/features/cantador/data/services/piso_resolver.dart`) loads the table→floor mapping once from `getTablesByFloor()` and falls back to a hardcoded floor split if that call fails.

### Cart is per-table, in memory

`CartBloc` keeps carts in a `Map<String, List<CartItem>>` keyed by `"${mealType}_${tableNumber}"`, entirely in memory (no persistence). Selecting a table (`SelectTable`) swaps which cart is "current"; `LiberarMesa` drops a specific table's cart. There's no single "the cart" — always go through the current table key.

## Known repo quirks

- `lib/features/auth/domain/entities/UderModel.dart` and `lib/features/auth/data/models/user_model.dart` are byte-identical duplicate `UserModel` classes (the domain one is a stray/misplaced copy, misspelled filename). `data/models/user_model.dart` is the one actually wired into the DI/repository flow — treat the domain-layer copy as dead weight, don't edit only one and assume the other updates.
- Code is heavily commented in Spanish with emoji section markers (`// ✅ NUEVO`, `// ═══`); match the existing style within a file rather than introducing a different convention.
- Lots of `print()` debug statements are left in intentionally (auth flow, API calls) as the de facto logging approach — don't strip them out as part of unrelated changes.
