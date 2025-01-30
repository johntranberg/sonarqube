#!/bin/bash

# Check if target directory is provided
if [ -z "$1" ]; then
    echo "Usage: ./bin/run-analysis.sh <target_directory>"
    exit 1
fi

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Read configuration
CONFIG_FILE="$PROJECT_ROOT/config/sonar-config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Parse JSON config using jq (make sure jq is installed)
SONAR_HOST=$(jq -r '.sonar.host' "$CONFIG_FILE")
SONAR_TOKEN=$(jq -r '.sonar.token' "$CONFIG_FILE")

if [ "$SONAR_TOKEN" = "YOUR_SONAR_TOKEN" ]; then
    echo "Error: Please update the token in config/sonar-config.json"
    echo "You can generate a token in SonarQube: $SONAR_HOST/account/security/"
    exit 1
fi

TARGET_DIR=$(realpath "$1")
PROJECT_NAME=$(basename "$TARGET_DIR")

# Start SonarQube
echo "Starting SonarQube..."
docker compose -f "$PROJECT_ROOT/docker-compose.yml" up -d sonarqube

# Wait for SonarQube to be ready
echo "Waiting for SonarQube to be ready..."
while ! curl -s "$SONAR_HOST" > /dev/null; do
    sleep 5
done

# Wait a bit more for full initialization
sleep 30

# Run analysis
echo "Running analysis on $TARGET_DIR..."
docker run --rm \
    --network="host" \
    -v "${TARGET_DIR}:/usr/src" \
    sonarsource/sonar-scanner-cli \
    -Dsonar.projectKey=$PROJECT_NAME \
    -Dsonar.sources=/usr/src \
    -Dsonar.host.url=$SONAR_HOST \
    -Dsonar.token=$SONAR_TOKEN

echo "Analysis complete. Visit $SONAR_HOST to view results."
