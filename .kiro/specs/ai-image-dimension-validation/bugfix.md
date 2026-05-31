# Bugfix Requirements Document

## Introduction

The AI consultation creation endpoint (`POST /api/v1/customer/ai/consultations`) currently fails with a 500 Internal Server Error when processing images smaller than 32x32 pixels. This occurs because the qwen3vl model used by Ollama has a `factor:32` constraint in its image processor, requiring images to be at least 32x32 pixels. The current `Base64Image` validation rule only validates file size, format, and MIME type, but does not check image dimensions. This allows small images to pass validation and reach the Ollama service, causing it to crash with a cryptic error message.

This bugfix ensures that images smaller than 32x32 pixels are rejected during validation with a clear, user-friendly error message (422 Unprocessable Entity) instead of causing a server crash (500 Internal Server Error).

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN an image with dimensions smaller than 32x32 pixels (e.g., 1x1, 16x16, 31x32) is submitted to the AI consultation endpoint THEN the system accepts the image through validation and passes it to the VisionAIService

1.2 WHEN the VisionAIService sends a small image (< 32x32 pixels) to the Ollama qwen3vl model THEN Ollama crashes with the error "height:1 or width:1 must be larger than factor:32"

1.3 WHEN Ollama crashes due to small image dimensions THEN the API returns a 500 Internal Server Error with the message "model runner has unexpectedly stopped, this may be due to resource limitations or an internal error"

1.4 WHEN users receive a 500 error for small images THEN they do not understand that the issue is related to image dimensions and cannot take corrective action

### Expected Behavior (Correct)

2.1 WHEN an image with width less than 32 pixels OR height less than 32 pixels is submitted to the AI consultation endpoint THEN the system SHALL reject the image during validation with a 422 Unprocessable Entity response

2.2 WHEN an image is rejected due to insufficient dimensions THEN the system SHALL return a clear error message: "The image must be at least 32x32 pixels. Your image is {width}x{height} pixels."

2.3 WHEN an image with dimensions of exactly 32x32 pixels or larger is submitted THEN the system SHALL accept the image and proceed with AI analysis

2.4 WHEN dimension validation is added THEN the system SHALL check dimensions after validating base64 format, file size, and MIME type but before accepting the image

### Unchanged Behavior (Regression Prevention)

3.1 WHEN an image with valid dimensions (>= 32x32 pixels) and valid format (JPEG, PNG, HEIC) is submitted THEN the system SHALL CONTINUE TO process the image successfully and return AI consultation results

3.2 WHEN an image exceeds the maximum file size (10MB) THEN the system SHALL CONTINUE TO reject it with the existing file size validation error

3.3 WHEN an image has an invalid format (not JPEG, PNG, or HEIC) THEN the system SHALL CONTINUE TO reject it with the existing format validation error

3.4 WHEN an image has invalid base64 encoding THEN the system SHALL CONTINUE TO reject it with the existing base64 validation error

3.5 WHEN validation fails for any reason THEN the system SHALL CONTINUE TO return a 422 Unprocessable Entity response (not 500)
