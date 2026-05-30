# Implementation Plan: Cross-Platform Image Handling

## Overview

This implementation plan converts the cross-platform image handling design into actionable coding tasks. The system provides a unified abstraction layer for image selection, storage, display, and upload across web browsers and desktop platforms (Windows, macOS, Linux). The implementation follows a three-phase approach: core infrastructure creation, integration with existing features, and testing/validation.

## Tasks

- [ ] 1. Create core infrastructure for platform-aware image handling
  - [x] 1.1 Create PlatformImage sealed class model
    - Create `lib/core/models/platform_image.dart` file
    - Implement sealed class `PlatformImage` with abstract methods `toBase64()` and `getSizeInBytes()`
    - Implement `WebPlatformImage` final class with `Uint8List bytes` field
    - Implement `DesktopPlatformImage` final class with `File file` field
    - Add factory constructor `PlatformImage.fromPlatform()` that uses `kIsWeb` for platform detection
    - Implement `toBase64()` method for both web (direct encoding) and desktop (read file then encode)
    - Implement `getSizeInBytes()` method for both platforms
    - Add equality operators and hashCode for both classes
    - Import required packages: `dart:io`, `dart:typed_data`, `dart:convert`, `package:flutter/foundation.dart`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 3.1, 3.2, 5.1, 5.2_

  - [x] 1.2 Create ImageService for platform-agnostic image operations
    - Create `lib/core/services/image_service.dart` file
    - Define `ImageSelectionResult` class with fields: `PlatformImage? image`, `bool wasCancelled`, `String? errorMessage`
    - Add computed properties `isSuccess` and `hasError` to `ImageSelectionResult`
    - Implement `ImageService` class with `ImagePicker` instance
    - Implement `selectImage()` method that detects platform and delegates to platform-specific methods
    - Implement `_selectImageWeb()` private method using `image_picker` with bytes
    - Implement `_selectImageDesktop()` private method using `file_picker` for gallery and `image_picker` for camera
    - Handle cancellation by returning `ImageSelectionResult(wasCancelled: true)`
    - Handle errors by returning `ImageSelectionResult(errorMessage: ...)`
    - Implement `imageToBase64()` method that delegates to `PlatformImage.toBase64()`
    - Implement `getImageSize()` method that delegates to `PlatformImage.getSizeInBytes()`
    - Import required packages: `dart:io`, `dart:typed_data`, `package:flutter/foundation.dart`, `package:image_picker/image_picker.dart`, `package:file_picker/file_picker.dart`
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 5.1, 5.2, 5.3, 5.4, 10.1, 10.4_

  - [x] 1.3 Create ImageDisplayWidget for platform-aware image rendering
    - Create `lib/core/widgets/image_display_widget.dart` file
    - Implement `ImageDisplayWidget` as a `StatelessWidget`
    - Add constructor parameters: `PlatformImage image`, `BoxFit fit`, `double? width`, `double? height`, `Widget? errorWidget`, `Widget? loadingWidget`
    - Implement `build()` method using switch expression for pattern matching on `PlatformImage`
    - For `WebPlatformImage`, use `Image.memory()` with bytes
    - For `DesktopPlatformImage`, use `Image.file()` with file
    - Add `errorBuilder` that shows custom error widget or default error widget
    - Add `loadingBuilder` for web images that shows loading indicator
    - Implement `_defaultErrorWidget()` with error icon and message
    - Implement `_defaultLoadingWidget()` with circular progress indicator
    - Import required packages: `dart:io`, `package:flutter/material.dart`, `../models/platform_image.dart`
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 10.2, 12.2_

- [~] 2. Checkpoint - Verify core infrastructure
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 3. Update AI Visual Assistant to use platform-aware image handling
  - [x] 3.1 Update CurrentConsultationState to use PlatformImage
    - Open `lib/presentation/panels/customer/ai_consultation/state/current_consultation_state.dart`
    - Replace `File? imageFile` field with `PlatformImage? image`
    - Update `copyWith()` method to accept `PlatformImage? image` parameter
    - Update `clearImage` logic in `copyWith()` method
    - Update `hasImage` getter to check `image != null`
    - Update equality operator to compare `image` instead of `imageFile`
    - Update `hashCode` to use `image` instead of `imageFile`
    - Update `toString()` method to reflect new field name
    - Import `package:gharsewa/core/models/platform_image.dart`
    - _Requirements: 3.1, 3.2, 3.3, 6.1, 6.2, 6.3_

  - [x] 3.2 Update CurrentConsultationNotifier to use ImageService
    - Open `lib/presentation/panels/customer/ai_consultation/state/current_consultation_notifier.dart`
    - Add `ImageService` instance as a class field
    - Update `selectImage()` method to use `ImageService.selectImage()`
    - Handle `ImageSelectionResult` by checking `isSuccess`, `wasCancelled`, and `hasError`
    - Update state with `PlatformImage` when selection succeeds
    - Show error message when selection fails
    - Update `clearImage()` method to clear `PlatformImage` from state
    - Import `package:gharsewa/core/services/image_service.dart` and `package:gharsewa/core/models/platform_image.dart`
    - _Requirements: 2.1, 2.2, 2.3, 6.1, 10.1_

  - [x] 3.3 Update ImageCaptureScreen to use ImageDisplayWidget
    - Open `lib/presentation/panels/customer/ai_consultation/screens/image_capture_screen.dart`
    - Replace `Image.file()` widget with `ImageDisplayWidget`
    - Pass `PlatformImage` from state to `ImageDisplayWidget`
    - Remove platform-specific image display logic
    - Update error handling to use `ImageDisplayWidget`'s built-in error widget
    - Import `package:gharsewa/core/widgets/image_display_widget.dart`
    - _Requirements: 4.1, 4.2, 4.3, 6.2, 6.3, 6.6, 12.2_

  - [x] 3.4 Update AnnotationCanvas to use ImageDisplayWidget
    - Open `lib/presentation/panels/customer/ai_consultation/widgets/annotation_canvas.dart`
    - Replace any `Image.file()` widgets with `ImageDisplayWidget`
    - Update image rendering logic to use `PlatformImage`
    - Ensure annotation overlay works correctly with platform-agnostic image display
    - Import `package:gharsewa/core/widgets/image_display_widget.dart`
    - _Requirements: 4.1, 4.2, 4.3, 6.4, 12.2_

  - [x] 3.5 Update AIConsultationApiService to use ImageService for base64 conversion
    - Open `lib/services/api/ai_consultation_api_service.dart`
    - Add `ImageService` instance as a class field
    - Update image upload logic to accept `PlatformImage` instead of `File`
    - Use `ImageService.imageToBase64()` to convert image to base64 string
    - Update API request to include base64-encoded image
    - Handle conversion errors and return appropriate error messages
    - Import `package:gharsewa/core/services/image_service.dart` and `package:gharsewa/core/models/platform_image.dart`
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 6.5, 11.1, 11.2, 11.3_

- [~] 4. Checkpoint - Verify AI Visual Assistant integration
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Update customer profile management to use platform-aware image handling
  - [x] 5.1 Update EditProfileScreen to use ImageService
    - Open `lib/presentation/panels/customer/screens/edit_profile_screen.dart`
    - Add `ImageService` instance
    - Update profile photo selection to use `ImageService.selectImage()`
    - Handle `ImageSelectionResult` with success, cancellation, and error cases
    - Store selected image as `PlatformImage` in local state
    - Update image display to use `ImageDisplayWidget`
    - Import `package:gharsewa/core/services/image_service.dart`, `package:gharsewa/core/models/platform_image.dart`, and `package:gharsewa/core/widgets/image_display_widget.dart`
    - _Requirements: 2.1, 2.2, 2.3, 4.1, 4.2, 7.1, 7.2, 7.3, 12.1, 12.2_

  - [x] 5.2 Update UserRepository to accept PlatformImage
    - Open `lib/data/repositories/user_repository.dart`
    - Update profile update methods to accept `PlatformImage?` instead of `File?`
    - Add `ImageService` instance for base64 conversion
    - Use `ImageService.imageToBase64()` to convert image before API call
    - Update error handling for image conversion failures
    - Import `package:gharsewa/core/services/image_service.dart` and `package:gharsewa/core/models/platform_image.dart`
    - _Requirements: 5.1, 5.2, 5.3, 7.4, 11.1, 11.2, 11.3_

- [x] 6. Update provider profile management to use platform-aware image handling
  - [x] 6.1 Update ProviderProfileScreen to use ImageService
    - Open `lib/features/provider_panel/presentation/screens/provider_profile_screen.dart`
    - Add `ImageService` instance
    - Update profile photo selection to use `ImageService.selectImage()`
    - Handle `ImageSelectionResult` with success, cancellation, and error cases
    - Store selected image as `PlatformImage` in local state
    - Update image display to use `ImageDisplayWidget`
    - Import `package:gharsewa/core/services/image_service.dart`, `package:gharsewa/core/models/platform_image.dart`, and `package:gharsewa/core/widgets/image_display_widget.dart`
    - _Requirements: 2.1, 2.2, 2.3, 4.1, 4.2, 8.1, 8.2, 8.3, 12.1, 12.2_

  - [x] 6.2 Update ProviderUploadService to accept PlatformImage
    - Open `lib/features/provider_panel/data/services/provider_upload_service.dart`
    - Update profile photo upload methods to accept `PlatformImage` instead of `File`
    - Update certificate upload methods to accept `PlatformImage` instead of `File`
    - Add `ImageService` instance for base64 conversion
    - Use `ImageService.imageToBase64()` to convert images before API calls
    - Update error handling for image conversion failures
    - Import `package:gharsewa/core/services/image_service.dart` and `package:gharsewa/core/models/platform_image.dart`
    - _Requirements: 5.1, 5.2, 5.3, 8.4, 9.5, 11.1, 11.2, 11.3_

- [ ] 7. Update certificate upload functionality to use platform-aware image handling
  - [x] 7.1 Update certificate upload UI to use ImageService
    - Locate certificate upload screen/widget in provider panel
    - Add `ImageService` instance
    - Update certificate image selection to use `ImageService.selectImage()`
    - Handle `ImageSelectionResult` with success, cancellation, and error cases
    - Store selected certificate images as `List<PlatformImage>` in local state
    - Update certificate preview display to use `ImageDisplayWidget`
    - Import `package:gharsewa/core/services/image_service.dart`, `package:gharsewa/core/models/platform_image.dart`, and `package:gharsewa/core/widgets/image_display_widget.dart`
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.6, 12.1, 12.2_

  - [x] 7.2 Verify certificate upload service integration
    - Ensure `ProviderUploadService` correctly handles certificate uploads with `PlatformImage`
    - Verify base64 conversion works correctly for certificates
    - Test error handling when certificate upload fails
    - _Requirements: 9.5, 10.3, 11.1, 11.2_
    - **VERIFIED**: Backend tests passed, certificate upload working with base64 conversion, error handling implemented

- [~] 8. Checkpoint - Verify all feature integrations
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Add error handling and user feedback improvements
  - [~] 9.1 Implement user-friendly error messages
    - Review all error messages in `ImageService` and ensure they are user-friendly
    - Replace platform-specific error messages with generic messages
    - Add logging for platform-specific errors (for debugging)
    - Ensure no "Unsupported operation: _Namespace" errors are shown to users
    - _Requirements: 10.1, 10.2, 10.3, 10.5_

  - [~] 9.2 Add loading indicators for image operations
    - Ensure `ImageDisplayWidget` shows loading indicator during image load
    - Add loading indicators in screens during image selection
    - Add loading indicators during image upload
    - Ensure loading indicators are consistent across platforms
    - _Requirements: 12.3, 12.4_

  - [~] 9.3 Implement error recovery mechanisms
    - Add retry functionality for failed image uploads
    - Provide clear error messages with actionable guidance
    - Ensure users can recover from errors without losing data
    - _Requirements: 10.1, 10.2, 10.3_

- [ ] 10. Final integration and verification
  - [~] 10.1 Verify backward compatibility with backend APIs
    - Test that base64-encoded images match expected format
    - Verify existing API endpoints work without modification
    - Test request/response format for all image upload endpoints
    - Verify image URLs returned by backend display correctly
    - _Requirements: 11.1, 11.2, 11.3, 11.4_

  - [~] 10.2 Verify UI/UX consistency across platforms
    - Test image selection flow on web and desktop
    - Verify image display sizing and aspect ratios are consistent
    - Ensure loading indicators are consistent
    - Verify existing UI design and layout are maintained
    - _Requirements: 12.1, 12.2, 12.3, 12.4_

  - [~] 10.3 Final cross-platform testing
    - Test all image operations on web (Chrome)
    - Test all image operations on desktop (Windows)
    - Verify no platform-specific errors occur
    - Test with various image formats and sizes
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 4.1, 4.2, 6.6, 7.5, 8.5, 9.6, 10.5_

- [~] 11. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- All tasks involve writing, modifying, or testing code
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- The implementation uses Dart/Flutter as specified in the design document
- No property-based tests are included as the design explicitly states PBT is not applicable to this feature
- Testing will rely on unit tests, integration tests, and manual cross-platform testing
- Core infrastructure must be completed before feature integrations
- All existing features (AI Visual Assistant, Customer Profile, Provider Profile, Certificate Upload) must be updated to use the new platform-aware system
- Backward compatibility with existing backend APIs is maintained throughout

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3"] },
    { "id": 1, "tasks": ["3.1"] },
    { "id": 2, "tasks": ["3.2", "3.3", "3.4"] },
    { "id": 3, "tasks": ["3.5", "5.1", "6.1", "7.1"] },
    { "id": 4, "tasks": ["5.2", "6.2", "7.2"] },
    { "id": 5, "tasks": ["9.1", "9.2", "9.3"] },
    { "id": 6, "tasks": ["10.1", "10.2", "10.3"] }
  ]
}
```
