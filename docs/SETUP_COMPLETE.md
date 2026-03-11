# RakshaPoorvak – Setup Status & Next Steps

## ✅ Completed

### 1. Java 17 (openjdk@17)
- **Installed via:** `brew install openjdk@17`
- **Location:** `/opt/homebrew/opt/openjdk@17`
- **Add to PATH:** See [Add to Shell](#add-to-shell) below

### 2. Maven
- **Installed via:** `brew install maven`
- **Location:** `/opt/homebrew/bin/mvn`
- Already in PATH if Homebrew is in PATH

### 3. Spring Boot Backend
- **Location:** `backend/`
- **Structure:** Minimal Spring Boot 3.2.5 project with:
  - Health endpoint: `GET /api/health`
  - Security configured (health is public)
  - PostgreSQL config in `application-dev.yml`
- **Verify:** `cd backend && mvn clean compile` (with JAVA_HOME set)

### 4. PATH Setup Script
- **Script:** `scripts/setup-path.sh`
- **Additions for ~/.zshrc:** `scripts/zshrc-additions.txt`

---

## 🔄 In Progress / Manual Steps

### Flutter
- **Status:** Initial install failed (download timeout). **Run manually in Terminal:**
  ```bash
  brew install --cask flutter
  ```
- **Add to PATH:** The zshrc additions include Flutter path detection.

### Android Studio
- **Status:** Install was started (large download).
- **Check:** Run `brew list --cask android-studio` to see if installed.
- **If not installed:** Run manually:
  ```bash
  brew install --cask android-studio
  ```
- **After install:**
  1. Open Android Studio once (setup wizard)
  2. **More Actions → SDK Manager** → Install: SDK Platform (API 34), Build-Tools, Command-line Tools, Emulator, Platform-Tools
  3. **More Actions → Virtual Device Manager** → Create an AVD
  4. Run: `flutter doctor --android-licenses` (accept all)

### PostgreSQL
- **Your note:** Already installed.
- **Verify:** `psql --version` and `psql postgres -c "SELECT 1"`
- **Start if needed:** `brew services start postgresql` or `brew services start postgresql@15`

### pgAdmin
- Already available per your note.

---

## Add to Shell

Run this to add all PATH and env vars to your `~/.zshrc`:

```bash
cat /Users/harshgorakhkhairnar/personal/major-project-26/scripts/zshrc-additions.txt >> ~/.zshrc
source ~/.zshrc
```

Or manually add the contents of `scripts/zshrc-additions.txt` to `~/.zshrc`.

---

## Verification Commands

After setup, run:

```bash
# Java
java -version
echo $JAVA_HOME

# Maven
mvn -version

# Flutter (after install)
flutter --version
flutter doctor

# PostgreSQL
psql --version
psql postgres -c "SELECT 1"

# Backend
cd backend && mvn spring-boot:run
# In another terminal: curl http://localhost:8080/api/health
```

---

## Monorepo Structure

```
major-project-26/
├── backend/          ✅ Spring Boot project created
├── docs/
├── scripts/          ✅ setup-path.sh, zshrc-additions.txt
├── hospital-dashboard/  (to be created - React + Vite)
├── user-app/            (to be created - Flutter)
└── driver-app/          (to be created - Flutter)
```

---

## Next: Development

Once Flutter and Android Studio are installed and `flutter doctor` passes:

1. Create Flutter projects: `user-app` and `driver-app`
2. Create React project: `hospital-dashboard`
3. Connect backend to your PostgreSQL DB (update `application-dev.yml` if needed)
4. Start coding per the PRD and CODING_RULES.
