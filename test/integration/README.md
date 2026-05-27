# AI Visual Assistant Integration Tests

## Quick Start

### Run All Integration Tests
```bash
flutter test test/integration/ai_consultation_integration_test.dart
```

### Run with Verbose Output
```bash
flutter test test/integration/ai_consultation_integration_test.dart --reporter expanded
```

### Run Specific Test
```bash
flutter test test/integration/ai_consultation_integration_test.dart --name "DefectMarker model validation"
```

## Test Structure

### Test Groups

1. **AI Visual Assistant Integration Tests**
   - Screen rendering tests
   - Error handling tests
   - Model validation tests
   - Workflow tests

2. **API Service Mock Tests**
   - API call simulations
   - Error handling
   - Response validation

## Test Files

- `ai_consultation_integration_test.dart` - Main integration test suite (runs without device)
- `../integration_test/ai_consultation_flow_test.dart` - Device-based integration tests

## Mock Data

All tests use mock data created by helper functions:
- `createTestImageFile()` - Creates a minimal JPEG for testing
- `createMockConsultation()` - Creates a complete consultation object
- `createMockHistory()` - Creates paginated history response

## Coverage

Run tests with coverage:
```bash
flutter test --coverage test/integration/ai_consultation_integration_test.dart
```

View coverage report:
```bash
genhtml coverage/lcov.info -o coverage/html
```

## Troubleshooting

### Tests Timeout
Some tests may timeout if screens have async operations. Increase timeout:
```dart
testWidgets('Test name', (tester) async {
  // ...
}, timeout: const Timeout(Duration(seconds: 30)));
```

### Widget Not Found
If a widget is not found, ensure:
1. The screen is properly initialized
2. Required providers are overridden
3. State is set up correctly

### Mock Not Working
If mocks aren't working:
1. Check `setUp()` initializes the mock
2. Verify `setMock*()` methods are called before test
3. Ensure provider override is applied

## Best Practices

1. **Always use setUp() and tearDown()**
   ```dart
   setUp(() {
     mockApiService = MockAIConsultationApiService();
   });
   
   tearDown(() {
     mockApiService.reset();
   });
   ```

2. **Use const constructors where possible**
   ```dart
   const DefectMarkerModel(id: 'test', x: 0.5, y: 0.5, description: 'Test')
   ```

3. **Mock API responses before tests**
   ```dart
   mockApiService.setMockConsultation(createMockConsultation());
   ```

4. **Use descriptive test names**
   ```dart
   test('DefectMarker validates coordinates are between 0 and 1', () { ... });
   ```

## Adding New Tests

1. Add test to appropriate group
2. Use existing helper functions
3. Mock dependencies
4. Add assertions
5. Update documentation

Example:
```dart
testWidgets('New feature test', (WidgetTester tester) async {
  // Setup
  final mockData = createMockConsultation();
  mockApiService.setMockConsultation(mockData);
  
  // Build widget
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        aiConsultationApiServiceProvider.overrideWithValue(mockApiService),
      ],
      child: const MaterialApp(home: YourScreen()),
    ),
  );
  
  await tester.pumpAndSettle();
  
  // Assertions
  expect(find.text('Expected Text'), findsOneWidget);
});
```

## CI/CD Integration

Add to your CI pipeline:
```yaml
- name: Run Integration Tests
  run: flutter test test/integration/ai_consultation_integration_test.dart --reporter json > test-results.json
```

## Related Documentation

- [Integration Tests Summary](INTEGRATION_TESTS_SUMMARY.md) - Detailed test coverage report
- [Widget Tests](../widget/WIDGET_TESTS_SUMMARY.md) - Widget-level tests
- [Design Document](../../.kiro/specs/ai-visual-assistant/design.md) - Feature design
- [Requirements](../../.kiro/specs/ai-visual-assistant/requirements.md) - Feature requirements
