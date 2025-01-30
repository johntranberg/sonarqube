#!/usr/bin/env python3
import json
import os
from datetime import datetime
from dotenv import load_dotenv
import anthropic
from pathlib import Path

def load_sonar_data(analysis_dir):
    """Load SonarQube analysis data from files"""
    data = {}
    for file_name in ['issues.json', 'metrics.json', 'hotspots.json']:
        file_path = os.path.join(analysis_dir, file_name)
        if os.path.exists(file_path):
            with open(file_path, 'r') as f:
                data[file_name.replace('.json', '')] = json.load(f)
    return data

def analyze_patterns(data):
    """Analyze patterns in code issues"""
    issues = data.get('issues', {}).get('issues', [])
    
    # Group issues by type and severity
    patterns = {
        'by_type': {},
        'by_severity': {},
        'by_file': {},
    }
    
    for issue in issues:
        issue_type = issue.get('type', 'unknown')
        severity = issue.get('severity', 'unknown')
        component = issue.get('component', 'unknown')
        
        patterns['by_type'][issue_type] = patterns['by_type'].get(issue_type, 0) + 1
        patterns['by_severity'][severity] = patterns['by_severity'].get(severity, 0) + 1
        
        if component not in patterns['by_file']:
            patterns['by_file'][component] = []
        patterns['by_file'][component].append({
            'type': issue_type,
            'severity': severity,
            'message': issue.get('message', '')
        })
    
    return patterns

def get_ai_analysis(client, patterns, data):
    """Get AI analysis of the patterns"""
    
    # Prepare the prompt
    prompt = f"""Analyze this SonarQube code analysis data and create a detailed report. Include:

1. Pattern Analysis:
{json.dumps(patterns, indent=2)}

2. Metrics:
{json.dumps(data.get('metrics', {}), indent=2)}

3. Security Hotspots:
{json.dumps(data.get('hotspots', {}), indent=2)}

Create a markdown report that includes:
1. An executive summary of the code quality
2. Detailed analysis of patterns found in the code
3. Specific refactoring recommendations for each major issue type
4. Prioritized list of improvements
5. Code examples or templates for fixing common issues found

Format the response in clean markdown with proper sections, code blocks, and bullet points."""

    # Get AI response
    message = client.messages.create(
        model="claude-3-opus-20240229",
        max_tokens=4000,
        messages=[{
            "role": "user",
            "content": prompt
        }]
    )
    
    # Extract just the text content from the response
    content = message.content[0].text if isinstance(message.content, list) else message.content
    return content

def main():
    # Load environment variables
    load_dotenv()
    api_key = os.getenv('ANTHROPIC_API_KEY')
    if not api_key:
        print("Error: ANTHROPIC_API_KEY not found in .env file")
        return

    # Initialize Anthropic client
    client = anthropic.Anthropic(api_key=api_key)

    # Load SonarQube data
    analysis_dir = '../TestCaseCreation/.sonar-analysis'
    data = load_sonar_data(analysis_dir)
    if not data:
        print("Error: No analysis data found")
        return

    # Analyze patterns
    patterns = analyze_patterns(data)

    try:
        # Get AI analysis
        ai_report = get_ai_analysis(client, patterns, data)

        # Create output directory if it doesn't exist
        output_dir = '../TestCaseCreation/refactoring-reports'
        os.makedirs(output_dir, exist_ok=True)

        # Save the report
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        report_path = os.path.join(output_dir, f'refactoring_report_{timestamp}.md')
        
        with open(report_path, 'w') as f:
            f.write(ai_report)

        print(f"\nAnalysis complete! Report saved to: {report_path}")
        print("The report includes:")
        print("1. Pattern analysis of code issues")
        print("2. Specific refactoring strategies")
        print("3. Generated improvement suggestions")
    except Exception as e:
        print(f"Error generating report: {str(e)}")
        if hasattr(e, 'response'):
            print(f"API Response: {e.response}")

if __name__ == "__main__":
    main()
