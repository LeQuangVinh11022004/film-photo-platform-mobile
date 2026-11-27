<div align="center">
  <img src="assets/images/logo.png" alt="AnalogAI Logo" width="140"/>
  <h1>AnalogAI — Film Photography Platform</h1>
  <p><strong>The Ultimate Mobile Ecosystem for Film Photographers & Lab Experts</strong></p>

  <p>
    <a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Flutter-3.47.2-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"></a>
    <a href="https://dart.dev/"><img src="https://img.shields.io/badge/Dart-3.13.2+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"></a>
    <a href="https://dotnet.microsoft.com/"><img src="https://img.shields.io/badge/Backend-ASP.NET_Core_9.0-512BD4?style=for-the-badge&logo=dotnet&logoColor=white" alt="ASP.NET Core"></a>
    <a href="https://azure.microsoft.com/"><img src="https://img.shields.io/badge/Cloud-Microsoft_Azure-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white" alt="Azure"></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge" alt="License: MIT"></a>
    <a href="CODE_OF_CONDUCT.md"><img src="https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg?style=for-the-badge" alt="Code of Conduct"></a>
    <a href="https://github.com/GFA26SE169_FA26SE091"><img src="https://img.shields.io/badge/Capstone-GFA26SE169__FA26SE091-2ea44f?style=for-the-badge&logo=github&logoColor=white" alt="Capstone Project"></a>
  </p>
</div>

---

## 📖 Table of Contents
- [📸 Overview](#-overview)
- [✨ Key Features](#-key-features)
- [🏗️ System Architecture](#️-system-architecture)
- [🛠️ Tech Stack](#️-tech-stack)
- [🌐 Backend & Deployment](#-backend--deployment)
- [🚀 Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation & Build](#installation--build)
  - [Default Test Credentials](#default-test-credentials)
- [🧪 Automated API Testing & Diagnostics](#-automated-api-testing--diagnostics)
- [🤝 GitHub Community Standards & Contributing](#-github-community-standards--contributing)
- [📄 License & Credits](#-license--credits)

---

## 📸 Overview
**AnalogAI** is a mobile platform bridging analog photography traditions with modern digital services. Designed specifically for film enthusiasts, studio owners, and lab technicians, it simplifies finding darkrooms, renting specialized cameras/lenses, booking expert consultations, and exploring AI-assisted film recipes and restoration.

Whether you are looking to develop your first roll of B&W 35mm film or seeking an advanced large-format workspace, AnalogAI provides an intuitive, end-to-end mobile experience.

---

## ✨ Key Features

| Feature | Description |
|---|---|
| 🏢 **Studio & Darkroom Booking** | Browse spaces, inspect darkroom equipment (enlargers, chemistry baths), check calendar availability, and reserve time slots. |
| 💳 **VNPay Deposit Payments** | Integrated with VNPay Sandbox to secure bookings with initial deposits and verified transaction references. |
| 👨‍🏫 **Expert Mentorship & Workshops** | Connect with experienced film lab technicians and analog artists for 1-on-1 consultations or technique masterclasses. |
| 🤖 **AI Analog Assistant** | AI-powered guidance on shooting conditions, film stock exposure recipes (Push/Pull), and negative restoration techniques. |
| 💬 **Community Forum & Showcase** | Share film photographs, exchange chemical processing recipes, and interact with the local analog community. |
| 🔔 **Local & In-App Notifications** | Instant alerts for booking status updates, payment confirmations, and scheduled studio sessions. |
| 📴 **Offline Mock Mode** | Built-in fallback system that enables smooth app review and UI testing even when internet access or remote APIs are offline. |

---

## 🏗️ System Architecture

The project follows a **Feature-First Clean Architecture** for maintainability, high testability, and clear separation of concerns:

```text
film_photography_platform/
├── android/                    # Android native configuration, Gradle 9.5, NDK 28
├── ios/                        # iOS Xcode project & configuration
├── assets/                     # Images, brand logos, icons, vector graphics
├── tools/                      # Engineering automation tools
│   └── api_test/
│       └── run_api_tests.ps1   # Automated PowerShell API test suite (25 endpoints)
├── lib/
│   ├── app/                    # App initialization, main.dart, app routing
│   ├── core/                   # Core shared infrastructure
│   │   ├── network/            # ApiClient singleton, HTTP interceptors, token management
│   │   ├── services/           # Local notification service, persistent storage
│   │   ├── theme/              # Color palette, typography, light & dark theme definitions
│   │   ├── utils/              # Formatters, currency/date utilities, image helpers
│   │   └── widgets/            # Reusable widgets (CustomButtons, Dialogs, Spinners)
│   └── features/               # Modular business features
│       ├── ai_tools/           # AI Photography Guide & negative restoration screens
│       ├── auth/               # Authentication (Login, Register, Session token storage)
│       ├── booking/            # Studio/Space calendar, time slot picker, booking state
│       ├── community/          # Community feed, discussion threads, photo sharing
│       ├── expert/             # Expert profiles, workshop listings, Q&A consultations
│       ├── home/               # Bottom navigation, dashboard, discovery cards
│       ├── notifications/      # In-app notification center
│       ├── payment/            # Payment gateway checkout, VNPay webview, deposit receipt
│       └── profile/            # User profile, history, settings
└── summary.log                 # Latest automated test report across all backend APIs
```

---

## 🛠️ Tech Stack

### Mobile Client (Frontend)
- **Framework:** [Flutter](https://flutter.dev/) (SDK 3.47.2)
- **Language:** [Dart](https://dart.dev/) (SDK >= 3.13.2 < 4.0.0)
- **UI & Design:** Material 3, [Google Fonts](https://pub.dev/packages/google_fonts), [Toastification](https://pub.dev/packages/toastification), [Flutter Animate](https://pub.dev/packages/flutter_animate)
- **Networking:** `http` package with centralized `ApiClient` (bearer token injection, SSL bypass for emulators)
- **Local Database & Cache:** [sqflite](https://pub.dev/packages/sqflite), [cached_network_image](https://pub.dev/packages/cached_network_image)
- **Device Features:** [image_picker](https://pub.dev/packages/image_picker), [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)

### Cloud Backend
- **Platform:** ASP.NET Core 9.0 Web API
- **Deployment:** [Microsoft Azure App Services](https://azure.microsoft.com/)
- **Database:** Entity Framework Core (PostgreSQL / Azure SQL)
- **Payment Gateway:** VNPay Sandbox API

---

## 🌐 Backend & Deployment

The app is pre-configured to communicate with the deployed Azure cloud backend:

* **Production Base URL:**
  ```text
  https://filmbooking-api-h7bghwcydwb8eecn.japaneast-01.azurewebsites.net
  ```
* **Configuration File:** [`lib/core/network/api_client.dart`](lib/core/network/api_client.dart)
* **Offline Mock Fallback:** If the backend is temporarily unreachable, the app automatically transitions to mock mode so UI workflows and navigation remain fully functional.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.47.2)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter extensions
- Android SDK with **NDK `28.2.13676358`** installed (`cmdline-tools` -> `sdkmanager "ndk;28.2.13676358"`)
- Physical Android device (USB Debugging enabled) or Android Emulator

### Installation & Build

1. **Clone the repository:**
   ```bash
   git clone https://github.com/GFA26SE169_FA26SE091/film_photography_platform.git
   cd film_photography_platform
   ```

2. **Fetch dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify Flutter environment:**
   ```bash
   flutter doctor
   ```

4. **Run the App in Debug mode:**
   ```bash
   flutter run -t lib/app/main.dart
   ```

5. **Build Release APK:**
   ```bash
   flutter build apk --release
   ```
   The generated APK will be available at: `build/app/outputs/flutter-apk/app-release.apk`

---

### Authentication and Community

Sign in with a username and password. Photographer registration requires a
username, email address, and an 8–72 character password. Use the credentials
provided by the backend team for existing accounts.

Photographers and experts share the community post feed and can manage their
own posts. Post images currently require an accessible HTTP(S) URL; the
backend does not provide an image upload endpoint.

---

## 🧪 Automated API Testing & Diagnostics

A pure PowerShell automated test harness is provided to verify connectivity and compliance against all backend endpoints without requiring Python:

```powershell
# Run the complete test suite against Azure Backend
powershell -ExecutionPolicy Bypass -File tools\api_test\run_api_tests.ps1
```

The script exercises **25 distinct scenarios** (Auth registration, login, studio listings, slot availability, booking creation, VNPay deposit initialization, and AI guide) and outputs a consolidated audit log:
- **Comprehensive Report:** [`summary.log`](summary.log)
- **Markdown Summary:** [`test_logs/api/<timestamp>/SUMMARY.md`](test_logs/api/)

---

## 🤝 GitHub Community Standards & Contributing

We welcome contributions from the community! This project adheres to GitHub's Community Standards:

- 📜 **[Code of Conduct](CODE_OF_CONDUCT.md):** Our standards for a welcoming, inclusive, and harassment-free community (Contributor Covenant v2.1).
- 🛠️ **[Contributing Guidelines](CONTRIBUTING.md):** Guidelines for branch naming, coding style, clean architecture, and pull requests.
- 🐛 **[Bug Reports](.github/ISSUE_TEMPLATE/bug_report.md):** Use our standardized issue template to submit reproducible bugs.
- 💡 **[Feature Requests](.github/ISSUE_TEMPLATE/feature_request.md):** Propose new enhancements and features.
- 🔀 **[Pull Request Template](.github/PULL_REQUEST_TEMPLATE.md):** Checklist for submitting clean, well-tested PRs.
- 🔒 **[Security Policy](SECURITY.md):** Vulnerability reporting and responsible disclosure.

---

## 📄 License & Credits

- **License:** This project is licensed under the [MIT License](LICENSE).
- **Capstone Course:** GFA26SE169 — FA26SE091 Capstone Project.
- **Developed by:** AnalogAI Mobile Development Team.

<div align="center">
  <sub>Built with ❤️ for the analog photography and darkroom community.</sub>
</div>
