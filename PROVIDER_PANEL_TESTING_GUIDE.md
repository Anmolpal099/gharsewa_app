# Provider Panel Testing Guide

## Quick Start

### 1. Start the Backend
```powershell
cd e:\gharsewa\backend
docker-compose up -d
```

### 2. Start the Flutter App
```powershell
cd e:\gharsewa
flutter run
```

### 3. Get Provider Token

#### Register a Provider Account:
```bash
POST http://localhost:8000/api/v1/auth/jwt/register
Content-Type: application/json

{
  "name": "Test Provider",
  "email": "provider@test.com",
  "password": "Test1234",
  "role": "serviceProvider"
}
```

#### Verify Email (Get OTP from logs):
```bash
# Check backend logs for OTP
docker-compose logs -f app | grep OTP

# Verify with OTP
POST http://localhost:8000/api/v1/auth/otp/verify-email
Content-Type: application/json

{
  "email": "provider@test.com",
  "otp": "123456"
}
```

#### Login:
```bash
POST http://localhost:8000/api/v1/auth/jwt/login
Content-Type: application/json

{
  "email": "provider@test.com",
  "password": "Test1234"
}

# Save the access_token
```

---

## Testing Scenarios

### Scenario 1: Dashboard Testing

**Objective**: Verify dashboard displays correct information

**Steps**:
1. Login as provider
2. Navigate to Dashboard tab
3. Verify welcome card shows user name
4. Verify earnings card shows current month earnings
5. Verify service overview cards show counts
6. Verify booking statistics are displayed
7. Pull down to refresh
8. Tap "View All" on recent bookings

**Expected Results**:
- ✅ Dashboard loads within 2 seconds
- ✅ All cards display correct data
- ✅ Pull-to-refresh works
- ✅ Navigation to bookings works
- ✅ Empty states show when no data

---

### Scenario 2: Service Management

**Objective**: Test full CRUD operations on services

**Steps**:

#### 2.1: Add Service
1. Navigate to Services tab
2. Tap "Add Service" FAB
3. Fill in form:
   - Name: "House Cleaning"
   - Description: "Professional house cleaning service"
   - Category: "Cleaning"
   - Price: "2000"
   - Duration: "120"
4. Tap "Add Service"

**Expected Results**:
- ✅ Form validation works
- ✅ Service is created
- ✅ Success notification appears
- ✅ Service appears in list
- ✅ Summary card updates

#### 2.2: Edit Service
1. Find the service in list
2. Tap "Edit" button
3. Change price to "2500"
4. Tap "Save"

**Expected Results**:
- ✅ Edit dialog opens with pre-filled data
- ✅ Service is updated
- ✅ Success notification appears
- ✅ List refreshes with new data

#### 2.3: Toggle Service Status
1. Find the service
2. Toggle the switch to inactive
3. Verify service moves to "Inactive Services" section
4. Toggle back to active

**Expected Results**:
- ✅ Status updates immediately
- ✅ Service moves between sections
- ✅ Notification appears

#### 2.4: Delete Service
1. Find the service
2. Tap "Delete" button
3. Confirm deletion

**Expected Results**:
- ✅ Confirmation dialog appears
- ✅ Service is deleted
- ✅ Success notification appears
- ✅ Service removed from list
- ✅ Summary card updates

---

### Scenario 3: Booking Management

**Objective**: Test booking request handling

**Prerequisites**: Create test bookings using customer account

**Steps**:

#### 3.1: View Pending Bookings
1. Navigate to Bookings tab
2. Verify "Pending" tab is selected
3. View pending booking requests

**Expected Results**:
- ✅ Pending bookings are displayed
- ✅ Booking details are visible (date, time, amount)
- ✅ Accept/Reject buttons are present

#### 3.2: Accept Booking
1. Find a pending booking
2. Tap "Accept" button
3. Verify booking moves to "Confirmed" tab

**Expected Results**:
- ✅ Booking status updates
- ✅ Success notification appears
- ✅ Booking appears in Confirmed tab
- ✅ Dashboard updates

#### 3.3: Reject Booking
1. Find a pending booking
2. Tap "Reject" button
3. Enter rejection reason: "Not available"
4. Tap "Reject"

**Expected Results**:
- ✅ Rejection dialog appears
- ✅ Reason is required
- ✅ Booking is rejected
- ✅ Notification appears
- ✅ Booking removed from pending

#### 3.4: Complete Booking
1. Switch to "Confirmed" tab
2. Find a confirmed booking
3. Tap "Complete" button
4. Confirm completion

**Expected Results**:
- ✅ Confirmation dialog appears
- ✅ Booking status updates to completed
- ✅ Success notification appears
- ✅ Booking moves to Completed tab
- ✅ Dashboard earnings update

---

### Scenario 4: Analytics Testing

**Objective**: Test analytics and filtering

**Steps**:

#### 4.1: View Default Analytics
1. Navigate to Analytics tab
2. Verify default view (Last 30 days, grouped by day)
3. Check summary cards
4. Check line chart
5. Check breakdown table

**Expected Results**:
- ✅ Analytics load within 2 seconds
- ✅ Summary cards show correct totals
- ✅ Chart displays data points
- ✅ Table shows breakdown by period

#### 4.2: Change Date Range
1. Tap filter icon
2. Change "From" date to 7 days ago
3. Change "To" date to today
4. Tap "Apply"

**Expected Results**:
- ✅ Filter dialog opens
- ✅ Date pickers work
- ✅ Analytics refresh with new data
- ✅ Chart updates
- ✅ Table updates

#### 4.3: Change Grouping
1. Tap filter icon
2. Select "Week" grouping
3. Tap "Apply"

**Expected Results**:
- ✅ Grouping changes
- ✅ Chart updates with weekly data
- ✅ Table shows weekly breakdown

#### 4.4: Use Quick Filters
1. Tap filter icon
2. Tap "Last 7 days" chip
3. Tap "Apply"

**Expected Results**:
- ✅ Date range updates automatically
- ✅ Grouping changes to "day"
- ✅ Analytics refresh

---

## Error Testing

### Test 1: Network Error
1. Disconnect internet
2. Try to load dashboard
3. Verify error message appears
4. Tap "Retry" button
5. Reconnect internet
6. Verify data loads

### Test 2: Invalid Data
1. Try to add service with empty name
2. Verify validation error
3. Try to add service with price < 0
4. Verify validation error
5. Try to add service with duration < 15
6. Verify validation error

### Test 3: Backend Error
1. Stop backend
2. Try to perform any action
3. Verify error notification
4. Start backend
5. Retry action

---

## Performance Testing

### Metrics to Check:
- [ ] Dashboard loads in < 2 seconds
- [ ] Service list loads in < 1 second
- [ ] Bookings list loads in < 1 second
- [ ] Analytics loads in < 2 seconds
- [ ] Navigation between tabs is instant
- [ ] Pull-to-refresh completes in < 1 second
- [ ] Form submissions complete in < 1 second

---

## UI/UX Testing

### Visual Checks:
- [ ] All cards have consistent styling
- [ ] Colors are appropriate for status
- [ ] Icons are meaningful
- [ ] Text is readable
- [ ] Buttons are properly sized
- [ ] Forms are well-organized
- [ ] Empty states are helpful
- [ ] Error states are clear
- [ ] Loading states are visible

### Interaction Checks:
- [ ] All buttons respond to taps
- [ ] Forms validate on submit
- [ ] Dialogs can be dismissed
- [ ] Pull-to-refresh works smoothly
- [ ] Tab switching is smooth
- [ ] Navigation is intuitive
- [ ] Notifications are visible
- [ ] Confirmations prevent accidents

---

## Integration Testing

### End-to-End Workflow:
1. **Provider Onboarding**:
   - Register as provider
   - Verify email
   - Login
   - View empty dashboard

2. **Service Setup**:
   - Add first service
   - Add second service
   - Edit a service
   - Toggle service status

3. **Booking Handling**:
   - Receive booking request (create from customer app)
   - Accept booking
   - Complete booking
   - View earnings update

4. **Analytics Review**:
   - View analytics
   - Change date range
   - Export data (future feature)

---

## Regression Testing

After any code changes, verify:
- [ ] Dashboard still loads correctly
- [ ] Services CRUD still works
- [ ] Bookings management still works
- [ ] Analytics still displays
- [ ] Navigation still works
- [ ] Error handling still works
- [ ] Notifications still appear

---

## Bug Reporting Template

```markdown
**Bug Title**: [Short description]

**Severity**: Critical / High / Medium / Low

**Steps to Reproduce**:
1. 
2. 
3. 

**Expected Result**:
[What should happen]

**Actual Result**:
[What actually happened]

**Screenshots**:
[Attach screenshots if applicable]

**Environment**:
- Device: [e.g., Pixel 6, iPhone 13]
- OS: [e.g., Android 13, iOS 16]
- Flutter Version: [e.g., 3.16.0]
- Backend Version: [e.g., Laravel 10.x]

**Additional Context**:
[Any other relevant information]
```

---

## Test Results Template

```markdown
## Provider Panel Test Results

**Date**: YYYY-MM-DD
**Tester**: [Name]
**Build**: [Version]

### Dashboard Testing
- [ ] Load dashboard: PASS / FAIL
- [ ] Earnings display: PASS / FAIL
- [ ] Service counts: PASS / FAIL
- [ ] Booking stats: PASS / FAIL
- [ ] Pull-to-refresh: PASS / FAIL
- [ ] Navigation: PASS / FAIL

### Services Testing
- [ ] Add service: PASS / FAIL
- [ ] Edit service: PASS / FAIL
- [ ] Delete service: PASS / FAIL
- [ ] Toggle status: PASS / FAIL
- [ ] Form validation: PASS / FAIL

### Bookings Testing
- [ ] View pending: PASS / FAIL
- [ ] Accept booking: PASS / FAIL
- [ ] Reject booking: PASS / FAIL
- [ ] Complete booking: PASS / FAIL
- [ ] Tab navigation: PASS / FAIL

### Analytics Testing
- [ ] Load analytics: PASS / FAIL
- [ ] Change date range: PASS / FAIL
- [ ] Change grouping: PASS / FAIL
- [ ] Quick filters: PASS / FAIL
- [ ] Chart display: PASS / FAIL

### Overall Result: PASS / FAIL

**Issues Found**: [Number]
**Critical Issues**: [Number]
**Notes**: [Any additional observations]
```

---

## Automated Testing (Future)

### Unit Tests:
```dart
// Example unit test
test('EarningsFilter creates correct query params', () {
  final filter = EarningsFilter(
    dateFrom: DateTime(2024, 1, 1),
    dateTo: DateTime(2024, 1, 31),
    groupBy: GroupBy.day,
  );
  
  expect(filter.dateFrom.day, 1);
  expect(filter.groupBy, GroupBy.day);
});
```

### Widget Tests:
```dart
// Example widget test
testWidgets('Dashboard displays earnings card', (tester) async {
  await tester.pumpWidget(ProviderDashboardScreen());
  await tester.pumpAndSettle();
  
  expect(find.text('This Month Earnings'), findsOneWidget);
  expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
});
```

### Integration Tests:
```dart
// Example integration test
testWidgets('Complete booking workflow', (tester) async {
  // 1. Navigate to bookings
  await tester.tap(find.text('Bookings'));
  await tester.pumpAndSettle();
  
  // 2. Accept a booking
  await tester.tap(find.text('Accept').first);
  await tester.pumpAndSettle();
  
  // 3. Verify success notification
  expect(find.text('Booking accepted successfully'), findsOneWidget);
});
```

---

**Happy Testing! 🧪**

