#!/bin/bash

# Test Registration API Endpoint
# This script tests the JWT registration endpoint with various scenarios

API_URL="http://localhost:8000/api/v1/auth/jwt/register"

echo "=========================================="
echo "Testing Registration API Endpoint"
echo "=========================================="
echo ""

# Test 1: Successful Registration
echo "Test 1: Successful Registration (Customer)"
echo "------------------------------------------"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john.doe@example.com",
    "password": "Password123",
    "role": "customer"
  }' | jq '.'
echo ""
echo ""

# Test 2: Successful Registration (Service Provider)
echo "Test 2: Successful Registration (Service Provider)"
echo "------------------------------------------"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "Jane Smith",
    "email": "jane.smith@example.com",
    "password": "SecurePass456",
    "role": "serviceProvider"
  }' | jq '.'
echo ""
echo ""

# Test 3: Duplicate Email
echo "Test 3: Duplicate Email (Should Fail)"
echo "------------------------------------------"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "Another User",
    "email": "john.doe@example.com",
    "password": "Password123",
    "role": "customer"
  }' | jq '.'
echo ""
echo ""

# Test 4: Invalid Email Format
echo "Test 4: Invalid Email Format (Should Fail)"
echo "------------------------------------------"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "Test User",
    "email": "invalid-email",
    "password": "Password123",
    "role": "customer"
  }' | jq '.'
echo ""
echo ""

# Test 5: Weak Password
echo "Test 5: Weak Password (Should Fail)"
echo "------------------------------------------"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "weak",
    "role": "customer"
  }' | jq '.'
echo ""
echo ""

# Test 6: Password Without Uppercase
echo "Test 6: Password Without Uppercase (Should Fail)"
echo "------------------------------------------"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "Test User",
    "email": "test2@example.com",
    "password": "password123",
    "role": "customer"
  }' | jq '.'
echo ""
echo ""

# Test 7: Password Without Number
echo "Test 7: Password Without Number (Should Fail)"
echo "------------------------------------------"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "Test User",
    "email": "test3@example.com",
    "password": "PasswordOnly",
    "role": "customer"
  }' | jq '.'
echo ""
echo ""

# Test 8: Invalid Role
echo "Test 8: Invalid Role (Should Fail)"
echo "------------------------------------------"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "Test User",
    "email": "test4@example.com",
    "password": "Password123",
    "role": "invalid_role"
  }' | jq '.'
echo ""
echo ""

# Test 9: Missing Required Fields
echo "Test 9: Missing Required Fields (Should Fail)"
echo "------------------------------------------"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "Test User"
  }' | jq '.'
echo ""
echo ""

echo "=========================================="
echo "All Tests Completed"
echo "=========================================="
