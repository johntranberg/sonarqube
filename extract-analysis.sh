#!/bin/bash

# Read configuration
CONFIG_FILE="$(dirname "$0")/sonar-config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Please run setup.sh first."
    exit 1
fi

# Parse JSON config
SONAR_URL=$(jq -r '.sonar.host' "$CONFIG_FILE")
SONAR_TOKEN=$(jq -r '.sonar.token' "$CONFIG_FILE")

if [ "$SONAR_TOKEN" = "YOUR_SONAR_TOKEN" ]; then
    echo "Error: Please update the token in sonar-config.json"
    echo "You can generate a token in SonarQube: $SONAR_URL/account/security/"
    exit 1
fi

# Get project key from command line argument or use directory name
if [ -z "$1" ]; then
    echo "Usage: ./extract-analysis.sh <target_directory>"
    exit 1
fi

TARGET_DIR=$(realpath "$1")
PROJECT_KEY=$(basename "$TARGET_DIR")
OUTPUT_DIR="$TARGET_DIR/.sonar-analysis"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to make authenticated API calls using token
call_api() {
    local endpoint=$1
    curl -s -H "Authorization: Bearer $SONAR_TOKEN" "${SONAR_URL}/api/${endpoint}"
}

echo "Extracting SonarQube analysis results..."

# Get issues (code smells, bugs, vulnerabilities)
echo "Fetching issues..."
call_api "issues/search?projectKeys=${PROJECT_KEY}&ps=500" > "$OUTPUT_DIR/issues.json"

# Get code metrics
echo "Fetching metrics..."
call_api "measures/component?component=${PROJECT_KEY}&metricKeys=complexity,cognitive_complexity,duplicated_lines_density,coverage,bugs,vulnerabilities,code_smells,security_hotspots" > "$OUTPUT_DIR/metrics.json"

# Get hotspots (security issues)
echo "Fetching security hotspots..."
call_api "hotspots/search?projectKey=${PROJECT_KEY}" > "$OUTPUT_DIR/hotspots.json"

# Extract local analysis data
echo "Extracting local analysis data..."
cp -r .scannerwork/scanner-report/* "$OUTPUT_DIR/raw-data/"

# Create a summary file
echo "Creating summary..."
cat > "$OUTPUT_DIR/analysis-summary.md" << EOL
# SonarQube Analysis Summary

## Overview
This directory contains the results of the SonarQube analysis for AI-based refactoring.

## Files
- \`issues.json\`: Contains all code issues including code smells, bugs, and vulnerabilities
- \`metrics.json\`: Contains code metrics like complexity, duplication, etc.
- \`hotspots.json\`: Contains security hotspots
- \`raw-data/\`: Contains detailed analysis data

## Using with AI
The data in this directory can be used to:
1. Identify problematic code areas
2. Understand code complexity and technical debt
3. Prioritize refactoring tasks
4. Generate specific refactoring suggestions

Example usage with AI:
\`\`\`python
import json

# Load issues
with open('issues.json') as f:
    issues = json.load(f)

# Load metrics
with open('metrics.json') as f:
    metrics = json.load(f)

# Process and analyze the data
# Pass to your AI refactoring agent
\`\`\`
EOL

echo "Analysis data has been extracted to $OUTPUT_DIR"
echo "You can now use this data with your AI refactoring agent"
