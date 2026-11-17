# Vehicle Management System — Frontend

The VMS frontend is a responsive Flutter application for viewing and maintaining a vehicle fleet. It communicates with the VMS Spring Boot REST API.

## Features

- **Fleet dashboard**
  - Summary cards for total vehicles, active vehicles, vehicles in maintenance, vehicles in transit, and electric vehicles.
  - A recent fleet activity table showing up to five vehicles.
  - Fleet fuel/powertrain distribution for electric, hybrid, diesel, and petrol vehicles.
- **Vehicle inventory**
  - List vehicles in a desktop data table or mobile-friendly cards.
  - Search by vehicle name, license plate, VIN, assigned driver, or department.
  - Filter by operational status and vehicle category.
  - Client-side pagination with five vehicles per page.
  - Empty, loading, connection-error, and retry states.
- **Vehicle management**
  - Register, edit, and delete vehicles.
  - Confirm before deleting a vehicle.
  - Capture make, model, model year, license plate, VIN, category, status, fuel type, mileage, assigned driver, department, and notes.
  - Display backend validation errors and a friendly message when a vehicle number is already registered.
- **Responsive admin interface**
  - Material 3 styling with desktop sidebar navigation and mobile navigation drawer.
  - Dashboard and fleet views adapt to desktop, tablet, and mobile screen sizes.

## Technology Stack

- Flutter and Dart (the SDK constraint is specified in `pubspec.yaml`).
- Material 3 widgets.
- `http` package for REST API requests.
- Flutter Test for widget and service tests.

## Backend Connection

The API client is `lib/services/vehicle_api_service.dart`. Its current base URL is:

```text
http://localhost:8080/api/vehicles
```

Run the backend locally before using fleet features. For another host, device, or deployment, update the base URL to the address reachable from the frontend. The frontend calls the vehicle list, create, update, and delete endpoints and handles validation and API error responses.

## Getting Started

### Prerequisites

- Flutter SDK installed, with a Dart SDK compatible with the constraint in `pubspec.yaml`.
- The VMS backend running for API-backed vehicle data.

### Install and Run

From the frontend project directory:

```bash
flutter pub get
flutter run -d chrome
```

Alternatively, run `flutter run` and select an available device.

### Quality Checks

```bash
flutter analyze
flutter test
flutter build web
```

## Project Structure

```text
lib/
  core/       Routes, theme, and responsive helpers
  models/     User and vehicle data models
  screens/    Login, dashboard, app shell, and vehicle views
  services/   Demo authentication and vehicle API client
  widgets/    Shared dashboard and vehicle UI components
test/         Widget and API service tests
web/          Flutter web entry point and assets
```