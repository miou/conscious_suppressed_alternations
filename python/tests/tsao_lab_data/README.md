# Unit Tests for tsao_lab_data

This directory contains comprehensive unit tests for the `tsao_lab_data` package, specifically focusing on the `Session` and `Paradigm` classes that handle neuroscience data loading and processing.

## Test Organization

### Test Files

- **`conftest.py`**: Pytest configuration and shared fixtures
  - Contains reusable test data factories
  - Provides fixtures for creating Session and Paradigm instances
  - Manages temporary directories for file I/O tests

- **`test_session.py`**: Comprehensive tests for the Session class (78 tests)
  - Session initialization and validation
  - HDF5 data loading (`from_h5`)
  - HDF5 data saving (`to_h5`)
  - Unit selection and filtering
  - Probe selection
  - Edge cases and error handling

- **`test_paradigm.py`**: Comprehensive tests for Paradigm classes (57 tests)
  - Base Paradigm validation
  - All 13 paradigm subclasses (FOB, PSS, BRS, PSN, BRN, TSS, PSST, BRST, PSNT, BRNT, FAS, FSMS, FSO)
  - HDF5 loading and saving
  - Trial selection and filtering
  - Unit selection
  - Properties and utilities
  - Edge cases

## Running Tests

### Run all tests
```bash
pytest tests/
```

### Run with verbose output
```bash
pytest tests/ -v
```

### Run specific test file
```bash
pytest tests/test_session.py
pytest tests/test_paradigm.py
```

### Run specific test class
```bash
pytest tests/test_session.py::TestSessionDataLoading
pytest tests/test_paradigm.py::TestFOBParadigm
```

### Run specific test
```bash
pytest tests/test_session.py::TestSessionDataLoading::test_session_from_h5_loads_basic_attributes
```

### Run with coverage report
```bash
pytest tests/ --cov=src/tsao_lab_data --cov-report=term-missing
```

## Test Coverage

Current test coverage statistics:
- **Session class**: 100% coverage - All code paths tested
- **Paradigm classes**: 79% coverage - Core functionality fully tested
- **Dataset class**: 0% coverage (intentionally excluded - backwards compatibility only)

### What is Tested

#### Session Class (100% coverage)
1. **Initialization & Validation**
   - Valid data creation
   - Automatic validation on init
   - Region/probe consistency checks
   - Layer direction validation
   - Unit array validation (shape, dtype, non-negative)
   - Waveform shape consistency
   - Paradigm compatibility validation

2. **Data Loading (from_h5)**
   - Loading all session attributes
   - Loading unit-level data
   - Loading waveform data
   - Loading paradigms from HDF5 groups
   - Extracting animal name from session name
   - Extracting timestamp from session name
   - Error handling for missing files
   - Error handling for unsupported paradigms

3. **Data Saving (to_h5)**
   - Creating HDF5 files
   - Saving all attributes and datasets
   - Roundtrip preservation (save → load → verify)
   - Proper HDF5 structure organization

4. **Unit Selection**
   - Filtering unit arrays
   - Updating waveform arrays
   - Propagating to paradigms
   - Maintaining validation after selection
   - Edge cases (empty, single unit)

5. **Probe Selection**
   - Filtering by probe
   - Updating metadata (regions, layer_direction)
   - Propagating to paradigms
   - Error handling for invalid probes

6. **Edge Cases**
   - Single unit/probe sessions
   - Large numbers of units (scalability)
   - Empty paradigm dictionaries
   - Contiguous vs non-contiguous selections

#### Paradigm Classes (79% coverage)
1. **Base Validation**
   - Stimulus file/index consistency
   - Array shape validation
   - Non-negative integer enforcement
   - Time bounds checking
   - Trial duration consistency

2. **HDF5 I/O**
   - Loading common fields
   - Saving paradigm data
   - Roundtrip testing
   - Paradigm name validation

3. **Unit Selection**
   - Filtering timecourse data
   - Optimized contiguous selection
   - Preserving time dimension
   - Subclass-specific fields (e.g., responses_priming)

4. **Trial Selection**
   - Range validation
   - Time coordinate adjustment
   - Filtering all trial-level arrays
   - Subclass-specific fields

5. **Properties**
   - trial_bounds computation
   - spike_trials extraction
   - eye tracking per trial

6. **All Paradigm Subclasses**
   - FOBParadigm (base functionality)
   - FSMSParadigm (flash suppression many stimuli)
   - FSOParadigm (flash suppression optimized)

### Bugs Found During Testing

The test suite discovered an edge case bug:
- **Empty unit selection**: Calling `select_units()` with an empty array raises `ValueError` due to `np.min()` on empty array in `Paradigm.select_units()`. This is documented in the test with a clear note that the functionality may need implementation if required in the future.

## Test Design Principles

1. **Comprehensive Coverage**: Tests cover normal operation, edge cases, and error conditions
2. **Clear Test Names**: Follow pattern `test_<method>_<scenario>_<expected_outcome>`
3. **Isolated Tests**: Each test is independent and can run in any order
4. **Fixture Reuse**: Common test data is created once via fixtures
5. **Mocking Strategy**: File I/O uses temporary directories to avoid filesystem dependencies
6. **Meaningful Assertions**: Tests verify actual functionality, not just "doesn't crash"
7. **Documentation**: Complex scenarios include docstrings explaining the test's purpose

## Types of Tests

### Unit Tests
- Test individual methods in isolation
- Verify correct handling of valid inputs
- Verify rejection of invalid inputs

### Integration Tests
- Test interaction between Session and Paradigm
- Verify data propagation through method calls
- Test HDF5 roundtrip (write → read → verify)

### Edge Case Tests
- Boundary values (0, 1, very large)
- Empty collections
- Single-item collections
- Invalid inputs (negative numbers, wrong types)

### Regression Tests
- Document known bugs/limitations
- Prevent reintroduction of fixed bugs

## Test Data Strategy

### Fixtures provide:
1. **Minimal valid data**: Just enough to create valid objects
2. **Realistic shapes**: Arrays sized appropriately for neuroscience data
3. **Random content**: Where specific values don't matter
4. **Deterministic seeds**: For reproducible test runs
5. **Temporary files**: Automatic cleanup via context managers

### What the tests catch:
- Data corruption during loading
- Incorrect data transformations
- File format parsing errors
- Inconsistent state after operations
- Memory/resource leaks
- Boundary value errors
- Type conversion issues
- Missing validation checks

## Future Test Enhancements

Potential areas for additional testing:
1. Performance/scalability tests with very large datasets
2. Concurrent access to Session/Paradigm objects
3. Stress testing with corrupted HDF5 files
4. Memory profiling for large data operations
5. Integration tests with actual data files from experiments
6. Property-based testing with hypothesis library

## Contributing

When adding new features to Session or Paradigm classes:
1. Add corresponding tests to `test_session.py` or `test_paradigm.py`
2. Follow existing test naming conventions
3. Include tests for normal operation, edge cases, and error conditions
4. Update this README if adding new test categories
5. Ensure all tests pass: `pytest tests/`
6. Check coverage: `pytest tests/ --cov=src/tsao_lab_data`

## Dependencies

- pytest >= 8.3.4
- numpy >= 2.4.1
- h5py >= 3.15.1
- pytest-cov (optional, for coverage reports)
