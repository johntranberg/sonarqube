# SonarQube Code Analysis Tool

This tool provides an easy way to run SonarQube analysis on any codebase. It uses Docker containers to ensure consistent analysis across different environments.

## Prerequisites

- Docker ([Install Docker](https://docs.docker.com/get-docker/))
- Docker Compose ([Install Docker Compose](https://docs.docker.com/compose/install/))
- ~2GB of free disk space for Docker images and volumes
- Python 3.8+ (for AI analysis)
- Anthropic API key (for AI analysis)

## Quick Start

1. Clone this repository:
```bash
git clone <repository-url>
cd sonarqube
```

2. Run the setup script:
```bash
./setup.sh
```

3. Run the analysis on your target directory:
```bash
./run-analysis.sh /path/to/your/code
```

4. (Optional) Run AI analysis on the results:
```bash
# First, add your Anthropic API key to .env
echo "ANTHROPIC_API_KEY=your_api_key_here" > .env

# Install Python dependencies
pip install -r requirements.txt

# Run AI analysis
./analyze_with_ai.py
```

## First-Time Setup

When you run the analysis for the first time:

1. Wait for SonarQube to initialize (this may take a few minutes)
2. Visit http://localhost:9000 in your browser
3. Login with default credentials:
   - Username: `admin`
   - Password: `admin`
4. You'll be prompted to change the password
5. After changing the password, your analysis will be available under the "code-analyzer" project

## Analysis Results

After running the analysis, you can find:

1. Web Interface (http://localhost:9000):
   - Code quality metrics
   - Code smells
   - Bugs and vulnerabilities
   - Complexity metrics
   - Code duplications

2. Local Results:
   - Raw analysis data is stored in the `.scannerwork` directory
   - This data can be used for further processing or integration with other tools

## AI-Powered Analysis

The tool includes AI-powered analysis using Anthropic's Claude model. After running the SonarQube analysis, you can generate an AI report that includes:

1. Pattern Analysis:
   - Common code issues
   - Issue distribution by severity and type
   - File-specific problems

2. Refactoring Strategies:
   - Specific recommendations for each issue type
   - Prioritized improvement suggestions
   - Best practices to follow

3. Generated Solutions:
   - Code examples for fixing common issues
   - Templates for implementing improvements
   - Step-by-step refactoring guides

The AI reports are saved in the `refactoring-reports` directory with timestamps.

## Troubleshooting

1. If SonarQube fails to start:
   ```bash
   # View SonarQube logs
   docker-compose logs sonarqube
   ```

2. If analysis fails:
   - Ensure SonarQube is fully initialized (check http://localhost:9000)
   - Verify the target directory path is correct
   - Check if the target directory is accessible to Docker

3. If AI analysis fails:
   - Check that your Anthropic API key is correctly set in `.env`
   - Ensure Python dependencies are installed
   - Verify that the SonarQube analysis data exists

## Cleanup

To stop SonarQube and clean up Docker volumes:
```bash
docker-compose down -v
