const axios = require('axios');

// Update this with your actual Vercel URL
const API_URL = 'https://woosh-api.vercel.app/api';

async function testAPI() {
  console.log('🧪 Testing Woosh API...\n');

  try {
    // Test 1: Health check
    console.log('1️⃣ Testing health check...');
    const healthResponse = await axios.post(`${API_URL}/query`, {
      sql: 'SELECT 1 as health_check',
      values: []
    });
    console.log('✅ Health check passed:', healthResponse.data.success);

    // Test 2: Simple query
    console.log('\n2️⃣ Testing simple query...');
    const queryResponse = await axios.post(`${API_URL}/query`, {
      sql: 'SELECT COUNT(*) as total FROM SalesRep',
      values: []
    });
    console.log('✅ Query test passed:', queryResponse.data.data[0]);

    // Test 3: Login (if you have test credentials)
    console.log('\n3️⃣ Testing login endpoint...');
    try {
      const loginResponse = await axios.post(`${API_URL}/auth/login`, {
        phoneNumber: 'test@example.com',
        password: 'testpassword'
      });
      console.log('✅ Login endpoint working (credentials may be invalid)');
    } catch (error) {
      if (error.response?.status === 401) {
        console.log('✅ Login endpoint working (expected auth failure)');
      } else {
        console.log('❌ Login endpoint error:', error.message);
      }
    }

    console.log('\n🎉 All tests completed!');
    console.log('📝 API is ready for Flutter integration');

  } catch (error) {
    console.error('❌ API test failed:', error.message);
    if (error.response) {
      console.error('Response:', error.response.data);
    }
  }
}

// Run tests
testAPI(); 