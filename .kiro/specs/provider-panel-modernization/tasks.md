# Implementation Plan: Provider Panel Modernization

## Overview

This implementation plan transforms the service provider experience in the Gharsewa Flutter application by implementing a modern Material Design 3 interface. The implementation follows a layered architecture with clear separation between presentation, business logic, and data layers. The plan focuses on building reusable components, implementing core business logic services, and creating five key screens: Enhanced Profile, Modernized Dashboard, Smart Request Management, AI Safety Center, and Bottom Navigation.

The implementation prioritizes incremental progress with early validation through code integration. Each task builds on previous work, ensuring no orphaned code. Testing tasks are marked as optional to allow for faster MVP delivery while maintaining quality standards.

## Tasks

- [x] 1. Set up project structure and core data models
  - Create directory structure for provider panel feature (`lib/features/provider_panel/`)
  - Create subdirectories: `data/models/`, `data/services/`, `presentation/screens/`, `presentation/widgets/`, `business_logic/`
  - Define all data models: `ProviderProfile`, `Certification`, `EarningsData`, `EarningsDataPoint`, `BookingRequest`, `PerformanceMetrics`, `Suggestion`, `SafetySOP`, `CounterOffer`, `ChartConfig`, `DateRange`
  - Define enums: `BookingRequestStatus`, `SuggestionType`, `SuggestionPriority`, `CounterOfferStatus`, `EarningsViewType`
  - Add required dependencies to `pubspec.yaml`: `provider` (or `riverpod`), `fl_chart`, `hive`, `hive_flutter`, `image_picker`, `http`, `intl`
  - _Requirements: 1.1, 2.1, 3.1, 4.1, 6.1, 8.2, 11.4, 13.1_

- [ ]* 1.1 Write unit tests for data model validation
  - Test `ProviderProfile.completeness` calculation
  - Test enum conversions and edge cases
  - _Requirements: 23.1_

- [ ] 2. Implement data layer services
  - [x] 2.1 Create API client with authentication and error handling
    - Implement HTTP client wrapper with base URL configuration
    - Add authentication token injection for all requests
    - Implement error parsing for 4xx and 5xx responses
    - Add timeout configuration (30 seconds default)
    - _Requirements: 25.1, 26.1, 26.2, 26.3_

  - [x] 2.2 Create Document Uploader service
    - Implement file validation (type and size checks)
    - Implement multipart file upload with progress tracking
    - Add image compression for photos before upload
    - Implement retry logic for failed uploads
    - _Requirements: 1.5, 3.3, 15.1, 15.2, 15.3, 15.4, 15.7, 15.8_

  - [ ]* 2.3 Write property test for file validation
    - **Property 1: Bio Validation Boundary**
    - **Validates: Requirements 1.4**
    - Test that bio validation returns true if and only if length is 50-500 characters

  - [ ]* 2.4 Write property test for skill validation
    - **Property 2: Skill Name Validation Boundary**
    - **Validates: Requirements 2.3**
    - Test that skill validation returns true if and only if length is 3-50 characters

  - [x] 2.5 Create Cache Manager for local data storage
    - Implement in-memory cache with expiration (5 minutes default)
    - Add cache invalidation methods
    - Implement Hive initialization for offline storage
    - _Requirements: 19.1, 28.2_

  - [x] 2.6 Create API endpoints integration
    - Implement GET `/api/provider/profile/:id` endpoint call
    - Implement PUT `/api/provider/profile/:id` endpoint call
    - Implement POST `/api/provider/skills` endpoint call
    - Implement DELETE `/api/provider/skills/:id` endpoint call
    - Implement POST `/api/provider/certifications` endpoint call
    - Implement GET `/api/provider/earnings` endpoint call with date range params
    - Implement GET `/api/provider/requests/pending` endpoint call
    - Implement POST `/api/provider/requests/:id/respond` endpoint call
    - Implement POST `/api/ai/safety-sop` endpoint call
    - Implement GET `/api/provider/metrics` endpoint call
    - _Requirements: 25.1, 25.2, 25.3, 25.4, 25.5, 25.6, 25.7, 25.8, 25.9, 25.10_

- [ ] 3. Implement business logic layer managers
  - [~] 3.1 Create Profile Manager with ChangeNotifier
    - Implement `fetchProfile()` method with API call and caching
    - Implement `updateProfile()` method with validation
    - Implement `updateProfilePhoto()` method with file upload
    - Implement `updateBio()` method with 50-500 character validation
    - Implement `calculateProfileCompleteness()` method (photo 25%, bio 25%, skills 25%, certs 25%)
    - Implement `validateBio()` and `validateProfilePhoto()` methods
    - _Requirements: 1.1, 1.3, 1.4, 1.5, 1.6, 23.1, 23.2, 23.3_

  - [ ]* 3.2 Write property test for profile completeness calculation
    - **Property 13: Profile Completeness Calculation**
    - **Validates: Requirements 23.1**
    - Test that completeness is sum of: 25 (photo) + 25 (bio ≥50) + 25 (skills ≥3) + 25 (certs ≥1)

  - [~] 3.3 Create Skill Manager with ChangeNotifier
    - Implement `fetchSkills()` method with caching
    - Implement `addSkill()` method with validation and duplicate check
    - Implement `removeSkill()` method with API call
    - Implement `validateSkill()` method (3-50 characters)
    - Implement `isDuplicateSkill()` method (case-insensitive)
    - Support up to 20 skills per provider
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 16.1, 16.2, 16.3_

  - [ ]* 3.4 Write property test for duplicate skill detection
    - **Property 8: Duplicate Skill Rejection**
    - **Validates: Requirements 16.3**
    - Test that skill addition rejects if skill already exists (case-insensitive)

  - [ ]* 3.5 Write property test for skill capacity limit
    - **Property 3: Skill Capacity Limit**
    - **Validates: Requirements 2.6**
    - Test that skill addition is accepted if and only if current count < 20

  - [~] 3.6 Create Certification Manager with ChangeNotifier
    - Implement `fetchCertifications()` method
    - Implement `uploadCertification()` method with file validation (PDF/PNG/JPG, <10MB)
    - Implement `deleteCertification()` method
    - Implement `validateCertificationFile()` method
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.7_

  - [~] 3.7 Create Earnings Analyzer with ChangeNotifier
    - Implement `fetchEarnings()` method with date range support
    - Implement `calculatePercentageChange()` method
    - Implement `getDailyEarnings()` method (last 7 days)
    - Implement `getWeeklyEarnings()` method (last 4 weeks)
    - Implement `formatCurrency()` method with locale support
    - _Requirements: 6.1, 6.2, 6.5, 6.7, 21.1, 21.7_

  - [ ]* 3.8 Write property test for percentage change calculation
    - **Property 5: Earnings Percentage Change Calculation**
    - **Validates: Requirements 6.5, 21.1**
    - Test that percentage change = ((current - previous) / previous) × 100 for non-zero previous

  - [ ]* 3.9 Write property test for currency formatting
    - **Property 6: Currency Formatting Consistency**
    - **Validates: Requirements 6.7**
    - Test that currency formatting includes locale-appropriate symbol and number format

  - [~] 3.10 Create Performance Tracker with ChangeNotifier
    - Implement `fetchMetrics()` method
    - Implement `calculateAverageResponseTime()` method
    - Implement `isTopPerformer()` method (top 10% check)
    - Implement `formatResponseTime()` method (minutes if <60, else hours)
    - Implement `getResponseTimeColor()` method (green <15min, yellow 15-60min, red >60min)
    - _Requirements: 4.1, 4.2, 4.3, 4.5, 4.6, 18.3, 18.4, 18.5_

  - [ ]* 3.11 Write property test for response time formatting
    - **Property 4: Response Time Formatting Threshold**
    - **Validates: Requirements 4.6**
    - Test that formatting uses "minutes" when <60 minutes, "hours" when ≥60 minutes

  - [ ]* 3.12 Write property test for average response time
    - **Property 10: Average Response Time Calculation**
    - **Validates: Requirements 18.3**
    - Test that average = sum of response times / count for non-empty lists

  - [~] 3.13 Create Request Manager with ChangeNotifier
    - Implement `watchPendingRequests()` stream method
    - Implement `acceptRequest()` method with 2-second response time
    - Implement `declineRequest()` method with reason parameter
    - Implement `sendCounterOffer()` method with price and message
    - Implement `sortRequestsByDate()` method (descending order)
    - Implement `filterUrgentRequests()` method (scheduled within 24 hours)
    - Add auto-refresh every 30 seconds when screen is active
    - _Requirements: 8.1, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 17.1, 17.5, 22.1, 22.2, 22.7_

  - [ ]* 3.14 Write property test for request sorting
    - **Property 7: Request Sorting Invariant**
    - **Validates: Requirements 8.8, 22.1**
    - Test that sorted output maintains descending order by createdAt for all adjacent pairs

  - [ ]* 3.15 Write property test for urgency detection
    - **Property 12: Urgency Detection Threshold**
    - **Validates: Requirements 22.2**
    - Test that urgency returns true if and only if scheduled time is within 24 hours

  - [ ]* 3.16 Write property test for counter-offer price validation
    - **Property 14: Counter-Offer Price Validation**
    - **Validates: Requirements 17.3**
    - Test that price validation returns true if and only if value > 0

  - [~] 3.17 Create AI Suggestion Engine
    - Implement `generateProfileSuggestions()` method
    - Implement `generateDashboardSuggestions()` method
    - Implement `generateSafetySOP()` method with job type parameter
    - Implement `prioritizeSuggestions()` method
    - Add error handling for AI service failures (silent fail for suggestions, retry for SOPs)
    - _Requirements: 5.1, 5.2, 5.4, 9.1, 9.2, 9.4, 11.3, 11.5_

  - [~] 3.18 Create Safety Center manager with ChangeNotifier
    - Implement `generateSOP()` method calling AI engine
    - Implement `saveSOP()` method with Hive storage
    - Implement `fetchSavedSOPs()` method from local storage
    - Implement `deleteSOP()` method
    - Implement `searchSOPs()` method with full-text search
    - Implement `syncSOPs()` method for online/offline sync
    - _Requirements: 11.1, 11.6, 11.7, 11.8, 19.1, 19.2, 19.4, 19.7_

- [ ] 4. Create reusable UI components
  - [~] 4.1 Create GradientCard widget
    - Implement card with gradient background support
    - Add elevation and rounded corners per Material Design 3
    - Support custom gradient colors and child widgets
    - _Requirements: 13.2, 13.5, 13.6_

  - [~] 4.2 Create SkillChip widget
    - Implement chip with skill name display
    - Add remove icon that appears on tap
    - Implement fade and scale animations for add/remove
    - Use consistent styling (background color, padding, text color)
    - _Requirements: 2.1, 2.5, 16.5, 16.7_

  - [~] 4.3 Create MetricCard widget
    - Implement card displaying icon, label, and value
    - Support gradient backgrounds
    - Add responsive sizing
    - _Requirements: 4.1, 7.1, 13.2_

  - [~] 4.4 Create RequestCard widget
    - Display customer avatar, name, location
    - Display service title, description, proposed price, date/time
    - Add Accept, Counter, and Decline action buttons
    - Highlight urgent requests with distinct visual indicator
    - Display time elapsed since request creation
    - _Requirements: 8.2, 8.3, 8.4, 8.6, 22.2, 22.3_

  - [~] 4.5 Create SuggestionCard widget
    - Implement card with purple gradient background
    - Display suggestion title and description
    - Add dismiss button
    - Implement swipe gesture for viewing more suggestions
    - _Requirements: 5.3, 9.3, 9.7_

  - [~] 4.6 Create VerifiedBadge widget
    - Implement checkmark icon in colored circle
    - Support different sizes for various contexts
    - _Requirements: 1.2, 20.1, 20.2, 20.3_

  - [~] 4.7 Create ProfileHeader widget
    - Display profile photo with circular crop
    - Display name and verified badge
    - Display location and professional category
    - _Requirements: 1.1, 1.2, 1.7, 20.3_

  - [~] 4.8 Create EmptyState widget
    - Display icon, message, and optional call-to-action button
    - Support different empty state scenarios
    - _Requirements: 22.6_

- [ ] 5. Implement earnings chart visualization
  - [~] 5.1 Create ChartRenderer widget using fl_chart
    - Implement bar chart with labeled axes
    - Add gradient fills for bars
    - Implement touch interaction to display exact values
    - Add smooth animation with 500ms duration
    - Scale y-axis automatically based on data range
    - Display "No data available" empty state
    - _Requirements: 6.3, 6.4, 14.1, 14.2, 14.3, 14.4, 14.5, 14.6, 14.7, 14.8_

  - [~] 5.2 Create EarningsChart widget wrapper
    - Integrate ChartRenderer with earnings data
    - Add daily/weekly toggle switch
    - Display total earnings and percentage change indicator
    - Update chart within 500ms when toggling views
    - Use green for positive change, red for negative change
    - _Requirements: 6.1, 6.2, 6.3, 6.5, 6.6, 21.2, 21.3_

  - [ ]* 5.3 Write property test for percentage formatting
    - **Property 11: Percentage Formatting Precision**
    - **Validates: Requirements 21.5**
    - Test that percentage formatting returns string with exactly one decimal place

  - [ ]* 5.4 Write widget tests for chart interactions
    - Test chart renders with valid data
    - Test empty state displays when no data
    - Test touch interaction shows values
    - _Requirements: 14.5, 14.7_

- [~] 6. Checkpoint - Verify core components and business logic
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. Implement Profile Screen
  - [~] 7.1 Create ProfileScreen with scrollable layout
    - Add ProfileHeader widget at top
    - Display bio section with edit button
    - Display skills section with SkillChip widgets in Wrap layout
    - Display certifications section with list of uploaded documents
    - Display performance metrics section (rating, jobs completed, response time)
    - Display profile completeness indicator with progress bar
    - Display AI suggestions card
    - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.7, 3.1, 4.1, 4.2, 4.3, 5.1, 5.3, 23.1, 23.3, 23.4_

  - [~] 7.2 Implement profile editing functionality
    - Create edit profile dialog/screen
    - Add bio text field with 50-500 character validation and counter
    - Add profile photo picker with image selection
    - Implement save button that calls Profile Manager
    - Display validation errors below fields
    - Show loading indicator during save
    - _Requirements: 1.3, 1.4, 1.5, 1.6_

  - [~] 7.3 Implement skill management functionality
    - Create add skill dialog with text input
    - Validate skill name (3-50 characters)
    - Check for duplicate skills before adding
    - Implement skill removal on chip tap
    - Display empty state when no skills exist
    - Animate skill additions and removals
    - _Requirements: 2.2, 2.3, 2.4, 2.5, 16.1, 16.2, 16.3, 16.6, 16.7_

  - [~] 7.4 Implement certification management functionality
    - Create add certification button
    - Implement file picker for PDF/PNG/JPG
    - Validate file size (<10MB) and type
    - Display upload progress indicator
    - Show verification status badge for each certification
    - Implement certification viewer on tap
    - Implement delete functionality for unverified certifications
    - Handle upload errors with retry option
    - _Requirements: 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 15.3, 15.6, 15.7_

  - [ ]* 7.5 Write widget tests for ProfileScreen
    - Test profile header displays correctly
    - Test skill chip interactions
    - Test certification upload flow
    - Test profile completeness calculation
    - _Requirements: 1.1, 2.1, 3.1, 23.1_

- [ ] 8. Implement Dashboard Screen
  - [~] 8.1 Create DashboardScreen with scrollable layout
    - Add earnings summary card with EarningsChart widget
    - Add rating card with MetricCard widget and top performer badge
    - Add AI smart suggestion card with SuggestionCard widget
    - Add quick action buttons grid (2x2: Schedule, Invoices, Support, Inventory)
    - Add pending requests section with RequestCard widgets
    - Implement pull-to-refresh functionality
    - _Requirements: 6.1, 7.1, 7.2, 7.3, 8.1, 9.1, 9.3, 10.1, 10.2, 10.8_

  - [~] 8.2 Implement quick action navigation
    - Wire Schedule button to schedule management screen
    - Wire Invoices button to invoices screen
    - Wire Support button to support/help screen
    - Wire Inventory button to inventory management screen
    - Display icons and labels for each button
    - _Requirements: 10.3, 10.4, 10.5, 10.6, 10.7_

  - [~] 8.3 Implement pending requests management
    - Display list of pending requests sorted by date (most recent first)
    - Highlight urgent requests (scheduled within 24 hours)
    - Display time elapsed since request creation
    - Implement Accept button with confirmation
    - Implement Counter button with counter-offer dialog
    - Implement Decline button with reason selection dialog
    - Auto-refresh request list every 30 seconds
    - Display empty state when no pending requests
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 22.1, 22.2, 22.3, 22.6, 22.7_

  - [~] 8.4 Implement counter-offer dialog
    - Pre-fill with customer's proposed price for reference
    - Add price input field with validation (must be > 0)
    - Add optional message text field
    - Implement submit button that calls Request Manager
    - Display validation errors
    - Show loading indicator during submission
    - _Requirements: 17.1, 17.2, 17.3, 17.4, 17.5_

  - [~] 8.5 Implement AI suggestion display and dismissal
    - Display suggestion with title and description
    - Implement dismiss button
    - Store dismissed suggestions to prevent re-display for 7 days
    - Implement swipe gesture to view more suggestions
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.7_

  - [ ]* 8.6 Write widget tests for DashboardScreen
    - Test earnings chart displays correctly
    - Test quick action buttons navigate correctly
    - Test request card interactions
    - Test counter-offer dialog validation
    - _Requirements: 6.1, 8.1, 10.1, 17.3_

- [ ] 9. Implement Safety Center Screen
  - [~] 9.1 Create SafetyCenterScreen with two sections
    - Add AI Safety & SOP Generator section at top
    - Add Saved SOPs library section below
    - Implement offline mode indicator
    - _Requirements: 11.1, 11.8, 19.3_

  - [~] 9.2 Implement SOP generator functionality
    - Add job type text input field
    - Add Generate button
    - Display loading indicator during generation (with "Taking longer than usual" message after 10s)
    - Display generated SOP in readable format with sections (hazards, PPE, procedures, emergency protocols)
    - Add Save button to store SOP locally
    - Handle generation failures with error message and retry option
    - _Requirements: 11.2, 11.3, 11.4, 11.5, 11.6_

  - [~] 9.3 Implement saved SOPs library
    - Display list of saved SOPs with job type and generation date
    - Implement full-text search across saved SOPs
    - Display SOPs from local storage (Hive)
    - Implement delete functionality for saved SOPs
    - Display empty state when no saved SOPs exist
    - Support offline access to all saved SOPs
    - Implement sync functionality when online
    - _Requirements: 11.7, 11.8, 19.1, 19.2, 19.4, 19.5, 19.6, 19.7_

  - [ ]* 9.4 Write widget tests for SafetyCenterScreen
    - Test SOP generator displays correctly
    - Test saved SOPs list displays correctly
    - Test search functionality
    - Test offline mode indicator
    - _Requirements: 11.1, 11.8, 19.3, 19.7_

- [~] 10. Checkpoint - Verify all screens are functional
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Implement Navigation and Integration
  - [~] 11.1 Create Navigation Controller with ChangeNotifier
    - Implement bottom navigation state management
    - Add methods: `navigateToTab()`, `navigateToScreen()`, `canPop()`, `pop()`
    - Maintain navigation stack for each tab
    - _Requirements: 12.6, 12.8_

  - [~] 11.2 Create ProviderPanelRoot widget with bottom navigation
    - Implement bottom navigation bar with 4 tabs: Explore, Bookings, Safety Center, Profile
    - Use appropriate icons for each tab (grid, calendar, shield, person)
    - Highlight active tab with distinct color
    - Wire tabs to corresponding screens
    - Preserve state when switching tabs
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 12.7, 12.8_

  - [~] 11.3 Implement screen transitions and animations
    - Add fade transitions for screen navigation
    - Add slide-up transitions for card appearances
    - Implement spring animations for button interactions
    - Ensure all animations maintain 60 FPS
    - Limit screen transition duration to 300ms
    - Provide reduced motion alternatives for accessibility
    - _Requirements: 13.3, 24.1, 24.2, 24.5, 24.6, 24.7, 24.8_

  - [~] 11.4 Wire all screens to Navigation Controller
    - Connect Dashboard screen to Explore tab
    - Connect Bookings screen to Bookings tab (placeholder if not yet implemented)
    - Connect Safety Center screen to Safety Center tab
    - Connect Profile screen to Profile tab
    - Implement deep linking support for direct navigation
    - _Requirements: 12.2, 12.3, 12.4, 12.5_

  - [ ]* 11.5 Write integration tests for navigation flows
    - Test navigation between all tabs
    - Test state preservation when switching tabs
    - Test deep linking navigation
    - _Requirements: 12.8_

- [ ] 12. Implement error handling and loading states
  - [~] 12.1 Add network error handling
    - Display "No internet connection" message with retry button for connection errors
    - Display "Request timed out" message with exponential backoff retry for timeouts
    - Display "Server error" message for 5xx errors
    - Parse and display specific error messages for 4xx errors
    - Preserve selected files on upload failure and provide retry option
    - _Requirements: 26.1, 26.2, 26.3, 26.5_

  - [~] 12.2 Add validation error handling
    - Display "Bio must be between 50 and 500 characters" for bio validation failures
    - Display "Skill name must be between 3 and 50 characters" for skill validation failures
    - Display specific file validation error messages (format, size)
    - Display "Price must be greater than zero" for counter-offer validation failures
    - _Requirements: 1.4, 2.3, 3.3, 17.3_

  - [~] 12.3 Add loading states
    - Display skeleton screens during data fetching
    - Display shimmer effects for loading cards
    - Display refresh indicator when cached data is older than 5 minutes
    - Display progress indicators for file uploads
    - _Requirements: 15.3, 28.2_

  - [~] 12.4 Add empty states
    - Display "No pending requests" message with availability update prompt
    - Display "Add your first skill" message with add button
    - Display "Upload certifications" message with upload button
    - Display "No earnings data available" message for empty earnings
    - Display "No saved SOPs" message in Safety Center
    - _Requirements: 16.6, 22.6_

  - [ ]* 12.5 Write unit tests for error handling
    - Test network error message formatting
    - Test validation error display
    - Test empty state rendering
    - _Requirements: 26.1, 26.2_

- [ ] 13. Implement accessibility and performance optimizations
  - [~] 13.1 Add accessibility features
    - Add semantic labels for all interactive elements
    - Ensure color contrast ratios meet WCAG AA (4.5:1 for text)
    - Set minimum touch target size to 48x48 dp for all interactive elements
    - Add alternative text for all icons and images
    - Support dynamic text sizing for all text elements
    - Add haptic feedback for important actions (accept request, save profile)
    - Avoid relying solely on color to convey information (use icons with color)
    - _Requirements: 27.1, 27.2, 27.3, 27.4, 27.5, 27.7, 27.8_

  - [~] 13.2 Add performance optimizations
    - Implement caching for profile data with 5-minute expiration
    - Implement lazy loading for images in request lists
    - Implement pagination for lists with more than 20 items
    - Compress images before upload
    - Optimize chart rendering to complete in <500ms
    - Ensure dashboard loads in <2 seconds on 4G
    - Monitor and maintain 60 FPS during animations
    - Disable animations if performance drops below 30 FPS
    - _Requirements: 28.1, 28.2, 28.3, 28.4, 28.5, 28.6, 28.7_

  - [ ]* 13.3 Write performance benchmark tests
    - Test dashboard load time (<2 seconds)
    - Test chart rendering time (<500ms)
    - Test animation frame rate (60 FPS)
    - _Requirements: 28.1, 28.5, 28.6_

- [ ] 14. Final integration and polish
  - [~] 14.1 Implement Material Design 3 theming
    - Define color scheme with primary, secondary, and accent colors
    - Apply consistent elevation and shadows
    - Use consistent border radius for cards and buttons
    - Implement typography hierarchy with consistent font sizes and weights
    - Apply gradient styling to key cards (earnings, AI suggestions)
    - _Requirements: 13.1, 13.2, 13.4, 13.5, 13.6, 13.8_

  - [~] 14.2 Add responsive layout support
    - Ensure layouts adapt to different screen sizes
    - Test on small (320dp), medium (360dp), and large (480dp) screen widths
    - Test portrait and landscape orientations
    - _Requirements: 13.7_

  - [~] 14.3 Add locale and internationalization support
    - Implement currency formatting with locale support
    - Support dynamic locale switching
    - Test with different locales (en_US, es_ES, etc.)
    - _Requirements: 6.7_

  - [ ]* 14.4 Write integration tests for complete user flows
    - Test profile update flow (edit bio, add skill, upload certification)
    - Test request management flow (accept request, send counter-offer, decline request)
    - Test SOP generation flow (generate, save, access offline)
    - Test earnings view flow (toggle daily/weekly, view chart)
    - _Requirements: 1.6, 8.3, 11.6, 6.3_

- [~] 15. Final checkpoint - Comprehensive testing and verification
  - Ensure all tests pass, ask the user if questions arise.


## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP delivery
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- Widget tests ensure UI components render and interact correctly
- Integration tests verify end-to-end user flows
- The implementation uses Dart/Flutter as specified in the design document
- All business logic is separated from UI components for testability
- State management uses Provider (or Riverpod) pattern
- Offline support is implemented using Hive for local storage
- Material Design 3 guidelines are followed throughout
- Accessibility compliance targets WCAG AA standards
- Performance targets: <2s dashboard load, <500ms chart render, 60 FPS animations

## Task Dependency Graph

```json
{
  "waves": [
    {
      "id": 0,
      "tasks": ["1.1", "2.1"]
    },
    {
      "id": 1,
      "tasks": ["2.2", "2.5", "2.6"]
    },
    {
      "id": 2,
      "tasks": ["2.3", "2.4", "3.1", "3.3", "3.6", "3.7", "3.10", "3.13", "3.17"]
    },
    {
      "id": 3,
      "tasks": ["3.2", "3.4", "3.5", "3.8", "3.9", "3.11", "3.12", "3.14", "3.15", "3.16", "3.18", "4.1", "4.2", "4.3", "4.4", "4.5", "4.6", "4.7", "4.8"]
    },
    {
      "id": 4,
      "tasks": ["5.1"]
    },
    {
      "id": 5,
      "tasks": ["5.2", "5.3", "5.4"]
    },
    {
      "id": 6,
      "tasks": ["7.1", "7.2", "7.3", "7.4"]
    },
    {
      "id": 7,
      "tasks": ["7.5", "8.1", "8.2", "8.3", "8.4", "8.5"]
    },
    {
      "id": 8,
      "tasks": ["8.6", "9.1", "9.2", "9.3"]
    },
    {
      "id": 9,
      "tasks": ["9.4", "11.1"]
    },
    {
      "id": 10,
      "tasks": ["11.2", "11.3", "11.4"]
    },
    {
      "id": 11,
      "tasks": ["11.5", "12.1", "12.2", "12.3", "12.4"]
    },
    {
      "id": 12,
      "tasks": ["12.5", "13.1", "13.2"]
    },
    {
      "id": 13,
      "tasks": ["13.3", "14.1", "14.2", "14.3"]
    },
    {
      "id": 14,
      "tasks": ["14.4"]
    }
  ]
}
```
