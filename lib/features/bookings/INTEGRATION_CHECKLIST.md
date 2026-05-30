# BookingRealtime Integration Checklist

Use this checklist to ensure proper integration of the BookingRealtime feature into your app.

## Pre-Integration Checklist

- [ ] Backend WebSocket server is running (Laravel Reverb)
- [ ] WebSocket configuration is set in environment variables
- [ ] JWT authentication is working
- [ ] Booking API endpoints are functional
- [ ] WebSocket connection manager is implemented (`lib/core/websocket/`)

## Integration Steps

### Step 1: Add BookingRealtimeListener to App
- [ ] Import the bookings feature: `import 'package:gharsewa/features/bookings/bookings.dart';`
- [ ] Wrap your app content with `BookingRealtimeListener`:
  ```dart
  MaterialApp(
    home: BookingRealtimeListener(
      child: YourMainScreen(),
    ),
  )
  ```
- [ ] Verify the app compiles without errors

### Step 2: Verify Booking List Providers
- [ ] Provider bookings screen uses `providerBookingsProvider`
- [ ] Customer bookings screen uses `customerBookingsProvider`
- [ ] Both providers are imported from the correct location
- [ ] Booking lists display correctly

### Step 3: Test WebSocket Connection
- [ ] Start the app and log in
- [ ] Check WebSocket connection status indicator shows "Live"
- [ ] Check console logs for "WebSocket connection established"
- [ ] Verify no connection errors in logs

### Step 4: Test Real-Time Updates
- [ ] Create a test booking via the app or API
- [ ] Update the booking status via the backend API or provider panel
- [ ] Verify the booking list updates automatically (no manual refresh needed)
- [ ] Verify scroll position is maintained after update

### Step 5: Test Notifications
- [ ] Update a booking status to "confirmed"
  - [ ] Snackbar appears with green background
  - [ ] Message says "Booking confirmed! Your service has been scheduled."
  - [ ] Check icon is displayed
- [ ] Update a booking status to "completed"
  - [ ] Snackbar appears with blue background
  - [ ] Message says "Booking completed! Thank you for using our service."
  - [ ] Task icon is displayed
- [ ] Update a booking status to "cancelled"
  - [ ] Snackbar appears with orange background
  - [ ] Message says "Booking cancelled."
  - [ ] Cancel icon is displayed
- [ ] Verify snackbar auto-dismisses after 4 seconds
- [ ] Verify "View" button is present (navigation not yet implemented)

### Step 6: Test Error Handling
- [ ] Stop the WebSocket server
- [ ] Verify connection status shows "Disconnected" or "Reconnecting..."
- [ ] Verify app continues to function (graceful degradation)
- [ ] Restart WebSocket server
- [ ] Verify connection is re-established automatically
- [ ] Verify booking updates work again

### Step 7: Test Edge Cases
- [ ] Test with invalid event data (missing booking_id)
  - [ ] Verify error is logged but app doesn't crash
- [ ] Test with multiple rapid status changes
  - [ ] Verify all updates are processed
  - [ ] Verify notifications don't overlap excessively
- [ ] Test with user logout
  - [ ] Verify WebSocket connection is closed
  - [ ] Verify no errors after logout
- [ ] Test with user login
  - [ ] Verify WebSocket connection is established
  - [ ] Verify booking events are received

## Post-Integration Verification

### Functionality
- [ ] Booking lists update in real-time
- [ ] Notifications appear for important status changes
- [ ] WebSocket connection is stable
- [ ] No memory leaks (check with Flutter DevTools)
- [ ] No performance issues

### Code Quality
- [ ] No compilation errors
- [ ] No analyzer warnings
- [ ] Code follows project conventions
- [ ] Proper error handling in place
- [ ] Logging is appropriate (not too verbose, not too sparse)

### Documentation
- [ ] README.md reviewed
- [ ] USAGE_EXAMPLE.md reviewed
- [ ] Integration instructions are clear
- [ ] Team members understand how to use the feature

### Testing
- [ ] Manual testing completed
- [ ] Edge cases tested
- [ ] Error scenarios tested
- [ ] Cross-platform testing (web and desktop if applicable)

## Troubleshooting

If you encounter issues, check:

1. **WebSocket Connection**
   - [ ] Backend WebSocket server is running
   - [ ] WebSocket URL is correct in environment config
   - [ ] JWT token is valid
   - [ ] No firewall blocking WebSocket connections

2. **Booking List Not Updating**
   - [ ] Correct provider is used in the screen
   - [ ] Provider invalidation is working (check logs)
   - [ ] Event data is valid (check logs)
   - [ ] WebSocket connection is established

3. **Notifications Not Showing**
   - [ ] `BookingRealtimeListener` is in the widget tree
   - [ ] Status change is one of: confirmed, completed, cancelled
   - [ ] Event data contains required fields
   - [ ] No errors in console logs

4. **Performance Issues**
   - [ ] Check for memory leaks with Flutter DevTools
   - [ ] Verify provider invalidation isn't too frequent
   - [ ] Check WebSocket message rate
   - [ ] Review logging verbosity

## Rollback Plan

If you need to rollback the integration:

1. Remove `BookingRealtimeListener` from your app
2. Remove the import: `import 'package:gharsewa/features/bookings/bookings.dart';`
3. Booking lists will continue to work with manual refresh
4. No data loss or corruption will occur

## Next Steps

After successful integration:

- [ ] Monitor WebSocket connection stability in production
- [ ] Gather user feedback on notifications
- [ ] Consider implementing navigation from notifications
- [ ] Consider adding notification preferences
- [ ] Consider adding sound/vibration for notifications
- [ ] Plan for scaling (multiple WebSocket server instances)

## Support

If you need help:

1. Review the documentation:
   - `README.md` - Architecture and overview
   - `USAGE_EXAMPLE.md` - Practical examples
   - `TASK_8.1_COMPLETION_SUMMARY.md` - Implementation details

2. Check the logs:
   - WebSocket connection logs
   - Booking event logs
   - Provider invalidation logs

3. Review the spec:
   - `.kiro/specs/realtime-websockets/design.md`
   - `.kiro/specs/realtime-websockets/requirements.md`

4. Contact the development team

## Sign-Off

Integration completed by: ___________________  
Date: ___________________  
Verified by: ___________________  
Date: ___________________  

Notes:
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
