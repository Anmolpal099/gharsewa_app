# AI Visual Assistant - User Guide

## Overview

The AI Visual Assistant is a powerful feature in Gharsewa that helps customers diagnose home service issues using AI-powered image analysis. Simply take a photo of the problem area, mark the defects, and receive instant recommendations including:

- **Problem Diagnosis**: What's wrong and why
- **Service Type**: Which service category you need
- **Cost Estimate**: Expected price range in NPR
- **Provider Recommendations**: Top 3 service providers for your issue

## Getting Started

### Prerequisites

- Gharsewa mobile app installed (Android/iOS)
- Active customer account
- Camera or photo gallery access
- Internet connection

### Accessing the Feature

1. Open the Gharsewa app
2. Log in to your customer account
3. Navigate to **AI Visual Assistant** from the main menu
4. You'll see two options:
   - **New Consultation**: Start a new diagnosis
   - **View History**: See past consultations

## Creating a New Consultation

### Step 1: Capture or Select Image

1. Tap **"New Consultation"**
2. Choose one of two options:
   - **Take Photo**: Opens your device camera
   - **Select from Gallery**: Browse your photo library

**Image Requirements:**
- Format: JPEG, PNG, or HEIC
- Size: 100 KB to 10 MB
- Resolution: Minimum 1280x720 pixels
- Quality: Clear, well-lit photos work best

**Tips for Best Results:**
- Use good lighting
- Get close to the problem area
- Keep the camera steady
- Avoid blurry images
- Include context around the defect

### Step 2: Mark Defects

After selecting an image, you'll enter the annotation editor:

1. **Tap on the image** where you see a problem
2. A red circular marker appears at that location
3. **Enter a description** in the popup dialog
   - Be specific (e.g., "Water leaking from pipe joint")
   - Use 2-500 characters
4. **Add more markers** if needed (up to 10 total)
5. **Edit markers** by tapping on existing ones
6. **Delete markers** by swiping left on the marker list

**Marker Tips:**
- Mark all visible defects
- Be specific in descriptions
- Use clear, simple language
- Mention colors, materials, or damage type
- Include any sounds or smells if relevant

### Step 3: Submit for Analysis

1. Review your markers and descriptions
2. Tap the **"Submit"** button in the app bar
3. Wait for AI analysis (typically 15-35 seconds)
4. A progress indicator shows the analysis is in progress

**During Analysis:**
- Keep the app open
- Stay connected to the internet
- Don't navigate away from the screen
- The AI is examining your image and markers

### Step 4: Review Results

Once analysis completes, you'll see:


#### 1. Diagnosis Card
- **What's Wrong**: Clear explanation of the problem
- **Severity**: How urgent the issue is
- **Recommendations**: What should be done

#### 2. Service Type
- **Category**: Which service you need (e.g., Plumbing Repair)
- **Icon**: Visual representation of the service

#### 3. Cost Estimate
- **Price Range**: Minimum to maximum cost in NPR
- **Currency**: All prices in Nepali Rupees
- **Note**: Estimates are approximate and may vary

#### 4. Recommended Providers
- **Top 3 Providers**: Best matches for your issue
- **Provider Details**:
  - Name and rating
  - Services offered
  - "Book Now" button

### Step 5: Book a Service (Optional)

1. Review the recommended providers
2. Tap **"Book Now"** on your preferred provider
3. The booking form opens with pre-filled information:
   - Service type
   - Provider selection
   - Your image and diagnosis attached
4. Complete the booking details
5. Submit your service request

## Viewing Consultation History

### Accessing History

1. From AI Assistant home, tap **"View History"**
2. See all your past consultations in chronological order
3. Each card shows:
   - Thumbnail image
   - Diagnosis summary
   - Service type
   - Date created

### Filtering and Searching

- **Filter by Service Type**: Tap the filter icon
- **Pull to Refresh**: Swipe down to reload
- **Scroll for More**: Automatic pagination loads older consultations

### Viewing Details

1. Tap any consultation card
2. See full details including:
   - Original image with markers
   - Complete diagnosis
   - All recommendations
   - Processing time

### Re-analyzing Images

1. Open a past consultation
2. Tap **"Re-analyze"** button
3. The same image opens in the annotation editor
4. Add new markers or modify descriptions
5. Submit for a fresh analysis

### Deleting Consultations

1. Open a consultation detail view
2. Tap the **"Delete"** button
3. Confirm deletion in the dialog
4. The consultation is removed from your history

**Note**: Deleted consultations cannot be recovered.

## Understanding AI Responses

### Diagnosis Quality

The AI provides diagnoses based on:
- Visual analysis of the image
- Your marker descriptions
- Pattern recognition from training data
- Service type categorization

**Confidence Levels:**
- High confidence: Clear, specific diagnosis
- Medium confidence: General diagnosis with caveats
- Low confidence: Uncertain, default recommendations

### Cost Estimates

Cost estimates are based on:
- Problem severity
- Service type
- Typical market rates in Nepal
- Complexity of the issue

**Important Notes:**
- Estimates are approximate
- Actual costs may vary
- Final price determined by provider
- Get quotes from multiple providers

### Provider Recommendations

Providers are ranked by:
- Service type match
- Customer ratings
- Availability
- Past performance

**Recommendation Tips:**
- Check provider ratings
- Read reviews
- Compare multiple providers
- Verify availability before booking


## Troubleshooting

### Camera Not Working

**Problem**: Camera doesn't open when tapping "Take Photo"

**Solutions**:
1. Check camera permissions in device settings
2. Grant Gharsewa access to camera
3. Restart the app
4. Try "Select from Gallery" instead

**Steps to Grant Permission**:
- **Android**: Settings → Apps → Gharsewa → Permissions → Camera → Allow
- **iOS**: Settings → Gharsewa → Camera → Enable

### Gallery Not Accessible

**Problem**: Can't select images from gallery

**Solutions**:
1. Check photo library permissions
2. Grant Gharsewa access to photos
3. Restart the app
4. Try "Take Photo" instead

### Image Validation Errors

**Problem**: "Image must be between 100KB and 10MB"

**Solutions**:
- Image too small: Use higher quality camera settings
- Image too large: Compress the image or use a different photo
- Try taking a new photo with the app camera

**Problem**: "Unsupported image format"

**Solutions**:
- Use JPEG, PNG, or HEIC formats only
- Convert the image using a photo editor
- Take a new photo with the app camera

### Analysis Taking Too Long

**Problem**: Analysis stuck on "Analyzing your image..."

**Solutions**:
1. Check your internet connection
2. Wait up to 30 seconds (normal processing time)
3. If timeout occurs, tap "Retry"
4. Try with a smaller image
5. Check if Ollama service is running (admin)

### AI Service Unavailable

**Problem**: "AI service temporarily unavailable"

**Solutions**:
1. Check internet connection
2. Wait a few minutes and try again
3. Contact support if problem persists
4. Check app status page

### No Providers Found

**Problem**: "No providers available for this service type"

**Solutions**:
1. Try a different service type filter
2. Check back later (providers may be added)
3. Contact support to request providers
4. Use general search to find providers manually

### Markers Not Appearing

**Problem**: Tapping on image doesn't add markers

**Solutions**:
1. Ensure you're tapping within the image area
2. Check if you've reached the 10 marker limit
3. Try tapping a different area
4. Restart the annotation editor

### Can't Delete Marker

**Problem**: Unable to remove a marker

**Solutions**:
1. Tap the marker in the list below the image
2. Tap "Delete" in the marker detail view
3. Or swipe left on the marker in the list
4. Restart the editor if issue persists

## Best Practices

### Taking Quality Photos

1. **Lighting**: Use natural light or bright indoor lighting
2. **Focus**: Ensure the problem area is in focus
3. **Distance**: Get close enough to see details
4. **Angle**: Shoot straight-on, not at extreme angles
5. **Context**: Include surrounding area for reference
6. **Stability**: Hold camera steady or use a surface

### Writing Good Descriptions

1. **Be Specific**: "Crack in wall, 2 inches long" vs "wall damage"
2. **Include Details**: Colors, materials, size, location
3. **Mention Symptoms**: Leaking, noise, smell, temperature
4. **Use Simple Language**: Clear and concise
5. **Avoid Jargon**: Unless you're certain of technical terms

### Getting Accurate Estimates

1. **Mark All Defects**: Don't miss visible problems
2. **Describe Thoroughly**: More detail = better estimate
3. **Multiple Angles**: Consider taking several photos
4. **Compare Providers**: Get quotes from 2-3 providers
5. **Ask Questions**: Clarify with providers before booking

### Managing Your History

1. **Regular Review**: Check past consultations periodically
2. **Track Recurring Issues**: Notice patterns in your home
3. **Delete Old Ones**: Remove consultations you no longer need
4. **Re-analyze**: Use old images if problem returns
5. **Reference for Providers**: Show history to service providers

## Privacy and Security

### Data Protection

- All images encrypted during transmission (HTTPS)
- Images stored securely on servers
- Only you can access your consultations
- No sharing with third parties without consent

### Data Retention

- Consultations stored for 12 months
- Automatic deletion after retention period
- Manual deletion available anytime
- Deleted data cannot be recovered

### Permissions

The app requires:
- **Camera**: To capture photos of issues
- **Photo Library**: To select existing images
- **Internet**: To send images for AI analysis
- **Storage**: To cache images locally

All permissions are optional but required for full functionality.

## Frequently Asked Questions

### How accurate is the AI diagnosis?

The AI provides educated estimates based on visual analysis. For critical issues, always consult a professional service provider for confirmation.

### Can I use the same image multiple times?

Yes! You can re-analyze any image from your history with different markers or descriptions.

### How long are consultations stored?

Consultations are stored for 12 months, then automatically deleted. You can manually delete them anytime.

### Can I edit a consultation after submission?

No, but you can re-analyze the same image with new markers to create a new consultation.

### What if the AI diagnosis is wrong?

The AI provides recommendations, not guarantees. Always verify with a professional provider. You can also try re-analyzing with more detailed markers.

### How many consultations can I create?

There's a rate limit of 10 consultations per minute to prevent abuse. No overall limit on total consultations.

### Can I share consultations with others?

Currently, consultations are private to your account. You can show your phone screen to providers or support staff.

### What happens if I lose internet during analysis?

The analysis will fail with a timeout error. You'll need to resubmit when connection is restored.

### Are there any costs for using AI Visual Assistant?

The AI analysis feature is included with your Gharsewa account. You only pay for services you book with providers.

## Support

### Getting Help

- **In-App Support**: Tap the help icon in the app
- **Email**: support@gharsewa.com
- **Phone**: [Support phone number]
- **Hours**: [Support hours]

### Reporting Issues

When reporting problems, include:
1. What you were trying to do
2. What happened instead
3. Error messages (screenshot if possible)
4. Device type and OS version
5. App version

### Feature Requests

We welcome feedback! Submit feature requests through:
- In-app feedback form
- Email to feedback@gharsewa.com
- User community forum

---

**Version**: 1.0  
**Last Updated**: January 2024  
**For**: Gharsewa Mobile App - AI Visual Assistant Feature
