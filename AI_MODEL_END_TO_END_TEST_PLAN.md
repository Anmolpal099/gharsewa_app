# AI Model (Qwen 3.5 VL 2B) End-to-End Integration Test Plan

## Status: Ready for Testing

### Prerequisites ✅
- [x] Authentication system working
- [x] Database migrations run
- [x] Ollama container running
- [x] Qwen 3.5 VL 2B model loaded
- [x] AI consultation tables created
- [x] API routes registered

---

## Test Plan Overview

We'll test the AI model integration across three user roles:
1. **Customer** - AI Visual Assistant (image analysis, consultations)
2. **Provider** - View customer consultations, AI-powered matching
3. **Admin** - AI analytics, performance metrics, system monitoring

---

## Phase 1: Backend API Testing

### Test 1.1: Ollama Health Check ✅
```bash
# Test Ollama is accessible
curl http://localhost:11434/api/tags

# Expected: List of models including qwen3-vl:2b
```

**Status**: ✅ PASSED - Ollama accessible, model loaded

### Test 1.2: Laravel AI Health Endpoint
```bash
# Test AI health endpoint
curl -X GET http://localhost:8000/api/v1/admin/ai/health \
  -H "Authorization: Bearer {admin_token}"

# Expected: 200 OK with model status
```

### Test 1.3: AI Consultation Creation (Customer)
```bash
# Login as customer
POST http://localhost:8000/api/v1/auth/jwt/login
{
  "email": "test@test.com",
  "password": "Test1234"
}

# Create AI consultation
POST http://localhost:8000/api/v1/customer/ai/consultations
Authorization: Bearer {customer_token}
{
  "image": "base64_encoded_image",
  "markers": [
    {
      "x": 0.5,
      "y": 0.5,
      "description": "Water leak visible here"
    }
  ]
}

# Expected: 200 OK with AI diagnosis, service type, cost estimate, providers
```

### Test 1.4: Consultation History (Customer)
```bash
GET http://localhost:8000/api/v1/customer/ai/consultations
Authorization: Bearer {customer_token}

# Expected: Paginated list of consultations
```

### Test 1.5: AI Analytics (Admin)
```bash
GET http://localhost:8000/api/v1/admin/ai/analytics
Authorization: Bearer {admin_token}

# Expected: Analytics data (total consultations, avg confidence, etc.)
```

---

## Phase 2: Customer Features Testing

### Feature 2.1: AI Visual Assistant
**Steps**:
1. Login as customer
2. Navigate to AI Assistant
3. Capture/upload image
4. Place markers on defect areas
5. Add descriptions to markers
6. Submit for AI analysis
7. View AI diagnosis
8. See cost estimate
9. View recommended providers
10. Create booking from consultation

**Expected Results**:
- Image capture works (camera/gallery)
- Markers can be placed (up to 10)
- Descriptions can be added
- AI analysis completes in < 30 seconds
- Diagnosis is relevant and accurate
- Service type is identified correctly
- Cost estimate is reasonable (NPR range)
- Top 3 providers are recommended
- Booking can be created

### Feature 2.2: Consultation History
**Steps**:
1. View consultation history
2. Filter by service type
3. Search consultations
4. View consultation details
5. Delete consultation

**Expected Results**:
- History shows all past consultations
- Pagination works (20 per page)
- Filters work correctly
- Search finds relevant consultations
- Details show full diagnosis
- Delete removes consultation

---

## Phase 3: Provider Features Testing

### Feature 3.1: View Customer Consultations
**Steps**:
1. Login as provider
2. View bookings
3. Open booking with AI consultation
4. View customer's AI diagnosis
5. See marked defect areas
6. Understand customer needs

**Expected Results**:
- Provider can see consultations linked to bookings
- AI diagnosis is visible
- Markers are displayed
- Service type matches provider's expertise

### Feature 3.2: AI-Powered Matching
**Steps**:
1. Customer creates consultation
2. AI recommends providers
3. Provider receives match notification
4. Provider views match score

**Expected Results**:
- Providers are matched based on service type
- Match scores are calculated (rating + reviews)
- Top 3 providers are recommended
- Providers can see why they were matched

---

## Phase 4: Admin Features Testing

### Feature 4.1: AI Analytics Dashboard
**Steps**:
1. Login as admin
2. Navigate to AI Analytics
3. View total consultations
4. Check average confidence score
5. See service type distribution
6. View consultation trends
7. Check provider recommendation accuracy

**Expected Results**:
- Total consultations count is accurate
- Average confidence score is displayed
- Service type distribution chart shows data
- Trends show daily/weekly/monthly patterns
- Recommendation accuracy is tracked

### Feature 4.2: AI Performance Monitoring
**Steps**:
1. View AI health status
2. Check model availability
3. Monitor response times
4. Track error rates
5. View AI request logs

**Expected Results**:
- Health status shows green/red
- Model availability is confirmed
- Response times are < 30s
- Error rate is < 5%
- Request logs show all AI calls

---

## Phase 5: Integration Testing

### Test 5.1: End-to-End Customer Flow
1. Customer registers → ✅
2. Customer logs in → ✅
3. Customer uploads image → ?
4. Customer places markers → ?
5. AI analyzes image → ?
6. Customer views diagnosis → ?
7. Customer sees providers → ?
8. Customer creates booking → ?

### Test 5.2: End-to-End Provider Flow
1. Provider registers → ✅
2. Provider logs in → ✅
3. Provider receives booking → ?
4. Provider views consultation → ?
5. Provider sees AI diagnosis → ?
6. Provider completes service → ?

### Test 5.3: End-to-End Admin Flow
1. Admin logs in → ✅
2. Admin views analytics → ?
3. Admin monitors AI health → ?
4. Admin checks performance → ?
5. Admin reviews consultations → ?

---

## Phase 6: Error Handling Testing

### Test 6.1: Invalid Image
- Upload non-image file
- Upload corrupted image
- Upload oversized image (> 5MB)

**Expected**: Proper error messages

### Test 6.2: Invalid Markers
- Place > 10 markers
- Place markers outside image bounds
- Submit without markers

**Expected**: Validation errors

### Test 6.3: AI Service Failure
- Ollama container down
- Model not loaded
- Network timeout

**Expected**: Graceful error handling, retry logic

### Test 6.4: Authentication Errors
- Expired JWT token
- Invalid token
- Missing token
- Wrong role

**Expected**: 401 Unauthorized or 403 Forbidden

---

## Phase 7: Performance Testing

### Test 7.1: Response Time
- Measure AI analysis time
- Target: < 30 seconds
- Actual: ?

### Test 7.2: Concurrent Requests
- 10 simultaneous consultations
- Check rate limiting (10 req/min)
- Monitor server load

### Test 7.3: Large Images
- Test with 5MB images
- Test with high-resolution images
- Measure processing time

---

## Phase 8: Security Testing

### Test 8.1: Authentication
- ✅ JWT token required
- ✅ Role-based access control
- ✅ Token expiration

### Test 8.2: Authorization
- Customer can only see own consultations
- Provider can only see linked consultations
- Admin can see all consultations

### Test 8.3: Data Protection
- Images encrypted in transit
- Consultations are private
- 12-month retention policy

---

## Current Issues to Fix

### Issue 1: 500 Error on Consultation Creation ❌
**Error**: Internal Server Error when creating consultation
**Possible Causes**:
1. Controller method error
2. Service method error
3. Database constraint violation
4. Ollama API error
5. Image processing error

**Next Steps**:
1. Check Laravel logs for detailed error
2. Test controller method directly
3. Test VisionAIService separately
4. Test Ollama API directly
5. Add debug logging

### Issue 2: WebSocket Health Check Failing ⚠️
**Status**: Container running but health check failing
**Impact**: Real-time notifications may not work
**Priority**: Medium (not blocking AI features)

---

## Test Accounts

### Customer
- Email: test@test.com
- Password: Test1234
- Role: customer

### Provider
- Email: provider@test.com
- Password: Provider123
- Role: serviceProvider

### Admin
- Email: anmolpal156@gmail.com
- Password: Anmol123@
- Role: admin

---

## Next Steps

1. **Fix 500 Error** - Debug consultation creation endpoint
2. **Test AI Health Endpoint** - Verify AI service is accessible
3. **Test with Real Image** - Use actual defect image
4. **Test All Customer Features** - Complete end-to-end flow
5. **Test Provider Features** - Verify consultation viewing
6. **Test Admin Features** - Verify analytics and monitoring
7. **Performance Testing** - Measure response times
8. **Security Testing** - Verify authentication and authorization
9. **Documentation** - Update integration guide
10. **User Acceptance Testing** - Get feedback from real users

---

## Success Criteria

✅ **Backend**:
- [ ] AI consultation creation works
- [ ] Consultation history works
- [ ] AI analytics works
- [ ] Health checks pass
- [ ] Response time < 30s

✅ **Frontend**:
- [ ] Image capture works
- [ ] Marker placement works
- [ ] AI analysis displays correctly
- [ ] Provider recommendations show
- [ ] Consultation history loads

✅ **Integration**:
- [ ] End-to-end customer flow works
- [ ] End-to-end provider flow works
- [ ] End-to-end admin flow works
- [ ] All roles can authenticate
- [ ] All features are accessible

✅ **Performance**:
- [ ] Response time < 30s
- [ ] Rate limiting works
- [ ] Concurrent requests handled
- [ ] No memory leaks

✅ **Security**:
- [ ] Authentication required
- [ ] Authorization enforced
- [ ] Data protected
- [ ] Errors handled gracefully

---

**Date Created**: May 31, 2026  
**Status**: Ready for Testing  
**Priority**: HIGH  
**Assigned To**: Development Team

