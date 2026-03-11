#!/bin/bash
# RakshaPoorvak - Environment PATH Setup
# Append these lines to ~/.zshrc (or run: source scripts/setup-path.sh)

# Homebrew (Apple Silicon)
eval "$(/opt/homebrew/bin/brew shellenv)"

# Java 17 (openjdk@17)
export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
export PATH="$JAVA_HOME/bin:$PATH"

# Maven (already in brew path, but ensure it's available)
export PATH="/opt/homebrew/bin:$PATH"

# Flutter (installed via brew cask)
# Flutter is typically at: /opt/homebrew/Caskroom/flutter/<version>/flutter/bin
if [ -d "/opt/homebrew/Caskroom/flutter" ]; then
  FLUTTER_VERSION=$(ls /opt/homebrew/Caskroom/flutter 2>/dev/null | tail -1)
  if [ -n "$FLUTTER_VERSION" ]; then
    export PATH="/opt/homebrew/Caskroom/flutter/$FLUTTER_VERSION/flutter/bin:$PATH"
  fi
fi

# Android SDK (set after installing Android Studio)
# Add after first run of Android Studio + SDK setup:
if [ -d "$HOME/Library/Android/sdk" ]; then
  export ANDROID_HOME="$HOME/Library/Android/sdk"
  export PATH="$ANDROID_HOME/emulator:$PATH"
  export PATH="$ANDROID_HOME/platform-tools:$PATH"
fi

# PostgreSQL (if installed via brew - already in path)
# export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"

echo "Environment loaded. Java: $(java -version 2>&1 | head -1)"
echo "Maven: $(mvn -version 2>&1 | head -1)"
echo "Flutter: $(flutter --version 2>&1 | head -1 || echo 'Not installed')"
