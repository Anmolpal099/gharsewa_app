// Generate Postman Collection for Phase 1 Backend APIs
const fs = require('fs');

// Helper to create a request
function createRequest(name, method, path, body = null, authType = 'bearer', tests = [], description = '') {
  const request = {
    name,
    request: {
      method,
      header: [{ key: 'Content-Type', value: 'application/json' }],
      url: {
        raw: `{{base_url}}${path}`,
        host: ['{{base_url}}'],
        path: path.split('/').filter(p => p)
      }
    },
    response: []
  };

  if (description) {
    request.request.description = description;
  }

  if (authType === 'noauth') {
    request.request.auth = { type: 'noauth' };
  }

  if (body) {
    request.request.body = {
      mode: 'raw',
      raw: JSON.stringify(body, null, 2)
    };
  }

  if (tests.length > 0) {
    request.event = [{
      listen: 'test',
      script: { exec: tests }
    }];
  }

  return request;
}

// Collection structure
const collection = {
  info: {
    name: 'Phase 1 Backend APIs - Gharsewa',
    description: 'Complete API collection for Gharsewa Phase 1 Backend APIs including Authentication, Services, Bookings, Profile, and Dashboard endpoints',
    schema: 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json'
  },
  auth: {
    type: 'bearer',
    bearer: [{ key: 'token', value: '{{access_token}}', type: 'string' }]
  },
  variable: [
    { key: 'base_url', value: 'http://localhost:8000/api/v1', type: 'string' },
    { key: 'access_token', value: '', type: 'string' },
    { key: 'provider_token', value: '', type: 'string' },
    { key: 'customer_token', value: '', type: 'string' },
    { key: 'service_id', value: '', type: 'string' },
    { key: 'booking_id', value: '', type: 'string' }
  ],
  item: []
};


// 1. Authentication folder
const authFolder = {
  name: '1. Authentication',
  item: [
    createRequest(
      'Register (Customer)',
      'POST',
      '/auth/jwt/register',
      {
        name: 'Test Customer',
        email: 'customer@test.com',
        password: 'Test1234',
        password_confirmation: 'Test1234',
        role: 'customer'
      },
      'noauth',
      [
        'pm.test("Status code is 201", () => pm.response.to.have.status(201));',
        'pm.test("Response has token", () => {',
        '    const response = pm.response.json();',
        '    pm.expect(response.data).to.have.property("access_token");',
        '});',
        'if (pm.response.code === 201) {',
        '    const response = pm.response.json();',
        '    pm.environment.set("customer_token", response.data.access_token);',
        '    pm.environment.set("access_token", response.data.access_token);',
        '}'
      ],
      'Register a new customer account'
    ),
    createRequest(
      'Register (Provider)',
      'POST',
      '/auth/jwt/register',
      {
        name: 'Test Provider',
        email: 'provider@test.com',
        password: 'Test1234',
        password_confirmation: 'Test1234',
        role: 'serviceProvider'
      },
      'noauth',
      [
        'pm.test("Status code is 201", () => pm.response.to.have.status(201));',
        'if (pm.response.code === 201) {',
        '    const response = pm.response.json();',
        '    pm.environment.set("provider_token", response.data.access_token);',
        '}'
      ],
      'Register a new service provider account'
    ),
    createRequest(
      'Login (Customer)',
      'POST',
      '/auth/jwt/login',
      {
        email: 'customer@test.com',
        password: 'Test1234'
      },
      'noauth',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'if (pm.response.code === 200) {',
        '    const response = pm.response.json();',
        '    pm.environment.set("customer_token", response.data.access_token);',
        '    pm.environment.set("access_token", response.data.access_token);',
        '}'
      ],
      'Login as customer'
    ),
    createRequest(
      'Login (Provider)',
      'POST',
      '/auth/jwt/login',
      {
        email: 'provider@test.com',
        password: 'Test1234'
      },
      'noauth',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'if (pm.response.code === 200) {',
        '    const response = pm.response.json();',
        '    pm.environment.set("provider_token", response.data.access_token);',
        '    pm.environment.set("access_token", response.data.access_token);',
        '}'
      ],
      'Login as service provider'
    ),
    createRequest(
      'Get Current User',
      'GET',
      '/auth/jwt/me',
      null,
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Response has user data", () => {',
        '    const response = pm.response.json();',
        '    pm.expect(response.data).to.have.property("id");',
        '    pm.expect(response.data).to.have.property("email");',
        '    pm.expect(response.data).to.have.property("role");',
        '});'
      ],
      'Get current authenticated user information'
    ),
    createRequest(
      'Refresh Token',
      'POST',
      '/auth/jwt/refresh',
      null,
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'if (pm.response.code === 200) {',
        '    const response = pm.response.json();',
        '    pm.environment.set("access_token", response.data.access_token);',
        '}'
      ],
      'Refresh JWT access token'
    ),
    createRequest(
      'Logout',
      'POST',
      '/auth/jwt/logout',
      null,
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));'
      ],
      'Logout current user'
    )
  ]
};


// 2. Services - Public folder
const servicesPublicFolder = {
  name: '2. Services - Public',
  item: [
    createRequest(
      'Browse Services',
      'GET',
      '/services?page=1&per_page=15',
      null,
      'noauth',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Response has data array", () => {',
        '    const response = pm.response.json();',
        '    pm.expect(response.data).to.be.an("array");',
        '});',
        'pm.test("Response has pagination meta", () => {',
        '    const response = pm.response.json();',
        '    pm.expect(response.meta).to.have.property("current_page");',
        '    pm.expect(response.meta).to.have.property("total");',
        '});'
      ],
      'Browse all active services (no authentication required)'
    ),
    createRequest(
      'Get Service Details',
      'GET',
      '/services/{{service_id}}',
      null,
      'noauth',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Service has required fields", () => {',
        '    const service = pm.response.json().data;',
        '    pm.expect(service).to.have.property("id");',
        '    pm.expect(service).to.have.property("name");',
        '    pm.expect(service).to.have.property("price");',
        '    pm.expect(service).to.have.property("provider");',
        '});'
      ],
      'Get detailed information about a specific service'
    ),
    createRequest(
      'Search Services',
      'GET',
      '/services/search?q=cleaning',
      null,
      'noauth',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Response has data array", () => {',
        '    const response = pm.response.json();',
        '    pm.expect(response.data).to.be.an("array");',
        '});'
      ],
      'Search services by name, description, or tags'
    ),
    createRequest(
      'Get Categories',
      'GET',
      '/services/categories',
      null,
      'noauth',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Response has categories", () => {',
        '    const response = pm.response.json();',
        '    pm.expect(response.data).to.be.an("array");',
        '});'
      ],
      'Get list of all service categories with counts'
    )
  ]
};


// 3. Services - Provider folder
const servicesProviderFolder = {
  name: '3. Services - Provider',
  item: [
    createRequest(
      'List My Services',
      'GET',
      '/provider/services',
      null,
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Response has data array", () => {',
        '    const response = pm.response.json();',
        '    pm.expect(response.data).to.be.an("array");',
        '});'
      ],
      'List all services owned by the authenticated provider'
    ),
    createRequest(
      'Create Service',
      'POST',
      '/provider/services',
      {
        name: 'House Cleaning Service',
        description: 'Professional house cleaning service with experienced staff',
        category: 'Cleaning',
        price: 1500,
        duration_minutes: 120,
        currency: 'NPR'
      },
      'bearer',
      [
        'pm.test("Status code is 201", () => pm.response.to.have.status(201));',
        'pm.test("Service created successfully", () => {',
        '    const response = pm.response.json();',
        '    pm.expect(response.data).to.have.property("id");',
        '    pm.expect(response.data.name).to.equal("House Cleaning Service");',
        '});',
        'if (pm.response.code === 201) {',
        '    const response = pm.response.json();',
        '    pm.environment.set("service_id", response.data.id);',
        '}'
      ],
      'Create a new service offering'
    ),
    createRequest(
      'Get Service Details',
      'GET',
      '/provider/services/{{service_id}}',
      null,
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Service has bookings count", () => {',
        '    const service = pm.response.json().data;',
        '    pm.expect(service).to.have.property("bookings_count");',
        '});'
      ],
      'Get detailed information about a specific service including bookings count'
    ),
    createRequest(
      'Update Service',
      'PUT',
      '/provider/services/{{service_id}}',
      {
        name: 'Premium House Cleaning Service',
        description: 'Premium house cleaning service with experienced staff and eco-friendly products',
        category: 'Cleaning',
        price: 2000,
        duration_minutes: 150,
        currency: 'NPR'
      },
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Service updated successfully", () => {',
        '    const response = pm.response.json();',
        '    pm.expect(response.data.price).to.equal(2000);',
        '});'
      ],
      'Update service information'
    ),
    createRequest(
      'Update Service Status',
      'PATCH',
      '/provider/services/{{service_id}}/status',
      {
        status: 'inactive'
      },
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Status updated", () => {',
        '    const response = pm.response.json();',
        '    pm.expect(response.data.status).to.equal("inactive");',
        '});'
      ],
      'Activate or deactivate a service'
    ),
    createRequest(
      'Delete Service',
      'DELETE',
      '/provider/services/{{service_id}}',
      null,
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));'
      ],
      'Delete a service (only if no active bookings exist)'
    )
  ]
};


// 4. Bookings - Customer folder
const bookingsCustomerFolder = {
  name: '4. Bookings - Customer',
  item: [
    createRequest(
      'List My Bookings',
      'GET',
      '/customer/bookings',
      null,
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Response has data array", () => {',
        '    const response = pm.response.json();',
        '    pm.expect(response.data).to.be.an("array");',
        '});'
      ],
      'List all bookings for the authenticated customer'
    ),
    createRequest(
      'Create Booking',
      'POST',
      '/customer/bookings',
      {
        service_id: '{{service_id}}',
        scheduled_at: '2026-06-01 10:00:00',
        notes: 'Please bring cleaning supplies'
      },
      'bearer',
      [
        'pm.test("Status code is 201", () => pm.response.to.have.status(201));',
        'pm.test("Booking created successfully", () => {',
        '    const response = pm.response.json();',
        '    pm.expect(response.data).to.have.property("id");',
        '    pm.expect(response.data.status).to.equal("pending");',
        '});',
        'if (pm.response.code === 201) {',
        '    const response = pm.response.json();',
        '    pm.environment.set("booking_id", response.data.id);',
        '}'
      ],
      'Create a new booking for a service'
    ),
    createRequest(
      'Get Booking Details',
      'GET',
      '/customer/bookings/{{booking_id}}',
      null,
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Booking has required fields", () => {',
        '    const booking = pm.response.json().data;',
        '    pm.expect(booking).to.have.property("id");',
        '    pm.expect(booking).to.have.property("status");',
        '    pm.expect(booking).to.have.property("service");',
        '    pm.expect(booking).to.have.property("provider");',
        '});'
      ],
      'Get detailed information about a specific booking'
    ),
    createRequest(
      'Cancel Booking',
      'POST',
      '/customer/bookings/{{booking_id}}/cancel',
      {
        cancellation_reason: 'Found another service provider'
      },
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Booking cancelled", () => {',
        '    const response = pm.response.json();',
        '    pm.expect(response.data.status).to.equal("cancelled");',
        '});'
      ],
      'Cancel a booking (only pending or confirmed status)'
    ),
    createRequest(
      'Check Availability',
      'GET',
      '/customer/bookings/check-availability?service_id={{service_id}}&date=2026-06-01',
      null,
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Response has availability info", () => {',
        '    const response = pm.response.json();',
        '    pm.expect(response.data).to.have.property("available");',
        '});'
      ],
      'Check if a service is available on a specific date'
    )
  ]
};


// 5. Bookings - Provider folder
const bookingsProviderFolder = {
  name: '5. Bookings - Provider',
  item: [
    createRequest(
      'List Bookings',
      'GET',
      '/provider/bookings',
      null,
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Response has data array", () => {',
        '    const response = pm.response.json();',
        '    pm.expect(response.data).to.be.an("array");',
        '});'
      ],
      'List all bookings for the provider\'s services'
    ),
    createRequest(
      'Get Booking Details',
      'GET',
      '/provider/bookings/{{booking_id}}',
      null,
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Booking has customer info", () => {',
        '    const booking = pm.response.json().data;',
        '    pm.expect(booking).to.have.property("customer");',
        '    pm.expect(booking.customer).to.have.property("name");',
        '});'
      ],
      'Get detailed information about a specific booking'
    ),
    createRequest(
      'Accept Booking',
      'POST',
      '/provider/bookings/{{booking_id}}/accept',
      null,
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Booking accepted", () => {',
        '    const response = pm.response.json();',
        '    pm.expect(response.data.status).to.equal("confirmed");',
        '});'
      ],
      'Accept a pending booking'
    ),
    createRequest(
      'Reject Booking',
      'POST',
      '/provider/bookings/{{booking_id}}/reject',
      {
        cancellation_reason: 'Not available at that time'
      },
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Booking rejected", () => {',
        '    const response = pm.response.json();',
        '    pm.expect(response.data.status).to.equal("rejected");',
        '});'
      ],
      'Reject a pending booking with a reason'
    ),
    createRequest(
      'Complete Booking',
      'POST',
      '/provider/bookings/{{booking_id}}/complete',
      null,
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Booking completed", () => {',
        '    const response = pm.response.json();',
        '    pm.expect(response.data.status).to.equal("completed");',
        '});'
      ],
      'Mark a confirmed booking as completed'
    ),
    createRequest(
      'Get Pending Bookings',
      'GET',
      '/provider/bookings/pending',
      null,
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("All bookings are pending", () => {',
        '    const response = pm.response.json();',
        '    response.data.forEach(booking => {',
        '        pm.expect(booking.status).to.equal("pending");',
        '    });',
        '});'
      ],
      'Get only pending bookings'
    ),
    createRequest(
      'Get Booking Statistics',
      'GET',
      '/provider/bookings/stats?date_from=2026-05-01&date_to=2026-05-31',
      null,
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Stats have required fields", () => {',
        '    const stats = pm.response.json().data;',
        '    pm.expect(stats).to.have.property("total_bookings");',
        '    pm.expect(stats).to.have.property("pending_count");',
        '    pm.expect(stats).to.have.property("confirmed_count");',
        '    pm.expect(stats).to.have.property("completed_count");',
        '    pm.expect(stats).to.have.property("total_revenue");',
        '});'
      ],
      'Get booking statistics with optional date range'
    )
  ]
};


// 6. Profile folder
const profileFolder = {
  name: '6. Profile',
  item: [
    createRequest(
      'Get Profile',
      'GET',
      '/profile',
      null,
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Profile has required fields", () => {',
        '    const profile = pm.response.json().data;',
        '    pm.expect(profile).to.have.property("id");',
        '    pm.expect(profile).to.have.property("name");',
        '    pm.expect(profile).to.have.property("email");',
        '    pm.expect(profile).to.have.property("role");',
        '});'
      ],
      'Get current user profile'
    ),
    createRequest(
      'Update Profile',
      'PUT',
      '/profile',
      {
        name: 'Updated Name',
        phone_number: '+977-9841234567',
        address: 'Kathmandu, Nepal'
      },
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Profile updated", () => {',
        '    const response = pm.response.json();',
        '    pm.expect(response.data.name).to.equal("Updated Name");',
        '});'
      ],
      'Update user profile information'
    ),
    {
      name: 'Upload Profile Image',
      request: {
        method: 'POST',
        header: [],
        url: {
          raw: '{{base_url}}/profile/image',
          host: ['{{base_url}}'],
          path: ['profile', 'image']
        },
        body: {
          mode: 'formdata',
          formdata: [
            {
              key: 'image',
              type: 'file',
              src: []
            }
          ]
        },
        description: 'Upload profile image (JPEG, PNG, JPG, max 2MB)'
      },
      event: [{
        listen: 'test',
        script: {
          exec: [
            'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
            'pm.test("Image URL returned", () => {',
            '    const response = pm.response.json();',
            '    pm.expect(response.data).to.have.property("profile_image_url");',
            '});'
          ]
        }
      }],
      response: []
    }
  ]
};


// 7. Provider Dashboard folder
const providerDashboardFolder = {
  name: '7. Provider Dashboard',
  item: [
    createRequest(
      'Get Provider Profile',
      'GET',
      '/provider/profile',
      null,
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Profile has services count", () => {',
        '    const profile = pm.response.json().data;',
        '    pm.expect(profile).to.have.property("services_count");',
        '});'
      ],
      'Get provider profile with services count'
    ),
    createRequest(
      'Update Provider Profile',
      'PUT',
      '/provider/profile',
      {
        name: 'Updated Provider Name',
        phone_number: '+977-9841234567',
        address: 'Kathmandu, Nepal',
        business_name: 'Premium Cleaning Services'
      },
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));'
      ],
      'Update provider profile information'
    ),
    createRequest(
      'Get Dashboard',
      'GET',
      '/provider/dashboard',
      null,
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Dashboard has all metrics", () => {',
        '    const dashboard = pm.response.json().data;',
        '    pm.expect(dashboard).to.have.property("total_services");',
        '    pm.expect(dashboard).to.have.property("active_services");',
        '    pm.expect(dashboard).to.have.property("total_bookings");',
        '    pm.expect(dashboard).to.have.property("pending_bookings");',
        '    pm.expect(dashboard).to.have.property("this_month_earnings");',
        '    pm.expect(dashboard).to.have.property("this_month_bookings");',
        '});'
      ],
      'Get provider dashboard with key metrics'
    ),
    createRequest(
      'Get Earnings',
      'GET',
      '/provider/earnings?date_from=2026-05-01&date_to=2026-05-31&group_by=day',
      null,
      'bearer',
      [
        'pm.test("Status code is 200", () => pm.response.to.have.status(200));',
        'pm.test("Earnings data returned", () => {',
        '    const response = pm.response.json();',
        '    pm.expect(response.data).to.be.an("array");',
        '});'
      ],
      'Get earnings breakdown by time period (day, week, or month)'
    )
  ]
};

// Add all folders to collection
collection.item.push(authFolder);
collection.item.push(servicesPublicFolder);
collection.item.push(servicesProviderFolder);
collection.item.push(bookingsCustomerFolder);
collection.item.push(bookingsProviderFolder);
collection.item.push(profileFolder);
collection.item.push(providerDashboardFolder);

// Write to file
fs.writeFileSync(
  'Phase1-Backend-APIs.postman_collection.json',
  JSON.stringify(collection, null, 2)
);

console.log('✅ Postman collection generated successfully!');
console.log('📁 File: Phase1-Backend-APIs.postman_collection.json');
console.log('📊 Total endpoints: 35');
console.log('📂 Folders: 7');
