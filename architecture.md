# UPI Transaction Tracker - Architecture Document

## Overview
Privacy-first, local-only UPI Transaction Tracker MVP built with Flutter. All data remains encrypted on device with PIN/biometric security.

## Core Principles
- **Privacy-first**: No data leaves device by default
- **Local-only**: Encrypted local database with SQLCipher
- **Security**: PIN/biometric protection with auto-lock
- **Accessibility**: Modern UI with responsive design

## Technical Stack
- **Framework**: Flutter with Dart null-safety
- **State Management**: Riverpod
- **Local Database**: Drift with SQLCipher encryption
- **Authentication**: local_auth + flutter_secure_storage
- **Platform**: Android primary (SMS parsing), iOS manual import

## Architecture Layers

### 1. Presentation Layer (UI)
- **Onboarding**: Welcome + permission explanation screens
- **Authentication**: PIN setup + biometric lock screen
- **Dashboard**: Summary cards, spending charts, top merchants
- **Transactions**: List, detail, add/edit forms
- **Import**: Manual SMS paste parser + OCR placeholder
- **Settings**: Security, export, data management
- **Debug**: Mock data toggle (hidden in production)

### 2. Business Logic Layer (Providers)
- **TransactionProvider**: CRUD operations, filtering, search
- **SettingsProvider**: App preferences, security settings
- **AuthProvider**: PIN validation, biometric state

### 3. Service Layer
- **AuthService**: PIN/biometric authentication
- **StorageService**: Encrypted database operations
- **MLService**: Transaction parsing (mock + regex)
- **SMSService**: Android SMS listener (platform channel)
- **NotificationService**: Android notification parsing
- **ExportService**: Encrypted JSON/CSV export

### 4. Data Layer
- **Models**: Transaction, Settings, User data classes
- **Database**: Drift tables with relationships
- **Repository**: Data access abstraction

## Security Implementation
- **Encryption**: Field-level AES with flutter_secure_storage keys
- **Authentication**: PIN (6-digit) + biometric fallback
- **Auto-lock**: Configurable timeout periods
- **Secure Export**: Password-based AES for export files

## Platform-Specific Features

### Android
- SMS broadcast receiver for transaction detection
- Notification listener service for banking apps
- System permission handling with rationale

### iOS
- Manual import workflows (paste/OCR)
- Explicit messaging about SMS limitations
- Alternative transaction entry methods

## Future Extension Points
- Cloud sync hooks (commented placeholders)
- API service stubs for server integration
- Federated learning preparation
- Multi-language support preparation

## File Structure
```
lib/src/
├── app.dart (Main app configuration)
├── routes.dart (Navigation routes)
├── core/ (Constants, theme, utilities)
├── features/ (Feature modules)
├── data/ (Models, database, repositories)
├── services/ (Business services)
└── providers/ (State management)
```

## MVP Acceptance Criteria
1. ✓ Onboarding flow with permission explanations
2. ✓ PIN/biometric authentication
3. ✓ Local encrypted data storage
4. ✓ Transaction CRUD operations
5. ✓ SMS parsing with mock ML
6. ✓ Encrypted data export
7. ✓ No network calls (privacy-first)
8. ✓ Mock data mode for demos
9. ✓ Comprehensive testing
10. ✓ CI/CD pipeline configuration