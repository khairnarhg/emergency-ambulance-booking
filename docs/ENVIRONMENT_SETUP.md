# RakshaPoorvak – Environment Setup & Prerequisites

This document provides the complete environment setup required to develop RakshaPoorvak on macOS. Follow these steps **before** starting development.

---

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Prerequisites Overview](#prerequisites-overview)
3. [Step-by-Step Installation (macOS)](#step-by-step-installation-macos)
4. [Verification](#verification)
5. [Optional Tools](#optional-tools)
6. [Environment Variables](#environment-variables)
7. [Troubleshooting](#troubleshooting)

---

## System Requirements

| Requirement | Minimum |
|-------------|---------|
| OS | macOS 10.14 (Mojave) or later (Catalina+ recommended) |
| RAM | 8 GB (16 GB recommended for Android emulator) |
| Storage | ~20 GB free (Xcode + Android SDK add significant space) |
| Architecture | Intel or Apple Silicon (M1/M2/M3) |

---

## Prerequisites Overview

| Tool | Version | Used By |
|------|---------|---------|
| **Homebrew** | Latest | Package manager for macOS |
| **Java (JDK)** | 17+ | Spring Boot backend |
| **Maven** | 3.9+ | Spring Boot build tool |
| **Node.js** | 20 LTS | Hospital Dashboard (React + Vite) |
| **npm** | 10+ | Hospital Dashboard package manager |
| **Flutter** | 3.16+ | User App & Driver App (mobile) |
| **PostgreSQL** | 15+ | Database |
| **Git** | 2.x | Version control |
| **Android Studio** | Latest | Android SDK (for Flutter Android builds) |
| **Xcode** | Latest (optional for iOS) | iOS builds (future) |

---

## Step-by-Step Installation (macOS)

### 1. Install Homebrew (if not already installed)

Homebrew is the package manager used for most installations.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Apple Silicon:** After install, add Homebrew to PATH:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**Verify:**
```bash
brew --version
```

---

### 2. Install Xcode Command Line Tools (required for compilers)

```bash
xcode-select --install
```

Accept the license when prompted:
```bash
sudo xcodebuild -license accept
```

---

### 3. Install Java 17 (JDK)

**Recommended: Eclipse Temurin (Adoptium)**

```bash
brew update
brew install --cask temurin@17
```

**Verify:**
```bash
java -version
# Should show: openjdk version "17.x.x"
```

**Set JAVA_HOME (add to `~/.zshrc`):**
```bash
echo 'export JAVA_HOME=$(/usr/libexec/java_home -v 17)' >> ~/.zshrc
source ~/.zshrc
```

---

### 4. Install Maven

```bash
brew install maven
```

**Verify:**
```bash
mvn -version
```

---

### 5. Install Node.js (LTS)

```bash
brew install node
```

**Verify:**
```bash
node -v   # v20.x or higher
npm -v    # 10.x or higher
```

---

### 6. Install PostgreSQL

```bash
brew install postgresql@15
```

**Link and add to PATH:**
```bash
brew link postgresql@15 --force
echo 'export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Start PostgreSQL:**
```bash
brew services start postgresql@15
```

**Verify:**
```bash
psql --version
```

**Create project database:**
```bash
psql postgres -c "CREATE USER rakshapoorvak WITH PASSWORD 'dev_password';"
psql postgres -c "CREATE DATABASE rakshapoorvak_dev OWNER rakshapoorvak;"
```

*(Change the password for production.)*

---

### 7. Install Flutter

```bash
brew install --cask flutter
```

**Verify:**
```bash
flutter --version
flutter doctor
```

**Fix common issues:**
- If Android license not accepted: `flutter doctor --android-licenses`
- For Apple Silicon: `sudo softwareupdate --install-rosetta --agree-to-license` (if prompted)

---

### 8. Install Android Studio (for Flutter Android development)

1. Download from [developer.android.com/studio](https://developer.android.com/studio)
2. Or: `brew install --cask android-studio`
3. Open Android Studio → **More Actions** → **SDK Manager**
4. Install:
   - Android SDK Platform (API 34 recommended)
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android Emulator
   - Android SDK Platform-Tools

5. Add to `~/.zshrc`:
```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
```
6. Run `source ~/.zshrc` and `flutter doctor` again.

---

### 9. Install Git (if not present)

```bash
brew install git
git --version
```

---

## Verification

Run the following to ensure everything is ready:

```bash
# Java
java -version
mvn -version

# Node & npm
node -v
npm -v

# PostgreSQL
psql --version
brew services list | grep postgresql

# Flutter
flutter doctor
flutter doctor -v
```

**Expected `flutter doctor` output:**
- [✓] Flutter
- [✓] Android toolchain
- [✓] Android Studio (if installed)
- [ ] Xcode (optional for iOS)
- [ ] Chrome (optional for web)

---

## Optional Tools

| Tool | Purpose | Install |
|------|---------|---------|
| **Docker** | Run PostgreSQL/Backend in containers | `brew install docker` |
| **Postman / Insomnia** | API testing | `brew install --cask postman` |
| **DBeaver / pgAdmin** | Database GUI | `brew install --cask dbeaver-community` |
| **Android Emulator** | Test Flutter apps | Via Android Studio |
| **VS Code / Cursor** | IDE | `brew install --cask cursor` |

---

## Environment Variables

### Backend (`backend/.env` or `application-dev.yml`)

```yaml
# Database
spring.datasource.url=jdbc:postgresql://localhost:5432/rakshapoorvak_dev
spring.datasource.username=rakshapoorvak
spring.datasource.password=dev_password

# JWT
jwt.secret=your-jwt-secret-key-min-256-bits
jwt.expiration=86400000
```

### Hospital Dashboard (`hospital-dashboard/.env.local`)

```
VITE_API_URL=http://localhost:8080
VITE_WS_URL=ws://localhost:8080/ws
```

### User App & Driver App (`lib/core/constants/env.dart` or `.env`)

```
API_BASE_URL=http://10.0.2.2:8080   # Android emulator → localhost
WS_URL=ws://10.0.2.2:8080/ws
```

---

## Troubleshooting

### Java not found after install
```bash
/usr/libexec/java_home -V
# Add correct path to JAVA_HOME in ~/.zshrc
```

### PostgreSQL connection refused
```bash
brew services start postgresql@15
# Check: brew services list
```

### Flutter doctor shows Android issues
```bash
flutter doctor --android-licenses
# Accept all with 'y'
```

### Maven build fails
- Ensure Java 17: `java -version`
- Clean: `mvn clean install`

### npm / Node version conflicts
- Use `nvm` for version management: `brew install nvm`
- Or reinstall: `brew reinstall node`

### Android emulator not starting
- Enable virtualization in BIOS (Intel) or use Apple Silicon native images
- In Android Studio: AVD Manager → Create Virtual Device

---

## Quick Reference: Run Order

When developing, start services in this order:

1. **PostgreSQL** – `brew services start postgresql@15`
2. **Backend** – `cd backend && mvn spring-boot:run`
3. **Hospital Dashboard** – `cd hospital-dashboard && npm run dev`
4. **User/Driver App** – `cd user-app && flutter run` (with emulator or device)

---

*Last updated: February 2025*
