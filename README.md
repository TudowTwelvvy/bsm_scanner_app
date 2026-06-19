# BSM Scanner App

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.6+-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.6+-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/.NET-8.0-512BD4?logo=dotnet" alt=".NET">
  <img src="https://img.shields.io/badge/SQL%20Server-2019+-CC2927?logo=microsoftsqlserver" alt="SQL Server">
  <img src="https://img.shields.io/badge/JWT-Auth-000000?logo=jsonwebtokens" alt="JWT">
</p>

A barcode scanner application that bridges the gap between mobile convenience and enterprise-grade backend security. Built with Flutter on the frontend and ASP.NET Core Identity on the backend, this application demonstrates how modern cross-platform development can deliver seamless user experiences while maintaining robust authentication and data integrity.

---

## Introduction

In today's fast-paced retail and inventory management environments, the ability to quickly scan, record, and retrieve product information is essential. The BSM Scanner App addresses this need by providing a complete solution that allows users to authenticate securely, scan barcodes using their device's camera, and maintain a persistent history of all scanned items. Every scan is tied to the authenticated user through JWT tokens, ensuring data privacy and accountability.

The application architecture follows Clean Architecture principles, separating concerns into distinct layers that communicate through well-defined contracts. This approach ensures that the business logic remains pure and testable, while the infrastructure concerns like HTTP communication and data persistence are isolated in the outer layers. The result is a codebase that is maintainable, scalable, and easy to reason about.

---

## What This Application Does

At its core, the BSM Scanner App is a product scanning and inventory tracking tool. When a user opens the application, they are greeted with an animated splash screen that checks whether they have a valid authentication token stored securely on their device. If a valid token exists, the user is automatically redirected to their scan history. If not, they are presented with a clean login screen where they can either sign in with existing credentials or create a new account.

Once authenticated, the user can navigate to the scanner screen, which transforms their device into a barcode reader. The scanner uses the device's camera with a custom overlay that guides the user to position the barcode correctly. When a barcode is detected, the application immediately pauses the camera to prevent duplicate scans and presents a dialog showing the scanned value. The user can add optional notes before saving the scan to their personal history.

The scan history screen serves as the application's home page. It displays all previously scanned items in a scrollable list, with each item showing the barcode value, type, and scan date. Users can tap any item to view its full details, edit the product name or notes, or delete it entirely. A gradient card at the top of the screen shows the total number of scans, providing a quick overview of activity.

---

## Technology Choices and Rationale

The frontend of this application is built with Flutter, Google's cross-platform UI framework. Flutter was chosen because it allows for a single codebase that compiles to native ARM code for both Android and iOS, while still providing the performance and native feel that users expect. The widget-based architecture of Flutter aligns naturally with the component-based design of modern user interfaces.

For state management, the application uses Riverpod rather than the more commonly seen Provider or Bloc patterns. Riverpod was selected because it offers compile-time safety, meaning that the Dart compiler can catch errors related to provider lookups before the application even runs. This eliminates an entire class of runtime bugs that plague other state management solutions. Riverpod also integrates seamlessly with Flutter's widget lifecycle, automatically disposing of resources when they are no longer needed.

Navigation is handled by GoRouter, a declarative routing package that treats URLs as the source of truth for the application's navigation state. This approach enables deep linking, allowing users to navigate directly to specific screens from external sources like notifications or web links. More importantly, GoRouter integrates with Riverpod to provide authentication guards that automatically redirect unauthenticated users away from protected routes.

The HTTP layer is built on Dio, a powerful HTTP client for Dart that supports interceptors, global configuration, and request cancellation. An interceptor is configured to automatically attach the JWT token to every outgoing request, eliminating the need to manually add headers in each API call. Another interceptor listens for 401 Unauthorized responses and broadcasts a global event that triggers automatic logout, ensuring that expired sessions are handled gracefully across the entire application.

For secure storage, the application uses Flutter Secure Storage, which leverages the platform's native encryption capabilities. On Android, this means the Android Keystore system, while iOS uses the Keychain. This ensures that authentication tokens are never stored in plain text and cannot be accessed by other applications or malicious actors with root access.

---

## Architecture Overview

The application follows Clean Architecture, a software design philosophy that emphasizes separation of concerns and dependency direction. In Clean Architecture, dependencies always point inward toward the domain layer, which contains the core business logic. The outer layers, which handle infrastructure concerns like HTTP communication and user interface rendering, depend on the inner layers but never the reverse.

The domain layer sits at the center of this architecture. It contains plain Dart classes that represent the core concepts of the application, such as users and products. These entities have no knowledge of Flutter, HTTP, or any external framework. They simply define what a user is, what a product is, and what operations can be performed on them. The domain layer also defines repository contracts, which are abstract interfaces that specify what capabilities any authentication or product repository must provide, without dictating how those capabilities are implemented.

Surrounding the domain layer is the data layer, which provides concrete implementations of the repository contracts. The authentication repository, for example, implements the authentication contract using Dio to communicate with the ASP.NET Core API and Flutter Secure Storage to persist tokens. Because the repository implements a contract defined in the domain layer, the presentation layer can depend on the abstract contract rather than the concrete implementation. This means that if the backend were ever replaced with a different technology, only the data layer would need to change. The user interface would remain untouched.

The presentation layer occupies the outermost ring of the architecture. It contains the Flutter widgets that render the user interface and the Riverpod providers that connect the UI to the domain layer. The presentation layer never directly instantiates HTTP clients or database connections. Instead, it reads repositories from Riverpod providers and calls methods on them. When the underlying data changes, Riverpod automatically rebuilds the affected widgets, ensuring that the user interface always reflects the current application state.

---

## Authentication and Security

Security is a foundational concern in the BSM Scanner App. The application uses JSON Web Tokens for authentication, which provides a stateless mechanism for verifying user identity across multiple requests. When a user logs in or registers, the ASP.NET Core API validates their credentials and returns a signed JWT token. This token contains claims that identify the user, including their unique identifier and email address, as well as an expiration timestamp that limits the token's validity period.

Upon receiving the token, the Flutter application immediately stores it in secure storage using hardware-backed encryption. The token is then decoded to extract the user's information, which is broadcast to all listening widgets through a Riverpod stream provider. This broadcast triggers the GoRouter authentication guard to re-evaluate the current route, redirecting the user from the login screen to their scan history.

Every subsequent API request automatically includes the token in the Authorization header, thanks to a Dio interceptor that runs before each request is sent. When the API receives a request, it validates the token's signature and expiration, then extracts the user identifier from the claims to determine which data the user is authorized to access. This ensures that users can only view and modify their own scans, preventing unauthorized access to other users' data.

A critical security challenge arises when the token expires. If any API request returns a 401 Unauthorized response, a second Dio interceptor detects this condition and broadcasts a global event. The authentication repository listens for this event and automatically clears the stored token, broadcasting a null user to all listeners. GoRouter detects this null user and immediately redirects to the login screen. This entire flow happens without any manual intervention from the user or explicit handling in the UI code, demonstrating the power of reactive architecture.

---

## The Scanning Experience

The scanner screen represents the most technically complex part of the application, integrating camera access, real-time image processing, and user interaction in a single cohesive experience. When the user navigates to the scanner, the application requests camera permission and initializes the Mobile Scanner controller, which manages the camera hardware and processes incoming video frames for barcode detection.

The screen presents a full-screen camera preview with a custom-painted overlay. This overlay darkens the entire screen except for a square cutout in the center, creating a visual guide that helps the user position the barcode correctly. White corner brackets frame the cutout, reinforcing the target area. This overlay is drawn using Flutter's CustomPainter API, which allows for efficient GPU-accelerated rendering that does not interfere with the camera preview underneath.

When the scanner detects a barcode, it immediately stops the camera to prevent multiple detections of the same code. A dialog appears showing the scanned value, the barcode type, and a text field for optional notes. The user can either save the scan to their history or cancel and return to scanning. If the user chooses to save, the application constructs a product entity and sends it to the API, which stores it in SQL Server with the user's identifier automatically extracted from the JWT token.

After saving or canceling, the camera restarts and the scan lock resets, allowing the user to scan additional items. A brief "Getting ready..." indicator appears during the restart transition, preventing any visual jarring that might occur from the camera briefly going black.

---

## Data Management and Synchronization

The application's data layer is designed around the principle that the server is the single source of truth. When the user views their scan history, the application fetches the latest data from the API rather than displaying cached information. This ensures that the user always sees the most current state, even if they have modified their scans from another device.

Riverpod's autoDispose feature plays a crucial role in this design. When the user navigates away from the scan history screen, the associated provider is automatically destroyed, discarding any cached data. When the user returns, a new provider is created and immediately fetches fresh data from the API. This pattern, combined with pull-to-refresh functionality, guarantees that the user interface never displays stale information.

For individual product details, the application uses a family provider that accepts a product identifier as a parameter. This creates a separate provider instance for each product, ensuring that viewing one product does not interfere with the cached state of another. When the user edits a product's name or notes, the changes are sent to the API, and the list provider is invalidated to force a refresh when the user returns to the history screen.

---

## Project Structure and Organization

The codebase is organized using a feature-first approach, where all code related to a specific feature lives in a single directory. This contrasts with the more traditional layer-first approach, where files are grouped by their technical type. Feature-first organization makes it easier to locate relevant code when working on a specific part of the application, and it simplifies the process of adding or removing features.

The authentication feature, for example, contains its domain models, data repositories, and presentation screens all within a single directory tree. The scanner feature follows the same pattern, with its product entity, repository, and camera screen grouped together. This organization reflects the reality that developers typically work on features rather than layers, and it reduces the cognitive overhead of navigating a large codebase.

Shared code that cuts across multiple features, such as theme configuration, HTTP client setup, and reusable widgets, lives in the core directory. This ensures that common concerns are defined in one place and reused consistently throughout the application.

---

## API Integration

The Flutter application communicates with the ASP.NET Core API through a well-defined set of REST endpoints. Authentication endpoints handle user registration and login, returning JWT tokens that the application stores securely. Product endpoints handle the creation, retrieval, update, and deletion of scan records, with each endpoint automatically validating the user's identity from the token.

The Dio HTTP client is configured with a base URL that points to the API, along with default headers that specify JSON as the content type. An interceptor examines every outgoing request and attaches the JWT token from secure storage if one exists. Another interceptor examines every incoming response and handles 401 errors by triggering the global logout event.

Error handling follows a layered approach. At the lowest level, Dio exceptions are caught and translated into domain-specific exceptions that carry human-readable messages. These domain exceptions propagate up to the presentation layer, where they are displayed to the user in SnackBar notifications. This separation ensures that the user interface never needs to understand HTTP status codes or JSON parsing errors.

---

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Architecture Overview](#architecture-overview)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Backend Setup](#backend-setup)
  - [Frontend Setup](#frontend-setup)
- [API Reference](#api-reference)
- [Authentication Flow](#authentication-flow)
- [Screenshots](#screenshots)
- [Future Enhancements](#future-enhancements)
- [Contributing](#contributing)
- [License](#license)

---

## Features

| Feature | Description | 
|---------|-------------|
| **JWT Authentication** | Secure login/register with token-based auth |
| **Auto-Login** | Persistent sessions using encrypted storage | 
| **Barcode Scanning** | Real-time camera-based barcode/QR detection |
| **Scan History** | View all saved scans with pull-to-refresh |
| **Product Details** | View, edit, and delete individual scans |
| **Swipe to Delete** | Intuitive gesture-based item removal |
| **Auth Guards** | Protected routes with automatic redirects |
| **Deep Linking** | URL-based navigation support |
| **User Greeting** | Display name shown in AppBar |
| **Camera Controls** | Torch toggle and front/back camera switch |

---

## Tech Stack

### Frontend

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | ^3.2.1 | Reactive state management |
| `go_router` | ^14.8.0 | Declarative routing with deep links |
| `dio` | ^5.8.0 | HTTP client with interceptors |
| `flutter_secure_storage` | ^10.0.0 | Hardware-encrypted token storage |
| `jwt_decoder` | ^2.0.1 | JWT token parsing |
| `mobile_scanner` | ^7.2.0 | Camera-based barcode detection |
| `intl` | ^0.20.0 | Date/time formatting |
| `equatable` | ^2.0.7 | Value equality for models |

### Backend

| Technology | Purpose |
|------------|---------|
| ASP.NET Core 8.0 | Web API framework |
| ASP.NET Core Identity | User management & authentication |
| JWT Bearer Tokens | Stateless authentication |
| Entity Framework Core | ORM for database operations |
| SQL Server | Relational database |

---

## Project Structure

```
bsm_scanner_app/
├── android/
│   └── app/
│       └── src/
│           └── main/
│               └── AndroidManifest.xml     # Camera + Internet permissions
├── lib/
│   ├── main.dart                           # Entry point
│   ├── app.dart                            # MaterialApp.router with GoRouter
│   ├── splash_screen.dart                  # Animated splash with auth check
│   ├── router/
│   │   └── app_router.dart                 # Route definitions + auth guards
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart          # API URLs, keys, timeouts
│   │   ├── config/
│   │   │   └── environment_config.dart     # Dev vs Production settings
│   │   ├── theme/
│   │   │   └── app_theme.dart              # Colors, fonts, button styles
│   │   ├── exceptions/
│   │   │   └── network_exceptions.dart     # HTTP error translations
│   │   ├── network/
│   │   │   ├── auth_events.dart            # 401 event bus
│   │   │   └── dio_client.dart             # HTTP client + JWT interceptor
│   │   ├── providers/
│   │   │   └── core_providers.dart         # SecureStorage + Dio providers
│   │   └── services/
│   │       └── secure_storage_service.dart # Encrypted token storage
│   └── features/
│       ├── auth/
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── user.dart           # User model (Guid id)
│       │   │   ├── repositories/
│       │   │   │   └── auth_repository_contract.dart
│       │   │   ├── dtos/
│       │   │   │   └── auth_dtos.dart      # Login/Register envelopes
│       │   │   ├── exceptions/
│       │   │   │   └── auth_exceptions.dart # Human-readable errors
│       │   │   └── services/
│       │   │       └── jwt_parser.dart     # JWT decoding logic
│       │   ├── data/
│       │   │   ├── auth_repository.dart    # Dio + API implementation
│       │   │   └── auth_repository_provider.dart # Riverpod wiring
│       │   └── presentation/
│       │       └── screens/
│       │           ├── login_screen.dart   # Email + password form
│       │           └── register_screen.dart # Registration form
│       ├── scanner/
│       │   ├── domain/
│       │   │   └── product_entity.dart     # Product model (int id)
│       │   ├── data/
│       │   │   └── product_repository.dart # CRUD API calls
│       │   └── presentation/
│       │       └── screens/
│       │           └── scanner_screen.dart # Camera + overlay + save
│       └── products/
│           └── presentation/
│               └── screens/
│                   ├── products_list_screen.dart    # Scan history
│                   └── product_detail_screen.dart   # View/edit/delete
├── pubspec.yaml                            # Dependencies
└── test/                                   # Unit tests
```

---

## Architecture Overview

### Clean Architecture Layers

```
┌─────────────────────────────────────────┐
│         PRESENTATION LAYER              │
│    (Screens, Widgets, Riverpod)         │
│                                         │
│  • LoginScreen, RegisterScreen         │
│  • ScannerScreen                        │
│  • ProductsListScreen                   │
│  • ProductDetailScreen                  │
│  • Riverpod Providers & Consumers       │
└─────────────────────────────────────────┘
                    │
                    ▼ depends on
┌─────────────────────────────────────────┐
│           DOMAIN LAYER                  │
│  (Entities, Contracts, DTOs, Errors)  │
│                                         │
│  • User Entity (Guid id)                │
│  • ProductEntity (int id)               │
│  • AuthRepositoryContract               │
│  • LoginRequest, RegisterRequest        │
│  • AuthException hierarchy              │
│  • JwtParser service                    │
└─────────────────────────────────────────┘
                    │
                    ▼ depends on
┌─────────────────────────────────────────┐
│            DATA LAYER                   │
│    (Repositories, Dio, SecureStorage) │
│                                         │
│  • AuthRepository (Dio + API)         │
│  • ProductRepository (Dio + API)      │
│  • DioClient with interceptors          │
│  • SecureStorageService                 │
│  • AuthEvents (event bus)               │
└─────────────────────────────────────────┘
                    │
                    ▼ HTTP/JSON
┌─────────────────────────────────────────┐
│           EXTERNAL LAYER                │
│      (ASP.NET Core API, SQL Server)     │
│                                         │
│  • /api/auth/login, /register           │
│  • /api/product (CRUD)                  │
│  • JWT Bearer validation                │
│  • Entity Framework Core                │
│  • SQL Server Database                  │
└─────────────────────────────────────────┘
```

### Dependency Rule

Dependencies always point **inward**. The Domain Layer knows nothing about Flutter, HTTP, or databases. The Presentation Layer depends on Domain contracts, not concrete implementations. The Data Layer implements Domain contracts using external frameworks.

| Layer | Knows About | Does NOT Know About |
|-------|-------------|---------------------|
| Presentation | Domain contracts, Riverpod, Flutter | Dio, SecureStorage, API URLs |
| Domain | Pure Dart | Flutter, HTTP, JSON |
| Data | Domain contracts, Dio, SecureStorage | Flutter widgets |
| External | HTTP, SQL | Flutter, Dart |

### Key Architectural Decisions

| Decision | Rationale |
|----------|-----------|
| **Feature-First** | All code for a feature lives in one folder. Easier to locate, add, or remove features. |
| **Riverpod** | Compile-safe state management. Catches provider lookup errors at build time. |
| **GoRouter** | URL-based navigation with auth guards. Enables deep linking and automatic redirects. |
| **JWT + SecureStorage** | Stateless auth with hardware encryption (Android Keystore / iOS Keychain). |
| **Event Bus for 401s** | Prevents circular dependency between Dio and AuthRepository. |
| **AutoDispose Providers** | Fresh data on every screen visit. No stale cache issues. |

---

## Getting Started

### Prerequisites

| Requirement | Version | Download |
|-------------|---------|----------|
| Flutter SDK | 3.6.0+ | [flutter.dev](https://flutter.dev) |
| Dart SDK | 3.6.0+ | Included with Flutter |
| Android Studio / VS Code | Latest | [developer.android.com](https://developer.android.com/studio) |
| .NET SDK | 8.0 | [dotnet.microsoft.com](https://dotnet.microsoft.com) |
| SQL Server | 2019+ | [microsoft.com/sql-server](https://www.microsoft.com/sql-server) |

### Backend Setup

1. **Clone the backend repository:**

```bash
git clone https://github.com/yourusername/bsm_scanner_api.git
cd bsm_scanner_api
```

2. **Update `appsettings.json`:**

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=BsmScannerDb;Trusted_Connection=True;TrustServerCertificate=True;"
  },
  "Jwt": {
    "Key": "your-super-secret-key-min-32-chars!",
    "Issuer": "BsmScannerApi",
    "Audience": "BsmScannerApp",
    "ExpiryMinutes": 60
  }
}
```

3. **Run migrations and start:**

```bash
dotnet ef database update
dotnet run
```

The API will be available at `http://localhost:5230`.

### Frontend Setup

1. **Clone the repository:**

```bash
git clone https://github.com/yourusername/bsm_scanner_app.git
cd bsm_scanner_app
```

2. **Install dependencies:**

```bash
flutter pub get
```

3. **Configure API URL** in `lib/core/config/environment_config.dart`:

| Environment | Device | Base URL |
|-------------|--------|----------|
| Development | Android Emulator | `http://10.0.2.2:5230` |
| Development | Physical Device | `http://192.168.1.100:5230` |
| Production | All | `https://api.yourdomain.com` |

4. **Run the app:**

```bash
# Development with hot reload
flutter run

# Production testing
flutter run --release

# Build APK
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release
```

---

## API Reference

### Authentication Endpoints

| Method | Endpoint | Request Body | Response | Auth Required |
|--------|----------|--------------|----------|---------------|
| `POST` | `/api/auth/login` | `{ "email": "", "password": "" }` | `{ "token": "jwt" }` | No |
| `POST` | `/api/auth/register` | `{ "email": "", "password": "", "displayName": "" }` | `{ "token": "jwt" }` | No |

### Product Endpoints

| Method | Endpoint | Request Body | Response | Auth Required |
|--------|----------|--------------|----------|---------------|
| `GET` | `/api/product` | — | `Product[]` | Yes |
| `GET` | `/api/product/:id` | — | `Product` | Yes |
| `POST` | `/api/product` | `{ "barcode": "", "productName": "", "notes": "", "barcodeType": "" }` | `201 Created` | Yes |
| `PUT` | `/api/product/:id` | `{ "productName": "", "notes": "" }` | `200 OK` | Yes |
| `DELETE` | `/api/product/:id` | — | `200 OK` | Yes |
| `GET` | `/api/product/count` | — | `int` | Yes |

### Product Model

| Field | Type | Description |
|-------|------|-------------|
| `id` | `int` | Auto-increment primary key |
| `barcode` | `string` | Scanned barcode value |
| `productName` | `string?` | User-editable name |
| `notes` | `string?` | User-added notes |
| `barcodeType` | `string` | Format (ean13, qrCode, etc.) |
| `scannedAt` | `datetime` | Scan timestamp |
| `userId` | `string` | ASP.NET Identity Guid |

### HTTP Status Codes

| Code | Meaning | Trigger |
|------|---------|---------|
| `200` | OK | Successful GET, PUT, DELETE |
| `201` | Created | Successful POST |
| `400` | Bad Request | Validation error |
| `401` | Unauthorized | Missing/invalid JWT |
| `404` | Not Found | Product doesn't exist |
| `409` | Conflict | Email already exists |
| `500` | Server Error | Unexpected exception |

---

## Authentication Flow

### Login Sequence

```
┌─────────────┐     Login Request      ┌─────────────┐
│    User     │ ─────────────────────► │  ASP.NET    │
│             │  {email, password}     │    API      │
└─────────────┘                        └──────┬──────┘
                                              │
                                              ▼
                                       ┌─────────────┐
                                       │  Validate   │
                                       │  Credentials│
                                       └──────┬──────┘
                                              │
                                              ▼
                                       ┌─────────────┐
                                       │  Generate   │
                                       │  JWT Token  │
                                       └──────┬──────┘
                                              │
┌─────────────┐     JWT Token          │     │
│   Flutter   │ ◄──────────────────────┘     │
│    App      │                                │
└──────┬──────┘                                │
       │                                       │
       ▼                                       │
┌─────────────┐                                │
│SecureStorage│  Store encrypted               │
│  Save Token │  (Android Keystore /           │
│             │   iOS Keychain)                │
└──────┬──────┘                                │
       │                                       │
       ▼                                       │
┌─────────────┐                                │
│  JwtParser  │  Decode token                  │
│ decodeUser()│  {sub, email, name, exp}       │
└──────┬──────┘                                │
       │                                       │
       ▼                                       │
┌─────────────┐                                │
│  StreamController                           │
│  .add(User) │  Broadcast to all listeners    │
└──────┬──────┘                                │
       │                                       │
       ▼                                       │
┌─────────────┐                                │
│  GoRouter   │  Detect auth state change      │
│  Redirect   │  /login ──► /home              │
└─────────────┘                                │
```

### Auto-Login on App Start

```
App Launches
    │
    ▼
AuthRepository._init()
    │
    ├──► Read token from SecureStorage
    │
    ├──► JwtParser.isExpired(token)?
    │    ├──► Yes ──► Delete token, broadcast null
    │    └──► No  ──► Decode user, broadcast User
    │
    ▼
GoRouter redirect evaluates
    │
    ├──► User != null ──► /home
    └──► User == null ──► /login
```

### 401 Auto-Logout

```
Any API Call
    │
    ▼
Dio Interceptor detects 401
    │
    ▼
AuthEvents.emitUnauthorized()
    │
    ▼
AuthRepository hears event
    │
    ├──► Delete token from SecureStorage
    ├──► Broadcast null on authStateChanges
    │
    ▼
GoRouter detects null user
    │
    ▼
Redirect /any ──► /login
```

---

## Data Flow

### Scan → Save → Database

```
Camera detects barcode
    │
    ▼
_showSaveDialog()
    │
    ▼
User taps "Save Scan"
    │
    ▼
_saveScan()
    │
    ├──► Create ProductEntity
    │    {id: 0, barcode, type, notes, scannedAt, userId}
    │
    ▼
ProductRepository.saveProduct()
    │
    ▼
Dio POST /api/product
    Authorization: Bearer <jwt>
    │
    ▼
ASP.NET API
    ├──► Validate JWT
    ├──► Read UserId from claims
    ├──► EF Core .Add(product)
    │
    ▼
SQL Server
    INSERT INTO Products
    │
    ▼
201 Created
    │
    ▼
SnackBar: "Scan saved!"
_scheduleCameraRestart()
```

---

## Screenshots



## Future Enhancements

| Feature | Priority | Description |
|---------|----------|-------------|
| Offline Support | High | Cache scans locally, sync when online |
| Barcode Lookup | High | Fetch product info from UPC Database |
| Export Data | Medium | CSV/Excel export of scan history |
| Search & Filter | Medium | Search scans by name or barcode |
| Dark Mode | Medium | Theme switching support |
| Push Notifications | Low | Inventory alerts and reminders |
| Multi-Language | Low | i18n support for global users |
| Unit Tests | High | Comprehensive test coverage |
| CI/CD Pipeline | Medium | Automated builds and deployments |

---

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### Code Style

| Rule | Enforcement |
|------|-------------|
| Dart formatting | `dart format .` |
| Linting | `flutter analyze` |
| Trailing commas | Required for clean diffs |
| Feature-first structure | All new features follow existing pattern |

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `JAVA_HOME` error | Set `JAVA_HOME` to JDK 17 path. Download from [Adoptium](https://adoptium.net/) |
| Camera permission denied | Add `<uses-permission android:name="android.permission.CAMERA" />` to `AndroidManifest.xml` |
| `Connection refused` | Verify API URL matches your backend address (emulator vs physical device) |
| Black screen after save | Camera restart uses `addPostFrameCallback` — ensure no context gaps |
| `BuildContext across async gaps` | Always check `mounted` before using `context` after `await` |

---

## Acknowledgments

| Resource | Link |
|----------|------|
| Flutter | [flutter.dev](https://flutter.dev) |
| Riverpod | [riverpod.dev](https://riverpod.dev) |
| Mobile Scanner | [pub.dev/packages/mobile_scanner](https://pub.dev/packages/mobile_scanner) |
| Dio | [pub.dev/packages/dio](https://pub.dev/packages/dio) |
| GoRouter | [pub.dev/packages/go_router](https://pub.dev/packages/go_router) |
| ASP.NET Core | [dotnet.microsoft.com/apps/aspnet](https://dotnet.microsoft.com/apps/aspnet) |

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <b>Built with ❤️ using Flutter & ASP.NET Core</b>
</p>

<p align="center">
  <a href="https://github.com/yourusername/bsm_scanner_app">GitHub</a> •
  <a href="https://github.com/yourusername/bsm_scanner_app/issues">Issues</a> •
  <a href="https://github.com/yourusername/bsm_scanner_app/discussions">Discussions</a>
</p>
