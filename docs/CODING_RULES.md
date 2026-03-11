# RakshaPoorvak – Coding Rules & Standards

This document defines coding standards, patterns, and best practices for the RakshaPoorvak project. **AI agents and developers must follow these rules** to maintain code quality, consistency, and reduce bugs across all components.

---

## Table of Contents

1. [General Principles](#general-principles)
2. [Backend (Spring Boot / Java)](#backend-spring-boot--java)
3. [Hospital Dashboard (React / TypeScript)](#hospital-dashboard-react--typescript)
4. [Mobile Apps (Flutter / Dart)](#mobile-apps-flutter--dart)
5. [API Design](#api-design)
6. [Database](#database)
7. [Security](#security)
8. [Error Handling](#error-handling)
9. [Testing](#testing)
10. [Git & Documentation](#git--documentation)

---

## General Principles

### 1. Consistency
- Follow the project structure defined in `PROJECT_STRUCTURE.md`.
- Use the naming conventions specified for each layer.
- Do not deviate from agreed patterns without justification.

### 2. Single Responsibility
- Each class, function, or component should have one clear purpose.
- Split large files into smaller, focused modules.

### 3. DRY (Don't Repeat Yourself)
- Extract reusable logic into shared utilities, hooks, or services.
- Use constants for magic numbers and repeated strings.

### 4. Fail Fast
- Validate inputs at boundaries (API, forms).
- Throw meaningful errors early rather than propagating invalid state.

### 5. Readability Over Cleverness
- Write code that is easy to understand.
- Prefer explicit over implicit.
- Add comments only when logic is non-obvious.

---

## Backend (Spring Boot / Java)

### Package Structure
- Use `com.rakshapoorvak` as base package.
- Organize by layer: `controller`, `service`, `repository`, `model`, `config`, `exception`, `security`, `websocket`.

### Naming
- **Classes:** PascalCase (e.g., `SosEventService`, `UserController`).
- **Methods:** camelCase (e.g., `findNearestAmbulance`, `createSosEvent`).
- **Constants:** UPPER_SNAKE_CASE (e.g., `MAX_RETRY_ATTEMPTS`).
- **Packages:** lowercase (e.g., `com.rakshapoorvak.service`).

### Controller Rules
- Controllers should be thin: validate input, call service, return response.
- Use `@Valid` for request body validation.
- Return `ResponseEntity<>` with appropriate HTTP status codes.
- Do not put business logic in controllers.

```java
// ✅ GOOD
@PostMapping("/sos")
public ResponseEntity<SosEventDto> createSos(@Valid @RequestBody CreateSosRequest request,
                                             @AuthenticationPrincipal User user) {
    SosEventDto created = sosService.createSos(user.getId(), request);
    return ResponseEntity.status(HttpStatus.CREATED).body(created);
}

// ❌ BAD – business logic in controller
@PostMapping("/sos")
public ResponseEntity<?> createSos(@RequestBody CreateSosRequest request) {
    // Finding ambulance, updating DB, etc. in controller
}
```

### Service Rules
- Service methods should be transactional where needed (`@Transactional`).
- One service method = one logical operation.
- Use DTOs for input/output; avoid exposing entities directly.

### Repository Rules
- Use Spring Data JPA repositories.
- Custom queries: use `@Query` with named parameters.
- Avoid N+1: use `@EntityGraph` or `JOIN FETCH` when loading associations.

### Entity Rules
- Use `@Column` with explicit names for DB columns.
- Use `@CreatedDate`, `@LastModifiedDate` for auditing.
- Avoid bidirectional relationships unless necessary.
- Prefer `LocalDateTime` over `Date`.

---

## Hospital Dashboard (React / TypeScript)

### File Structure
- Components in `src/components/` with one component per folder.
- Pages in `src/pages/`.
- API calls in `src/api/`.
- Types in `src/types/`.
- Hooks in `src/hooks/`.

### Naming
- **Components:** PascalCase (e.g., `LiveMap.tsx`, `SosMonitor.tsx`).
- **Hooks:** `use` prefix, camelCase (e.g., `useWebSocket`, `useSosEvents`).
- **Utils:** camelCase (e.g., `formatDate`, `parseStatus`).

### Component Rules
- Use functional components with hooks.
- Prefer composition over inheritance.
- Extract reusable UI into `components/common/`.
- Keep components under 200 lines; split if larger.

```tsx
// ✅ GOOD
const LiveMap: React.FC<LiveMapProps> = ({ sosEvents, ambulances }) => {
  const { mapRef, center } = useMapSetup(ambulances);
  return <MapContainer ref={mapRef} center={center} />;
};

// ❌ BAD – huge component with all logic inline
```

### State Management
- Use React state for local UI state.
- Use context or Zustand for shared state (auth, WebSocket).
- Avoid prop drilling: use context for deeply nested data.

### API Layer
- Use a single API client (Axios/fetch) with base URL and interceptors.
- Handle 401: redirect to login or refresh token.
- Always handle errors; show user-friendly messages.

### TypeScript
- Enable strict mode.
- Avoid `any`; use `unknown` if type is truly unknown.
- Define interfaces for props and API responses.

---

## Mobile Apps (Flutter / Dart)

### File Structure
- Follow feature-first structure: `features/<feature>/presentation/`.
- Shared code in `core/` and `shared/`.
- API in `data/api/`, models in `data/models/`.

### Naming
- **Files:** snake_case (e.g., `sos_confirmation_screen.dart`).
- **Classes:** PascalCase (e.g., `SosConfirmationScreen`).
- **Variables/functions:** camelCase (e.g., `sosEvent`, `fetchSosEvents`).
- **Constants:** lowerCamelCase or SCREAMING_CAPS in const objects.

### Widget Rules
- Extract widgets into separate files when reused or > 50 lines.
- Use `const` constructors where possible.
- Prefer `StatelessWidget` unless state is needed.

### State Management
- Choose one approach (Provider, Riverpod, Bloc) and stick to it.
- Keep business logic out of UI widgets.
- Use repositories for data access.

### API & Models
- Use `dio` or `http` with a base client.
- Parse JSON to typed models (avoid `dynamic`).
- Handle network errors and show SnackBar/Dialog.

### Platform-Specific
- Use `Platform.isAndroid` or conditional imports for platform checks.
- Test on both emulator and real device for location/camera.

---

## API Design

### REST Conventions
- Use nouns for resources: `/api/sos-events`, `/api/ambulances`.
- Use HTTP methods correctly: GET (read), POST (create), PUT/PATCH (update), DELETE (delete).
- Use plural nouns: `/users` not `/user`.

### Response Format
- Success: `{ "data": {...} }` or direct payload.
- Error: `{ "error": { "code": "...", "message": "..." } }`.
- Use consistent structure across all endpoints.

### Status Codes
- `200` – Success
- `201` – Created
- `400` – Bad request (validation)
- `401` – Unauthorized
- `403` – Forbidden
- `404` – Not found
- `500` – Server error

### WebSocket
- Use STOMP over WebSocket for structured messages.
- Define clear topics: `/topic/sos/{sosId}/location`, `/topic/sos/{sosId}/status`.
- Send only necessary data; avoid large payloads.

---

## Database

### Migrations
- Use Flyway or Liquibase for schema versioning.
- Never modify applied migrations; add new ones.
- Name: `V<n>__description.sql` (e.g., `V1__init.sql`, `V2__add_triage_table.sql`).

### Naming
- Tables: `snake_case`, plural (e.g., `sos_events`, `ambulances`).
- Columns: `snake_case` (e.g., `created_at`, `user_id`).
- Indexes: `idx_<table>_<column(s)>`.
- Foreign keys: `fk_<table>_<ref_table>`.

### Queries
- Use parameterized queries; never concatenate user input.
- Add indexes for frequently queried columns (location, status, timestamps).
- Avoid `SELECT *`; specify required columns in repositories.

---

## Security

### Authentication
- Use JWT for API authentication.
- Store tokens securely (HttpOnly cookie or secure storage on mobile).
- Implement token refresh flow.
- Validate token on every protected endpoint.

### Authorization
- Check user role/permissions in service layer.
- Hospital dashboard: hospital staff only.
- Driver app: driver role only.
- User app: user role only.

### Sensitive Data
- Never log passwords, tokens, or PII.
- Use environment variables for secrets.
- Encrypt sensitive data at rest if required.

### Input Validation
- Validate all inputs (length, format, range).
- Sanitize user input before storage/display.
- Use Bean Validation (`@Valid`, `@NotNull`, etc.) on DTOs.

---

## Error Handling

### Backend
- Use `@ControllerAdvice` for global exception handling.
- Map exceptions to appropriate HTTP status and error body.
- Log errors with context; do not expose stack traces to clients.

### Frontend / Mobile
- Catch errors at API boundary.
- Show user-friendly messages.
- Log errors for debugging (avoid exposing internals to user).

### WebSocket
- Handle connection drops and reconnection.
- Queue messages if disconnected; sync on reconnect.

---

## Testing

### Backend
- Unit tests for services (mock repositories).
- Integration tests for critical APIs.
- Use `@SpringBootTest` for integration tests.
- Aim for > 70% coverage on service layer.

### Frontend
- Unit tests for hooks and utils.
- Component tests for critical UI (e.g., SOS button).
- Use Vitest or Jest.

### Mobile
- Unit tests for repositories and business logic.
- Widget tests for key screens.
- Integration tests for critical flows (SOS → tracking).

### Naming
- Test files: `*Test.java`, `*.test.ts`, `*_test.dart`.
- Test names: `should_<expected_behavior>_when_<condition>`.

---

## Git & Documentation

### Commits
- Use conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`.
- Keep commits atomic and descriptive.
- Example: `feat(backend): add SOS creation endpoint`

### Branching
- `main` – production-ready.
- `develop` – integration branch.
- Feature branches: `feature/sos-one-tap`, `fix/websocket-reconnect`.

### Code Comments
- Comment *why*, not *what*.
- Document complex algorithms.
- Keep comments up to date with code changes.

### README
- Each component (backend, dashboard, apps) should have a README.
- Include: setup, run instructions, env vars, main endpoints/screens.

---

## Summary Checklist for AI Agents

Before submitting code, ensure:

- [ ] Follows project folder structure
- [ ] Uses correct naming conventions for the layer
- [ ] No business logic in controllers
- [ ] Input validation at boundaries
- [ ] Errors handled and logged appropriately
- [ ] No hardcoded secrets
- [ ] Types/interfaces defined (no `any` where avoidable)
- [ ] Consistent with existing patterns in the codebase
- [ ] No unnecessary dependencies added

---

*These rules are binding for all contributors and AI-assisted development. Update this document when patterns evolve.*
