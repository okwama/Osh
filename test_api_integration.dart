import 'package:woosh/services/api_service.dart';
import 'package:woosh/config/database_config.dart';

void main() async {
  print('🧪 Testing API Integration...');
  
  // Test 1: API Health Check
  print('\n1️⃣ Testing API health...');
  try {
    final isHealthy = await ApiService.instance.isHealthy();
    print('✅ API Health: $isHealthy');
  } catch (e) {
    print('❌ API Health failed: $e');
  }
  
  // Test 2: Simple Query
  print('\n2️⃣ Testing simple query...');
  try {
    final results = await ApiService.instance.query('SELECT 1 as test');
    print('✅ Query test: ${results.length} results');
  } catch (e) {
    print('❌ Query test failed: $e');
  }
  
  // Test 3: Login (with test credentials)
  print('\n3️⃣ Testing login...');
  try {
    final response = await ApiService.instance.login('0706166875', 'your_password');
    print('✅ Login test: ${response['success']}');
    if (response['success'] == true) {
      print('   User: ${response['salesRep']['name']}');
      print('   Token: ${response['accessToken']?.substring(0, 20)}...');
    }
  } catch (e) {
    print('❌ Login test failed: $e');
  }
  
  print('\n🎉 API Integration test completed!');
} 