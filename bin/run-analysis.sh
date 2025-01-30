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

# Check for Java project and compiled classes
JAVA_FILES=$(find "$TARGET_DIR" -name "*.java" -type f)
ADDITIONAL_ARGS=""

if [ ! -z "$JAVA_FILES" ]; then
    echo "Java files detected, looking for compiled classes..."
    
    # Common build directories for Java projects
    POSSIBLE_BUILD_DIRS=(
        "target/classes"
        "build/classes"
        "out/production"
        "bin"
    )
    
    for BUILD_DIR in "${POSSIBLE_BUILD_DIRS[@]}"; do
        if [ -d "$TARGET_DIR/$BUILD_DIR" ]; then
            echo "Found compiled classes in $BUILD_DIR"
            ADDITIONAL_ARGS="$ADDITIONAL_ARGS -Dsonar.java.binaries=/usr/src/$BUILD_DIR"
            break
        fi
    done
    
    if [ -z "$ADDITIONAL_ARGS" ]; then
        echo "Warning: Java files found but no compiled classes detected."
        echo "Please compile your Java project before running the analysis,"
        echo "or use -Dsonar.java.binaries to specify the location of compiled classes,"
        echo "or use -Dsonar.exclusions to exclude Java files from analysis."
        echo ""
        echo "Common build commands:"
        echo "Maven: mvn compile"
        echo "Gradle: ./gradlew classes"
        echo ""
        read -p "Do you want to continue without Java analysis? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
        ADDITIONAL_ARGS="-Dsonar.exclusions=**/*.java"
    fi
fi

# Detect Git branch if in a Git repository
if [ -d "$TARGET_DIR/.git" ] || git -C "$TARGET_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH_NAME=$(git -C "$TARGET_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ ! -z "$BRANCH_NAME" ]; then
        echo "Note: Branch analysis (sonar.branch.name) is only available in SonarQube Developer Edition or higher."
        echo "      The analysis will proceed without branch information in Community Edition."
        echo "      Current branch: $BRANCH_NAME"
        # Only add branch parameter if explicitly requested
        if [ "$SONAR_BRANCH_ANALYSIS" = "true" ]; then
            ADDITIONAL_ARGS="$ADDITIONAL_ARGS -Dsonar.branch.name=$BRANCH_NAME"
        fi
    fi
fi

# Run analysis
echo "Running analysis on $TARGET_DIR..."
docker run --rm \
    --network="host" \
    -v "${TARGET_DIR}:/usr/src" \
    sonarsource/sonar-scanner-cli \
    -Dsonar.projectKey=$PROJECT_NAME \
    -Dsonar.sources=/usr/src \
    -Dsonar.host.url=$SONAR_HOST \
    -Dsonar.token=$SONAR_TOKEN \
    $ADDITIONAL_ARGS

echo "Analysis complete. Visit $SONAR_HOST to view results."
