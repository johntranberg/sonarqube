#!/bin/bash

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker first."
    echo "Visit https://docs.docker.com/get-docker/ for installation instructions."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker compose &> /dev/null; then
    echo "Error: Docker Compose is not installed. Please install Docker Compose first."
    echo "Visit https://docs.docker.com/compose/install/ for installation instructions."
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Attempting to install..."
    
    if command -v brew &> /dev/null; then
        # macOS with Homebrew
        brew install jq
    elif command -v apt-get &> /dev/null; then
        # Debian/Ubuntu
        sudo apt-get update && sudo apt-get install -y jq
    elif command -v yum &> /dev/null; then
        # RHEL/CentOS
        sudo yum install -y jq
    elif command -v apk &> /dev/null; then
        # Alpine
        apk add --no-cache jq
    else
        echo "Error: Could not install jq automatically."
        echo "Please install jq manually: https://stedolan.github.io/jq/download/"
        exit 1
    fi
fi

# Pull required Docker images
echo "Pulling required Docker images..."
docker pull sonarqube:latest
docker pull sonarsource/sonar-scanner-cli:latest

# Create necessary directories
echo "Creating necessary directories..."
mkdir -p "$PROJECT_ROOT/.scannerwork"

# Make scripts executable
echo "Making scripts executable..."
chmod +x "$PROJECT_ROOT/bin"/*.sh

# Check if config file exists
if [ ! -f "$PROJECT_ROOT/config/sonar-config.json" ]; then
    echo "Creating sonar-config.json from example..."
    cp "$PROJECT_ROOT/config/sonar-config.example.json" "$PROJECT_ROOT/config/sonar-config.json"
fi

echo "Setup complete! You can now run './bin/run-analysis.sh <target_directory>' to analyze your code."
echo "Note: On first run, you'll need to:"
echo "1. Wait for SonarQube to fully initialize (this may take a few minutes)"
echo "2. Visit http://localhost:9000"
echo "3. Login with default credentials (admin/admin)"
echo "4. Change the password when prompted"
echo "5. Create a token in SonarQube: http://localhost:9000/account/security/ and update it in config/sonar-config.json"
