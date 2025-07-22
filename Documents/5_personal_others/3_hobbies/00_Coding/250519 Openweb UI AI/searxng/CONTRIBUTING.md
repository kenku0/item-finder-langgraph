# Contributing to SearXNG for OpenWebUI

Thank you for your interest in contributing to SearXNG for OpenWebUI! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct:

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive criticism
- Respect differing viewpoints and experiences

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

When creating a bug report, include:

1. **Clear Title**: Summarize the issue
2. **Description**: Detailed description of the bug
3. **Steps to Reproduce**: List the exact steps
4. **Expected Behavior**: What should happen
5. **Actual Behavior**: What actually happens
6. **Environment**:
   - OS and version
   - Docker version (if applicable)
   - Browser and version
   - SearXNG version
7. **Logs**: Include relevant log outputs
8. **Screenshots**: If applicable

### Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:

1. **Use Case**: Explain why this enhancement would be useful
2. **Proposed Solution**: Describe your preferred solution
3. **Alternatives**: List any alternative solutions you've considered
4. **Additional Context**: Add any other relevant information

### Pull Requests

1. **Fork the Repository**
   ```bash
   git clone https://github.com/kenku0/searxng-openwebui.git
   cd searxng-openwebui
   git remote add upstream https://github.com/kenku0/searxng-openwebui.git
   ```

2. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

3. **Make Your Changes**
   - Follow the coding standards
   - Add tests if applicable
   - Update documentation
   - Keep commits atomic and well-described

4. **Test Your Changes**
   ```bash
   # Run the application
   docker-compose up --build
   
   # Test functionality
   curl http://localhost:8080/search?q=test
   ```

5. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "feat: add amazing new feature"
   ```

   Follow conventional commits:
   - `feat:` New feature
   - `fix:` Bug fix
   - `docs:` Documentation changes
   - `style:` Code style changes
   - `refactor:` Code refactoring
   - `test:` Test additions/changes
   - `chore:` Maintenance tasks

6. **Push to Your Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**
   - Go to the original repository
   - Click "New Pull Request"
   - Select your fork and branch
   - Fill in the PR template
   - Submit for review

## Development Setup

### Prerequisites

- Python 3.8+
- Docker and Docker Compose
- Git

### Local Development

1. **Setup Development Environment**
   ```bash
   # Clone the repo
   git clone https://github.com/kenku0/searxng-openwebui.git
   cd searxng-openwebui
   
   # Create virtual environment
   python -m venv venv
   source venv/bin/activate  # Windows: venv\Scripts\activate
   
   # Install development dependencies
   pip install -r requirements-dev.txt
   ```

2. **Run Tests**
   ```bash
   # Unit tests
   pytest tests/
   
   # Integration tests
   pytest tests/integration/
   
   # Linting
   flake8 .
   black --check .
   ```

3. **Code Formatting**
   ```bash
   # Format Python code
   black .
   
   # Sort imports
   isort .
   ```

## Coding Standards

### Python

- Follow PEP 8
- Use type hints where appropriate
- Maximum line length: 88 characters (Black default)
- Use descriptive variable names

### YAML/Configuration

- Use 2 spaces for indentation
- Quote strings when necessary
- Add comments for complex configurations

### Documentation

- Use clear, concise language
- Include code examples
- Update README.md for user-facing changes
- Add docstrings to functions

## Testing

### Writing Tests

- Place tests in the `tests/` directory
- Name test files with `test_` prefix
- Use descriptive test names
- Include both positive and negative test cases

Example:
```python
def test_search_returns_results():
    """Test that search endpoint returns valid results."""
    response = client.get("/search?q=test")
    assert response.status_code == 200
    assert "results" in response.json()
```

### Running Tests

```bash
# All tests
pytest

# Specific test file
pytest tests/test_search.py

# With coverage
pytest --cov=app tests/
```

## Documentation

- Update README.md for new features
- Add inline comments for complex logic
- Document API changes
- Include examples for new configurations

## Release Process

1. Update version numbers
2. Update CHANGELOG.md
3. Create a release branch
4. Submit PR for review
5. After merge, create GitHub release
6. Update Docker images

## Getting Help

- **Discord**: [Join our server](https://discord.gg/example)
- **Issues**: Use GitHub issues for bugs/features
- **Discussions**: Use GitHub discussions for questions

## Recognition

Contributors will be recognized in:
- README.md contributors section
- GitHub insights
- Release notes

Thank you for contributing to SearXNG for OpenWebUI!