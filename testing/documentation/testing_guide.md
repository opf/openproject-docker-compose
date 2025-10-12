# Testing Guide

This guide covers how to effectively use the OpenProject Configuration Manager testing framework.

## Getting Started

### Prerequisites
- Python 3.8+
- Virtual environment activated
- Dependencies installed: `pip install -e ".[dev]"`

### First Time Setup
```bash
# Create and activate virtual environment
python -m venv testing/env
source testing/env/bin/activate  # Linux/Mac
# or testing\env\Scripts\activate  # Windows

# Install dependencies
pip install -e ".[dev]"
```

## Running Tests

### Quick Commands
```bash
# All tests
pytest

# Fast unit tests only
python testing/scripts/run_unit_tests.py

# Everything with coverage
pytest --cov=openproject_config_manager --cov-report=html
```

### Test Selection
```bash
# By directory
pytest testing/unit/
pytest testing/integration/  
pytest testing/e2e/

# By marker
pytest -m "ui"           # UI tests only
pytest -m "not slow"     # Skip slow tests
pytest -m "unit or integration"  # Multiple markers

# By name pattern
pytest -k "test_config"  # Tests with "config" in name
pytest -k "not test_slow"  # Exclude tests with "slow" in name
```

### Debugging
```bash
# Verbose output
pytest -v -s

# Stop on first failure
pytest -x

# Enter debugger on failure
pytest --pdb

# Run specific test with debugging
pytest testing/unit/test_core_config.py::TestConfiguration::test_basic_config -v -s
```

## Writing Tests

### Test Structure
```python
def test_component_behavior():
    # Arrange - Set up test data
    config = Configuration(...)
    
    # Act - Execute the functionality
    result = config.validate()
    
    # Assert - Verify the results
    assert result is True
    assert config.errors == []
```

### Using Fixtures
```python
def test_with_fixture(sample_config):
    # Use fixtures from conftest.py
    assert sample_config.rails_env == "production"
```

### Mocking External Dependencies
```python
@patch('openproject_config_manager.some_module.external_call')
def test_with_mock(mock_external):
    mock_external.return_value = "expected_result"
    # Your test here
```

## Test Categories

### Unit Tests
- **Focus**: Single components
- **Speed**: < 1 second
- **Mocking**: Heavy use of mocks
- **Example**: Testing configuration validation logic

### Integration Tests  
- **Focus**: Component interaction
- **Speed**: 1-10 seconds
- **Mocking**: Minimal, real components
- **Example**: Testing CLI → Collector → Exporter flow

### E2E Tests
- **Focus**: Complete workflows
- **Speed**: 10+ seconds
- **Mocking**: None, real system
- **Example**: Full configuration collection workflow

## Coverage Analysis

### Generate Coverage Report
```bash
pytest --cov=openproject_config_manager --cov-report=html --cov-report=term
```

### View Coverage
```bash
# Terminal output shows summary
# HTML report: open htmlcov/index.html
```

### Coverage Goals
- **Unit tests**: 90%+ coverage
- **Integration tests**: Cover critical paths
- **E2E tests**: Cover main user workflows

## Performance Testing

### Timing Tests
```bash
# Time individual tests
pytest --durations=10

# Profile slow tests
pytest -m slow --profile
```

### Memory Usage
```bash
# Check for memory leaks in long tests
pytest --memray
```

## Continuous Integration

### Local CI Simulation
```bash
# Run the same checks as CI
python testing/scripts/run_all_tests.py
flake8 src testing
black --check src testing
```

### CI Configuration
See `.github/workflows/ci.yml` for the complete CI pipeline configuration.

## Best Practices

### Test Naming
- Use descriptive names: `test_config_validation_fails_with_invalid_port`
- Group related tests in classes: `class TestConfigurationValidation:`

### Test Independence
- Each test should be independent
- Use fixtures for common setup
- Clean up after tests (use teardown fixtures)

### Mock Guidelines
- Mock external dependencies (file systems, networks)
- Don't mock the code you're testing
- Use realistic mock data

### Documentation
- Write docstrings for complex test scenarios
- Comment non-obvious test logic
- Keep README files updated

## Troubleshooting

### Common Issues

**ImportError: Module not found**
```bash
# Ensure you're in the right directory and have dependencies
cd /opt/openproject/external/config-manager
pip install -e ".[dev]"
```

**Tests fail with path errors**
```bash
# Check your working directory
pwd
# Should be in project root for pytest
```

**Fixtures not found**
```bash
# Ensure conftest.py is in the right location
# Check fixture names match exactly
```

### Getting Help
- Check test output for specific error messages
- Use `pytest --help` for command options
- Review conftest.py for available fixtures
- Check existing tests for patterns

---

Happy testing! 🧪