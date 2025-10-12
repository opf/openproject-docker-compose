# Testing Framework - OpenProject Docker Compose# Testing Framework Documentation



This directory contains the comprehensive testing framework for the main OpenProject Docker Compose orchestration system.Welcome to the OpenProject Configuration Manager testing framework! This directory contains comprehensive testing infrastructure organized for maintainability and clarity.



## 🎯 **Testing Philosophy**## 📁 Directory Structure



We use a structured approach to testing with clear separation of concerns:```

- **Unit Tests**: Test individual components in isolationtesting/

- **Integration Tests**: Test component interactions and workflows  ├── unit/                    # Fast unit tests for individual components

- **End-to-End Tests**: Test complete user workflows and system behavior├── integration/             # Integration tests for multiple components

├── e2e/                     # End-to-end workflow tests  

## 📁 **Directory Structure**├── scripts/                 # Test runner utilities

├── config/                  # Test configuration files

```├── results/                 # Test output and reports (gitignored)

testing/├── documentation/           # Testing guides and documentation

├── unit/                    # Unit tests (fast, isolated)└── env/                     # Virtual environment (gitignored)

│   ├── test_config.py      # Configuration management tests```

│   ├── conftest.py         # Unit test fixtures

│   └── __init__.py## 🚀 Quick Start

├── integration/            # Integration tests (components working together)

│   ├── conftest.py         # Integration test fixtures  ### Run All Tests

│   └── __init__.py```bash

├── e2e/                    # End-to-end tests (full workflows)cd /opt/openproject/external/config-manager

│   ├── conftest.py         # E2E test fixturespython testing/scripts/run_all_tests.py

│   └── __init__.py```

├── scripts/                # Test execution scripts

│   ├── run_unit_tests.py   # Run only unit tests### Run Specific Test Types

│   ├── run_integration_tests.py  # Run only integration tests  ```bash

│   ├── run_e2e_tests.py    # Run only e2e tests# Unit tests only (fast)

│   └── run_all_tests.py    # Run complete test suitepython testing/scripts/run_unit_tests.py

├── config/                 # Test configuration

│   └── pytest.ini         # Pytest configuration# Integration tests only

├── results/                # Test results and reportspython testing/scripts/run_integration_tests.py  

├── documentation/          # Testing guides and documentation

│   ├── testing_guide.md    # Comprehensive testing guide# End-to-end tests only

│   └── framework_overview.md  # Testing framework overviewpython testing/scripts/run_e2e_tests.py

└── README.md              # This file```

```

### Run Tests with Pytest Directly

## 🚀 **Quick Start**```bash

# All tests

### Run All Testspytest testing/

```bash

cd testing# Specific test type  

python scripts/run_all_tests.pypytest testing/unit/

```pytest testing/integration/

pytest testing/e2e/

### Run Specific Test Types

```bash# With coverage

# Unit tests only (fast)pytest testing/ --cov=openproject_config_manager --cov-report=html

python scripts/run_unit_tests.py```



# Integration tests only## 📋 Test Categories

python scripts/run_integration_tests.py

### Unit Tests (`testing/unit/`)

# End-to-end tests only- **Purpose**: Test individual components in isolation

python scripts/run_e2e_tests.py- **Speed**: Fast (< 1 second per test)

```- **Dependencies**: Minimal, heavily mocked

- **Files**:

### Run Tests with Pytest Directly  - `test_core_config.py` - Configuration model tests

```bash  - `test_ui_console.py` - UI component tests

# From project root  - `test_discovery_environment.py` - Environment discovery tests

pytest testing/unit/ -v                    # Unit tests  - `test_export_cfg_writer.py` - Configuration export tests

pytest testing/integration/ -v             # Integration tests    - `test_validation_validator.py` - Validation logic tests

pytest testing/e2e/ -v                     # E2E tests

pytest testing/ -v                         # All tests### Integration Tests (`testing/integration/`)

```- **Purpose**: Test multiple components working together

- **Speed**: Medium (1-10 seconds per test)

## 📊 **Current Test Coverage**- **Dependencies**: Real components, some external dependencies

- **Files**:

- **Unit Tests**: Configuration management, deployment orchestration  - `test_integration.py` - Cross-component integration

- **Integration Tests**: TBD - Docker Compose workflows, container interactions  - `test_collector_interactive.py` - Interactive collection flows

- **E2E Tests**: TBD - Complete deployment scenarios  - `test_main_cli.py` - CLI interface integration



## 🔧 **Adding New Tests**### End-to-End Tests (`testing/e2e/`)

- **Purpose**: Test complete user workflows

### Unit Tests- **Speed**: Slow (10+ seconds per test)

- Add to `testing/unit/`- **Dependencies**: Full system, real file I/O

- Focus on testing individual functions/classes- **Files**:

- Use mocks for external dependencies  - `test_e2e_ui_workflows.py` - Complete configuration workflows

- Should run in <1 second each

## 🔧 Configuration

### Integration Tests  

- Add to `testing/integration/`- **pytest.ini**: Located in `testing/config/pytest.ini`

- Test component interactions- **pyproject.toml**: Main project config also contains pytest settings

- May use Docker containers or external services- **conftest.py**: Shared fixtures in each test directory

- Acceptable to run in <30 seconds each

## 📊 Coverage and Reporting

### End-to-End Tests

- Add to `testing/e2e/`Test results and coverage reports are stored in `testing/results/` and are automatically ignored by git.

- Test complete user workflows

- May take several minutes to run## 🏃‍♂️ CI/CD Integration

- Test real deployment scenarios

The GitHub Actions workflow automatically runs all test types in the correct sequence:

## 📋 **Test Standards**1. Unit tests (fast feedback)

2. Integration tests (component interaction)  

1. **Naming**: Test files must start with `test_`3. E2E tests (full workflows)

2. **Documentation**: Each test should have a clear docstring

3. **Isolation**: Tests should not depend on each other## 📚 Best Practices

4. **Cleanup**: Tests should clean up any resources they create

5. **Assertions**: Use descriptive assertion messages1. **Write unit tests first** - Fast feedback loop

2. **Mock external dependencies** in unit tests

## 🔗 **Related Documentation**3. **Use real components** in integration tests

4. **Test real user scenarios** in E2E tests

- [`documentation/testing_guide.md`](documentation/testing_guide.md) - Comprehensive testing guide5. **Keep tests independent** - No test dependencies

- [`documentation/framework_overview.md`](documentation/framework_overview.md) - Framework architecture6. **Use descriptive test names** - Clear intent

- [`config/pytest.ini`](config/pytest.ini) - Pytest configuration details7. **Maintain test fixtures** in conftest.py files



This testing framework ensures reliability and maintainability of the OpenProject Docker Compose system.## 🐛 Debugging Tests

```bash
# Run with verbose output
pytest testing/ -v -s

# Run specific test
pytest testing/unit/test_core_config.py::TestConfiguration::test_basic_config

# Debug with pdb
pytest testing/ --pdb

# See coverage gaps
pytest testing/ --cov=openproject_config_manager --cov-report=html
open htmlcov/index.html
```

---

For more detailed information, see the individual documentation files in this directory.