#!/bin/bash
# RakshaPoorvak - Prerequisites checker
# Run this to verify you have all required tools installed

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REQUIRED_MISSING=0
OPTIONAL_MISSING=0

check_required() {
    local name=$1
    local cmd=$2
    local version_cmd=$3
    local install_hint=$4
    local min_version=$5

    echo -n "Checking $name... "

    if command -v "$cmd" &> /dev/null; then
        if [ -n "$version_cmd" ]; then
            version=$(eval "$version_cmd" 2>/dev/null || echo "unknown")
            echo -e "${GREEN}✔ Found${NC} ($version)"
        else
            echo -e "${GREEN}✔ Found${NC}"
        fi
    else
        echo -e "${RED}✖ Not found${NC}"
        echo -e "  ${YELLOW}Install: $install_hint${NC}"
        ((REQUIRED_MISSING++))
    fi
}

check_optional() {
    local name=$1
    local cmd=$2
    local version_cmd=$3
    local install_hint=$4

    echo -n "Checking $name... "

    if command -v "$cmd" &> /dev/null; then
        if [ -n "$version_cmd" ]; then
            version=$(eval "$version_cmd" 2>/dev/null || echo "unknown")
            echo -e "${GREEN}✔ Found${NC} ($version)"
        else
            echo -e "${GREEN}✔ Found${NC}"
        fi
    else
        echo -e "${YELLOW}○ Not found (optional)${NC}"
        echo -e "  ${YELLOW}Install: $install_hint${NC}"
        ((OPTIONAL_MISSING++))
    fi
}

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  RakshaPoorvak - Prerequisites Check${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}Required:${NC}"
echo ""

check_required "Java 17+" "java" "java -version 2>&1 | head -1 | cut -d'\"' -f2" "brew install openjdk@17"
check_required "Maven" "mvn" "mvn -version 2>&1 | head -1 | awk '{print \$3}'" "brew install maven"
check_required "Node.js 18+" "node" "node -v" "brew install node"
check_required "npm" "npm" "npm -v" "comes with Node.js"
check_required "Docker" "docker" "docker -v | awk '{print \$3}' | tr -d ','" "Install Docker Desktop or Rancher Desktop"
check_required "Git" "git" "git --version | awk '{print \$3}'" "brew install git"

echo ""
echo -e "${BLUE}Optional (for mobile development):${NC}"
echo ""

check_optional "Flutter" "flutter" "flutter --version 2>&1 | head -1 | awk '{print \$2}'" "https://flutter.dev/docs/get-started/install"
check_optional "Android SDK" "adb" "adb --version 2>&1 | head -1" "Install Android Studio"
check_optional "Xcode" "xcodebuild" "xcodebuild -version 2>&1 | head -1" "Install from App Store (Mac only)"

echo ""
echo -e "${BLUE}Optional (useful tools):${NC}"
echo ""

check_optional "psql" "psql" "psql --version | awk '{print \$3}'" "brew install postgresql@15"
check_optional "jq" "jq" "jq --version" "brew install jq"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

# Check if Docker is running
echo ""
echo -n "Checking Docker daemon... "
if docker info &> /dev/null; then
    echo -e "${GREEN}✔ Running${NC}"
else
    echo -e "${RED}✖ Not running${NC}"
    echo -e "  ${YELLOW}Please start Docker Desktop or Rancher Desktop${NC}"
    ((REQUIRED_MISSING++))
fi

# Summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

if [ $REQUIRED_MISSING -eq 0 ]; then
    echo -e "${GREEN}All required prerequisites are installed!${NC}"
    if [ $OPTIONAL_MISSING -gt 0 ]; then
        echo -e "${YELLOW}$OPTIONAL_MISSING optional tools are missing (only needed for mobile dev).${NC}"
    fi
    echo ""
    echo "You can proceed with setup:"
    echo "  ./scripts/setup.sh"
    exit 0
else
    echo -e "${RED}$REQUIRED_MISSING required prerequisites are missing.${NC}"
    echo ""
    echo "Please install the missing tools, then run this script again."
    echo ""
    echo "Quick install (macOS with Homebrew):"
    echo "  brew install openjdk@17 maven node git"
    echo ""
    echo "Don't forget to add Java to your PATH:"
    echo "  export PATH=\"/opt/homebrew/opt/openjdk@17/bin:\$PATH\""
    echo "  export JAVA_HOME=\"/opt/homebrew/opt/openjdk@17\""
    exit 1
fi
