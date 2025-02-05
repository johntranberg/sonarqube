# SonarQube Code Analysis Tool

This tool provides an easy way to run SonarQube analysis on any codebase and extract insights using AI. It uses Docker containers to ensure consistent analysis across different environments.

## Prerequisites

- Docker ([Install Docker](https://docs.docker.com/get-docker/))
- Docker Compose ([Install Docker Compose](https://docs.docker.com/compose/install/))
- ~2GB of free disk space for Docker images and volumes
- Python 3.8+ (for AI analysis)
- Anthropic API key (for AI analysis)

## Project Structure

```
sonarqube/
├── bin/               # Scripts directory
│   ├── run-analysis.sh
│   └── extract-analysis.sh
├── config/            # Configuration files
│   ├── sonar-config.example.json
│   └── .env.example
├── src/              # Source code
│   └── analyze_with_ai.py
├── setup.sh          # Initial setup script
├── docker-compose.yml
├── requirements.txt
└── README.md
```

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

3. Configure your settings:
```bash
# Set up SonarQube token
cp config/sonar-config.example.json config/sonar-config.json
# Edit config/sonar-config.json with your token after generating it in SonarQube

# Set up Anthropic API key (for AI analysis)
cp config/.env.example config/.env
# Edit config/.env with your Anthropic API key
```

4. Run the analysis on your target directory:
```bash
./bin/run-analysis.sh /path/to/your/code
```

5. Extract detailed analysis results (optional):
```bash
./bin/extract-analysis.sh /path/to/your/code
```

6. Run AI analysis on the results (optional):
```bash
# Install Python dependencies
pip3 install -r requirements.txt

# Run AI analysis
python3 src/analyze_with_ai.py
```

## First-Time Setup

When you run the analysis for the first time:

1. Wait for SonarQube to initialize (this may take a few minutes)
2. Visit http://localhost:9000 in your browser
3. Login with default credentials:
   - Username: `admin`
   - Password: `admin`
4. You'll be prompted to change the password
5. Generate a token in SonarQube:
   - Go to User > My Account > Security
   - Generate a new token
   - Copy the token to `config/sonar-config.json`

## Analysis Results

After running the analysis, you can find:

1. Web Interface (http://localhost:9000):
   - Code quality metrics
   - Code smells
   - Bugs and vulnerabilities
   - Complexity metrics
   - Code duplications

2. Local Results (when using extract-analysis.sh):
   - Results are stored in `.sonar-analysis` directory within your target directory
   - Contains raw data that can be used for further processing or integration

## Important Notes

### Branch Analysis
Branch analysis is only available in SonarQube Developer Edition or higher. When using Community Edition:
- The analysis will run on the default branch view
- Branch information will not be tracked separately
- If you have Developer Edition or higher, you can enable branch analysis:
  ```bash
  SONAR_BRANCH_ANALYSIS=true ./bin/run-analysis.sh /path/to/your/code
  ```

### Java Projects

When analyzing Java projects, SonarQube requires access to the compiled classes to perform a proper analysis. The script will automatically:

1. Detect Java files in your project
2. Look for compiled classes in common build directories:
   - `target/classes` (Maven)
   - `build/classes` (Gradle)
   - `out/production` (IntelliJ IDEA)
   - `bin` (Eclipse)

If no compiled classes are found, you'll need to compile your project first:
```bash
# For Maven projects
mvn compile

# For Gradle projects
./gradlew classes
```

Without compiled classes, you'll either need to:
- Compile the project first (recommended)
- Specify the location of compiled classes manually with `-Dsonar.java.binaries`
- Exclude Java files from analysis with `-Dsonar.exclusions`

## AI-Powered Analysis

The tool includes AI-powered analysis using Anthropic's Claude model. After running the SonarQube analysis and extraction, you can generate an AI report that includes:

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

## Troubleshooting

1. If SonarQube fails to start:
   ```bash
   # View SonarQube logs
   docker compose logs sonarqube
   ```

2. If analysis fails:
   - Ensure SonarQube is fully initialized (check http://localhost:9000)
   - Verify the target directory path is correct
   - Check if your SonarQube token is correctly set in `config/sonar-config.json`

3. If jq is not installed:
   - Run `./setup.sh` again to install it
   - Or install manually: [jq installation guide](https://stedolan.github.io/jq/download/)

## Contributing

Feel free to open issues or submit pull requests for improvements. Some areas that could use enhancement:

1. Additional analysis metrics
2. More AI-powered insights
3. Integration with other code quality tools
4. Support for different languages and frameworks

## License

This project is licensed under the MIT License - see the LICENSE file for details.
