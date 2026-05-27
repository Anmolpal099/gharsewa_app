# Requirements Document

## Introduction

The AI Visual Assistant feature enables Gharsewa customers to diagnose home service issues using AI-powered image analysis. Customers can capture or select images of problematic areas, mark defects with visual annotations, add descriptions, and receive intelligent recommendations including problem diagnosis, service type suggestions, cost estimates, and provider recommendations. The system integrates with the existing Ollama service running the Qwen 3.5 Vision model (qwen3-vl:2b) and maintains a consultation history for future reference.

## Glossary

- **AI_Visual_Assistant**: The system component that orchestrates image capture, annotation, AI analysis, and recommendation generation
- **Image_Capture_Module**: The component responsible for capturing photos via camera or selecting from device gallery
- **Annotation_Editor**: The component that allows users to mark defective areas and add text descriptions
- **Vision_AI_Service**: The Ollama service running the Qwen 3.5 Vision model (qwen3-vl:2b) for image analysis
- **Consultation**: A complete interaction including image, annotations, descriptions, AI analysis, and recommendations
- **Consultation_History**: The stored record of all past consultations for a customer
- **Defect_Marker**: A visual indicator (red circle/marker) placed on an image to highlight a problematic area
- **AI_Response**: The structured output from the Vision AI Service containing diagnosis, service type, cost estimate, and provider recommendations
- **Service_Provider**: A registered provider in the Gharsewa system offering specific home services
- **NPR**: Nepali Rupees, the currency used for cost estimates

## Requirements

### Requirement 1: Image Acquisition

**User Story:** As a customer, I want to capture or select images of home service issues, so that I can get AI-powered diagnosis and recommendations.

#### Acceptance Criteria

1. WHEN a customer selects "Take Photo", THE Image_Capture_Module SHALL activate the device camera and capture a high-quality image
2. WHEN a customer selects "Select from Gallery", THE Image_Capture_Module SHALL open the device gallery and allow image selection
3. THE Image_Capture_Module SHALL support image formats JPEG, PNG, and HEIC
4. WHEN an image is captured or selected, THE Image_Capture_Module SHALL validate that the image size is between 100KB and 10MB
5. IF an image fails validation, THEN THE Image_Capture_Module SHALL display an error message indicating the specific validation failure

### Requirement 2: Visual Annotation

**User Story:** As a customer, I want to mark defective areas on images and add descriptions, so that the AI can understand exactly what problems I'm experiencing.

#### Acceptance Criteria

1. WHEN an image is loaded, THE Annotation_Editor SHALL display the image with annotation tools
2. WHEN a customer taps on the image, THE Annotation_Editor SHALL place a red circular marker at the tap location
3. THE Annotation_Editor SHALL allow placement of up to 10 defect markers on a single image
4. WHEN a marker is placed, THE Annotation_Editor SHALL prompt the customer to add a text description for that marker
5. THE Annotation_Editor SHALL allow text descriptions up to 500 characters per marker
6. WHEN a customer taps an existing marker, THE Annotation_Editor SHALL allow editing or deletion of that marker and its description
7. THE Annotation_Editor SHALL display all markers with their associated descriptions in a list view
8. WHEN a customer removes a marker, THE Annotation_Editor SHALL remove both the visual marker and its associated text description

### Requirement 3: AI Image Analysis

**User Story:** As a customer, I want the AI to analyze my annotated images, so that I can receive accurate diagnosis and service recommendations.

#### Acceptance Criteria

1. WHEN a customer submits an annotated image, THE AI_Visual_Assistant SHALL send the image, marker coordinates, and descriptions to the Vision_AI_Service
2. THE AI_Visual_Assistant SHALL format the request to include marker positions as coordinate pairs and associated text descriptions
3. WHEN the Vision_AI_Service receives a request, THE Vision_AI_Service SHALL analyze the image using the qwen3-vl:2b model
4. THE Vision_AI_Service SHALL process the analysis within 30 seconds for images up to 5MB
5. IF the Vision_AI_Service fails to respond within 30 seconds, THEN THE AI_Visual_Assistant SHALL display a timeout error message
6. WHEN analysis completes, THE Vision_AI_Service SHALL return an AI_Response containing diagnosis, service type, cost estimate, and provider recommendations
7. IF the Vision_AI_Service returns an error, THEN THE AI_Visual_Assistant SHALL log the error and display a user-friendly error message

### Requirement 4: Diagnosis and Recommendations

**User Story:** As a customer, I want to receive comprehensive diagnosis and recommendations, so that I can understand the problem and take appropriate action.

#### Acceptance Criteria

1. THE AI_Response SHALL include a problem diagnosis describing what is wrong in 50 to 500 characters
2. THE AI_Response SHALL include a recommended service type matching one of the existing service categories in the Gharsewa system
3. THE AI_Response SHALL include a cost estimate with minimum and maximum values in NPR
4. THE AI_Response SHALL include a list of 3 suggested Service_Providers ranked by relevance to the diagnosed problem
5. WHEN the AI_Visual_Assistant receives an AI_Response, THE AI_Visual_Assistant SHALL display the diagnosis prominently at the top of the results screen
6. THE AI_Visual_Assistant SHALL display the recommended service type with an icon representing that service category
7. THE AI_Visual_Assistant SHALL display the cost estimate as a range in the format "NPR [min] - [max]"
8. THE AI_Visual_Assistant SHALL display each suggested Service_Provider with name, rating, and a "Book Now" action button

### Requirement 5: Service Provider Matching

**User Story:** As a customer, I want to see relevant service providers based on the AI diagnosis, so that I can quickly book the appropriate service.

#### Acceptance Criteria

1. WHEN the Vision_AI_Service determines a service type, THE AI_Visual_Assistant SHALL query the database for Service_Providers offering that service type
2. THE AI_Visual_Assistant SHALL rank Service_Providers by rating in descending order
3. THE AI_Visual_Assistant SHALL filter Service_Providers to include only those with active status
4. THE AI_Visual_Assistant SHALL return the top 3 Service_Providers matching the criteria
5. IF fewer than 3 Service_Providers match the criteria, THEN THE AI_Visual_Assistant SHALL return all available matching providers
6. IF no Service_Providers match the criteria, THEN THE AI_Visual_Assistant SHALL display a message indicating no providers are currently available for the service type

### Requirement 6: Booking Integration

**User Story:** As a customer, I want to book a service directly from the AI recommendations, so that I can quickly resolve my home service issue.

#### Acceptance Criteria

1. WHEN a customer taps "Book Now" on a recommended Service_Provider, THE AI_Visual_Assistant SHALL navigate to the booking screen
2. THE AI_Visual_Assistant SHALL pre-populate the booking form with the service type from the AI_Response
3. THE AI_Visual_Assistant SHALL pre-populate the booking form with the selected Service_Provider
4. THE AI_Visual_Assistant SHALL attach the original image and annotations to the booking request
5. THE AI_Visual_Assistant SHALL include the AI diagnosis in the booking notes field

### Requirement 7: Consultation History

**User Story:** As a customer, I want to view my past AI consultations, so that I can reference previous diagnoses and track recurring issues.

#### Acceptance Criteria

1. WHEN a Consultation is completed, THE AI_Visual_Assistant SHALL save the Consultation to the Consultation_History
2. THE Consultation_History SHALL store the original image, all markers with coordinates, text descriptions, AI_Response, and timestamp
3. WHEN a customer navigates to the history view, THE AI_Visual_Assistant SHALL display all past Consultations in reverse chronological order
4. THE AI_Visual_Assistant SHALL display each Consultation with a thumbnail image, diagnosis summary, and date
5. WHEN a customer taps a past Consultation, THE AI_Visual_Assistant SHALL display the complete Consultation details including image, annotations, and AI_Response
6. WHEN viewing a past Consultation, THE AI_Visual_Assistant SHALL allow the customer to re-submit the same image for a new analysis
7. THE Consultation_History SHALL retain Consultations for a minimum of 12 months

### Requirement 8: Ollama Service Integration

**User Story:** As the system, I want to communicate with the Ollama service reliably, so that AI analysis requests are processed correctly.

#### Acceptance Criteria

1. THE Vision_AI_Service SHALL connect to the Ollama service at http://gharsewa_ollama:11434
2. THE Vision_AI_Service SHALL use the qwen3-vl:2b model for all image analysis requests
3. WHEN sending a request, THE Vision_AI_Service SHALL encode the image in base64 format
4. THE Vision_AI_Service SHALL include a structured prompt containing marker coordinates and descriptions
5. WHEN the Ollama service is unavailable, THE Vision_AI_Service SHALL retry the request up to 3 times with exponential backoff
6. IF all retry attempts fail, THEN THE Vision_AI_Service SHALL return an error indicating the service is unavailable
7. THE Vision_AI_Service SHALL log all requests and responses for debugging and analytics purposes

### Requirement 9: Data Persistence

**User Story:** As the system, I want to store consultation data reliably, so that customers can access their history and the system can generate analytics.

#### Acceptance Criteria

1. THE AI_Visual_Assistant SHALL store Consultation records in the MySQL database
2. THE Consultation record SHALL include customer_id, image_path, markers_json, descriptions_json, ai_response_json, service_type, cost_min, cost_max, and created_at timestamp
3. WHEN storing an image, THE AI_Visual_Assistant SHALL save the image file to the server storage and store the file path in the database
4. THE AI_Visual_Assistant SHALL ensure image files are stored with unique filenames to prevent collisions
5. THE AI_Visual_Assistant SHALL associate each Consultation with the authenticated customer's user ID
6. WHEN retrieving Consultation_History, THE AI_Visual_Assistant SHALL only return Consultations belonging to the authenticated customer

### Requirement 10: User Interface Navigation

**User Story:** As a customer, I want to easily navigate the AI Visual Assistant feature, so that I can quickly diagnose issues without confusion.

#### Acceptance Criteria

1. WHEN a customer navigates to the AI Assistant section, THE AI_Visual_Assistant SHALL display options for "New Consultation" and "View History"
2. WHEN a customer selects "New Consultation", THE AI_Visual_Assistant SHALL display options for "Take Photo" and "Select from Gallery"
3. THE AI_Visual_Assistant SHALL display a progress indicator while the Vision_AI_Service processes the image
4. WHEN analysis is complete, THE AI_Visual_Assistant SHALL display the results screen with diagnosis and recommendations
5. THE AI_Visual_Assistant SHALL provide a "Back" navigation option at each step to return to the previous screen
6. THE AI_Visual_Assistant SHALL provide a "Start New Consultation" option from the results screen

### Requirement 11: Error Handling and User Feedback

**User Story:** As a customer, I want clear feedback when errors occur, so that I understand what went wrong and how to proceed.

#### Acceptance Criteria

1. WHEN an error occurs during image capture, THE Image_Capture_Module SHALL display an error message describing the camera or gallery access issue
2. WHEN an image fails validation, THE AI_Visual_Assistant SHALL display the specific validation error and requirements
3. WHEN the Vision_AI_Service is unavailable, THE AI_Visual_Assistant SHALL display a message indicating the service is temporarily unavailable and suggest trying again later
4. WHEN network connectivity is lost, THE AI_Visual_Assistant SHALL display a message indicating no internet connection
5. WHEN an unexpected error occurs, THE AI_Visual_Assistant SHALL display a generic error message and log the detailed error for debugging
6. THE AI_Visual_Assistant SHALL provide a "Retry" option for recoverable errors
7. THE AI_Visual_Assistant SHALL provide a "Contact Support" option for unrecoverable errors

### Requirement 12: Performance and Responsiveness

**User Story:** As a customer, I want the AI Visual Assistant to respond quickly, so that I can get diagnoses without long waits.

#### Acceptance Criteria

1. THE Image_Capture_Module SHALL display the camera preview within 2 seconds of selection
2. THE Annotation_Editor SHALL render markers and respond to touch input within 100 milliseconds
3. THE AI_Visual_Assistant SHALL display the progress indicator within 500 milliseconds of submission
4. THE Vision_AI_Service SHALL complete image analysis within 30 seconds for images up to 5MB
5. THE AI_Visual_Assistant SHALL display the results screen within 1 second of receiving the AI_Response
6. THE Consultation_History SHALL load and display the list of past consultations within 2 seconds

### Requirement 13: Image Quality and Format Handling

**User Story:** As a customer, I want to submit high-quality images in various formats, so that the AI can accurately analyze the issues.

#### Acceptance Criteria

1. THE Image_Capture_Module SHALL capture images at a minimum resolution of 1280x720 pixels
2. THE Image_Capture_Module SHALL support JPEG, PNG, and HEIC image formats
3. WHEN an image is selected or captured, THE AI_Visual_Assistant SHALL validate the image format
4. IF an unsupported format is detected, THEN THE AI_Visual_Assistant SHALL display an error message listing supported formats
5. THE AI_Visual_Assistant SHALL compress images larger than 5MB to 5MB or less while maintaining aspect ratio and readability
6. THE AI_Visual_Assistant SHALL preserve the original image quality for images 5MB or smaller

### Requirement 14: Security and Privacy

**User Story:** As a customer, I want my consultation images and data to be secure, so that my privacy is protected.

#### Acceptance Criteria

1. THE AI_Visual_Assistant SHALL require customer authentication before allowing access to any features
2. THE AI_Visual_Assistant SHALL transmit all images and data over HTTPS connections
3. THE AI_Visual_Assistant SHALL ensure that customers can only access their own Consultation_History
4. THE AI_Visual_Assistant SHALL not share customer images or consultation data with third parties
5. WHEN storing images, THE AI_Visual_Assistant SHALL store them in a secure directory with restricted access permissions
6. THE AI_Visual_Assistant SHALL include the customer's authentication token in all API requests to the backend

### Requirement 15: Cost Estimation Accuracy

**User Story:** As a customer, I want realistic cost estimates, so that I can budget appropriately for the service.

#### Acceptance Criteria

1. THE Vision_AI_Service SHALL generate cost estimates based on the diagnosed problem severity and service type
2. THE cost estimate minimum value SHALL be at least NPR 500
3. THE cost estimate maximum value SHALL not exceed NPR 50000
4. THE cost estimate range SHALL have a maximum value that is at least 1.5 times the minimum value
5. WHEN the Vision_AI_Service cannot determine a reliable cost estimate, THE AI_Response SHALL include a default range of NPR 1000 - NPR 5000 with a note indicating the estimate is approximate
